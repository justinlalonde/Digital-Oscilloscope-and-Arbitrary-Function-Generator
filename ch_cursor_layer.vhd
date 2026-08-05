-------------------------------------------------------------------------------
-- Title       : Channel Cursor Layer
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : ch_cursor_layer.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-08-02
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this layer module interfaces with the layer compositor and handles
--               horizontal cursor positions
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity ch_cursor_layer is
    Generic (CH_INDEX : STD_LOGIC);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           lay_col : in STD_LOGIC_VECTOR(COL_INDEX_WIDTH - 1 downto 0);
           lay_row : in STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
           active : out STD_LOGIC;
           rgb : out STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0);
           cursors_en : in STD_LOGIC;
           selected_ch : in STD_LOGIC;
           curs0_up : in STD_LOGIC;
           curs0_down : in STD_LOGIC;
           curs1_up : in STD_LOGIC;
           curs1_down : in STD_LOGIC;
           curs0 : out STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
           curs1 : out STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0)
           );
end ch_cursor_layer;

architecture Behavioral of ch_cursor_layer is

    signal curs0_pos : unsigned(ROW_INDEX_WIDTH - 1 downto 0) := to_unsigned(DEFAULT_CURS0_POS, ROW_INDEX_WIDTH);
    signal curs1_pos : unsigned(ROW_INDEX_WIDTH - 1 downto 0) := to_unsigned(DEFAULT_CURS1_POS, ROW_INDEX_WIDTH);

begin

    curs0 <= std_logic_vector(SCREEN_HEIGHT - 1 - curs0_pos);
    curs1 <= std_logic_vector(SCREEN_HEIGHT - 1 - curs1_pos);

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rgb <= (others => '0');
            else
                if CH_INDEX = '0' then
                    rgb <= CH1_CURSOR_COLOR;
                else
                    rgb <= CH2_CURSOR_COLOR;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                active <= '0';
            elsif cursors_en = '1' and selected_ch = CH_INDEX then
                if lay_row = std_logic_vector(curs0_pos) or lay_row = std_logic_vector(curs1_pos) then
                    active <= '1';
                else
                    active <= '0';
                end if;
            else
                active <= '0';
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                curs0_pos <= to_unsigned(DEFAULT_CURS0_POS, ROW_INDEX_WIDTH);
                curs1_pos <= to_unsigned(DEFAULT_CURS1_POS, ROW_INDEX_WIDTH);
            elsif cursors_en = '1' and selected_ch = CH_INDEX then
                if curs0_up = '1' and curs0_pos > 1 then
                    curs0_pos <= curs0_pos - 2;
                elsif curs0_down = '1' and curs0_pos < SCREEN_HEIGHT - 2 then
                    curs0_pos <= curs0_pos + 2;
                end if;
                if curs1_up = '1' and curs1_pos > 1 then
                    curs1_pos <= curs1_pos - 2;
                elsif curs1_down = '1' and curs1_pos < SCREEN_HEIGHT - 2 then
                    curs1_pos <= curs1_pos + 2;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
