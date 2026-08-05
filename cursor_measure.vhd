-------------------------------------------------------------------------------
-- Title       : Cursor measurement
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : cursor_measure.vhd
-- Author      : Justin Lalonde (AI assistance)
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module detects which of the four possible cursors (2 per 
--               channel) moved last and displays its current computed value to
--               the boards 7-segment display depending on the oscilloscope window's
--               current vertical zoom
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity cursor_measure is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           cursors_en : in STD_LOGIC;
           ch1_curs0 : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           ch1_curs1 : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           ch2_curs0 : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           ch2_curs1 : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           ch1_zoom : in STD_LOGIC_VECTOR (2 downto 0);
           ch2_zoom : in STD_LOGIC_VECTOR (2 downto 0);
           seg : out STD_LOGIC_VECTOR(6 downto 0);
           dp : out STD_LOGIC;
           an : out STD_LOGIC_VECTOR(3 downto 0));
end cursor_measure;

architecture Behavioral of cursor_measure is

    constant VREF_MV   : integer := 3300;
    constant MID_MV    : integer := VREF_MV / 2;          
    constant MID_ROW   : integer := SCREEN_HEIGHT / 2;    
    constant DENOM     : integer := SCREEN_HEIGHT * 32;

    signal prev_ch1_curs0 : std_logic_vector(ROW_INDEX_WIDTH-1 downto 0) := (others => '0');
    signal prev_ch1_curs1 : std_logic_vector(ROW_INDEX_WIDTH-1 downto 0) := (others => '0');
    signal prev_ch2_curs0 : std_logic_vector(ROW_INDEX_WIDTH-1 downto 0) := (others => '0');
    signal prev_ch2_curs1 : std_logic_vector(ROW_INDEX_WIDTH-1 downto 0) := (others => '0');

    signal active_value : std_logic_vector(ROW_INDEX_WIDTH-1 downto 0) := (others => '0');
    signal active_zoom  : std_logic_vector(2 downto 0) := (others => '0');

    signal meas_valid : std_logic := '0';

    signal cursors_en_d : std_logic := '0';

    signal row_offset_reg : integer := 0;
    signal zoom_reg       : std_logic_vector(2 downto 0) := (others => '0');

    signal mv_value : integer range 0 to VREF_MV := 0;

    signal digit0, digit1, digit2, digit3 : integer range 0 to 9 := 0;

    signal refresh_cnt : unsigned(19 downto 0) := (others => '0');
    signal digit_sel   : std_logic_vector(1 downto 0);

    signal seg_int : std_logic_vector(6 downto 0);
    signal dp_int  : std_logic;
    signal an_int  : std_logic_vector(3 downto 0);

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                prev_ch1_curs0 <= (others => '0');
                prev_ch1_curs1 <= (others => '0');
                prev_ch2_curs0 <= (others => '0');
                prev_ch2_curs1 <= (others => '0');
                active_value   <= (others => '0');
                active_zoom    <= (others => '0');
                meas_valid     <= '0';
                cursors_en_d   <= '0';
            elsif cursors_en = '0' then
                meas_valid   <= '0';
                cursors_en_d <= '0';
                prev_ch1_curs0 <= ch1_curs0;
                prev_ch1_curs1 <= ch1_curs1;
                prev_ch2_curs0 <= ch2_curs0;
                prev_ch2_curs1 <= ch2_curs1;
            elsif cursors_en = '1' and cursors_en_d = '0' then
                cursors_en_d   <= '1';
                prev_ch1_curs0 <= ch1_curs0;
                prev_ch1_curs1 <= ch1_curs1;
                prev_ch2_curs0 <= ch2_curs0;
                prev_ch2_curs1 <= ch2_curs1;
            else
                cursors_en_d <= '1';
                if ch1_curs0 /= prev_ch1_curs0 then
                    active_value <= ch1_curs0;
                    active_zoom  <= ch1_zoom;
                    meas_valid   <= '1';
                elsif ch1_curs1 /= prev_ch1_curs1 then
                    active_value <= ch1_curs1;
                    active_zoom  <= ch1_zoom;
                    meas_valid   <= '1';
                elsif ch2_curs0 /= prev_ch2_curs0 then
                    active_value <= ch2_curs0;
                    active_zoom  <= ch2_zoom;
                    meas_valid   <= '1';
                elsif ch2_curs1 /= prev_ch2_curs1 then
                    active_value <= ch2_curs1;
                    active_zoom  <= ch2_zoom;
                    meas_valid   <= '1';
                end if;
                prev_ch1_curs0 <= ch1_curs0;
                prev_ch1_curs1 <= ch1_curs1;
                prev_ch2_curs0 <= ch2_curs0;
                prev_ch2_curs1 <= ch2_curs1;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                row_offset_reg <= 0;
                zoom_reg       <= (others => '0');
            else
                row_offset_reg <= to_integer(unsigned(active_value)) - MID_ROW;
                zoom_reg       <= active_zoom;
            end if;
        end if;
    end process;

    process(clk)
        variable zoom_mult : integer range 1 to 128;
        variable num        : integer := 0;
        variable result      : integer := 0;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                mv_value <= 0;
            else
                case to_integer(unsigned(zoom_reg)) is
                    when 0 => zoom_mult := 1;
                    when 1 => zoom_mult := 2;
                    when 2 => zoom_mult := 4;
                    when 3 => zoom_mult := 8;
                    when 4 => zoom_mult := 16;
                    when 5 => zoom_mult := 32;
                    when 6 => zoom_mult := 64;
                    when others => zoom_mult := 128;
                end case;

                num    := row_offset_reg * VREF_MV * zoom_mult;
                result := MID_MV + (num / DENOM);  

                if result > VREF_MV then
                    mv_value <= VREF_MV;      
                elsif result < 0 then
                    mv_value <= 0;            
                else
                    mv_value <= result;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            digit0 <= mv_value / 1000;
            digit1 <= (mv_value mod 1000) / 100;
            digit2 <= (mv_value mod 100) / 10;
            digit3 <= mv_value mod 10;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                refresh_cnt <= (others => '0');
            else
                refresh_cnt <= refresh_cnt + 1;
            end if;
        end if;
    end process;

    digit_sel <= std_logic_vector(refresh_cnt(19 downto 18));

    process(digit_sel, digit0, digit1, digit2, digit3, cursors_en, meas_valid)
        variable cur_digit : integer range 0 to 9;
    begin
        if cursors_en = '0' or meas_valid = '0' then
            seg_int <= "1111111";
            dp_int  <= '1';
            an_int  <= "1111";
        else
            case digit_sel is
                when "00" =>                       
                    cur_digit := digit0;
                    an_int    <= "0111";
                    dp_int    <= '0';              
                when "01" =>                       
                    cur_digit := digit1;
                    an_int    <= "1011";
                    dp_int    <= '1';
                when "10" =>                       
                    cur_digit := digit2;
                    an_int    <= "1101";
                    dp_int    <= '1';
                when others =>                     
                    cur_digit := digit3;
                    an_int    <= "1110";
                    dp_int    <= '1';
            end case;

            case cur_digit is
                when 0 => seg_int <= "1000000";
                when 1 => seg_int <= "1111001";
                when 2 => seg_int <= "0100100";
                when 3 => seg_int <= "0110000";
                when 4 => seg_int <= "0011001";
                when 5 => seg_int <= "0010010";
                when 6 => seg_int <= "0000010";
                when 7 => seg_int <= "1111000";
                when 8 => seg_int <= "0000000";
                when 9 => seg_int <= "0010000";
                when others => seg_int <= "1111111";
            end case;
        end if;
    end process;

    seg <= seg_int;
    dp  <= dp_int;
    an  <= an_int;

end Behavioral;
