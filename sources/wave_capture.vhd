-- ----------------------------------------------------------------------------
-- Title       : Wave Capture
-- Project     : Digital Oscilloscope and Function Generator
-- ----------------------------------------------------------------------------
-- File        : wave_capture.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-- ----------------------------------------------------------------------------
-- Description : this module is responsible for reconstructing the sampled values
--               into a 96-wide array of 12-bit values so that it may be displayed 
--               in the opscilloscope window. It interfaces with the pmodAD1 for ADC values
--               and stores the sampled values in a large memory buffer.
--               Works with an Equivalent-Time-Sampling (ETS) algorithm sampling one point
--               per signal trigger cycle (which has its upsides and downsides, especially
--               for displaying lower frequency signals)
-- ----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity wave_capture is
    Generic (CH_INDEX : STD_LOGIC);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           point_index : in STD_LOGIC_VECTOR (COL_INDEX_WIDTH - 1 downto 0);
           point_data : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           adc_rdy : in STD_LOGIC;
           adc_data : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           h_zoom_out : in STD_LOGIC;
           h_zoom_in : in STD_LOGIC);
end wave_capture;

architecture Behavioral of wave_capture is

    signal period_cnt : unsigned(26 downto 0) := (others => '0'); 
    signal period : unsigned(26 downto 0) := (others => '0'); 
    
    constant TRIGG_LEVEL : unsigned(DATA_WIDTH - 1 downto 0) := to_unsigned(MID_SCALE, DATA_WIDTH);
    constant TRIGG_BUFFER : integer := 3; 
    signal trigg : std_logic := '0'; 
    signal trigg_cnt : unsigned(2 downto 0):= (others => '0');
    signal r_data_in : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others=>'0');
    
    signal zoom : unsigned(4 downto 0) := to_unsigned(DEFAULT_H_ZOOM,5); 
    signal zoom_factor : unsigned(MAX_H_ZOOM downto 0) := (others => '0');
    
    constant SAMPLE_CYCLES : integer := 108/2; 

    signal wave_mem_index : unsigned(COL_INDEX_WIDTH - 1 downto 0) := (others => '0');
    signal sample_delay : unsigned(MAX_H_ZOOM + 7 downto 0) := (others => '0');
    signal sample_delay_cnt : unsigned(MAX_H_ZOOM + 7 downto 0) := (others => '0');
    
    type sample_state_t is (standby, counting, converting);
    signal sample_state : sample_state_t := counting;
    
    type wave_mem_t is array(0 to SCREEN_WIDTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal wave_mem : wave_mem_t := (others => (others => '0'));
    
begin
    
    point_data <= wave_mem(to_integer(unsigned(point_index))); 

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                trigg <= '0';
                trigg_cnt <= (others => '0');
            elsif trigg_cnt >= to_unsigned(TRIGG_BUFFER, 3) then
                trigg <= '1';
                trigg_cnt <= (others => '0');
            elsif unsigned(r_data_in) < TRIGG_LEVEL and unsigned(adc_data) >= TRIGG_LEVEL then
                trigg_cnt <= "001";
            elsif trigg_cnt > 0 and unsigned(adc_data) >= TRIGG_LEVEL then
                trigg_cnt <= trigg_cnt + 1;
                trigg <= '0';
            else 
                trigg <= '0';
                trigg_cnt <= (others => '0');
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_data_in <= (others => '0');
            else
                r_data_in <= adc_data;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                period_cnt <= (others => '0');
                period <= (others => '0');
            elsif trigg = '1' then
                period_cnt <= (others => '0');
                period <= period_cnt;
            else
                period_cnt <= period_cnt + 1;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                wave_mem <= (others => (others => '0'));
                wave_mem_index <= (others => '0');
                sample_delay <= (others => '0');
                sample_delay_cnt <= (others => '0');
                sample_state <= standby;
            elsif period > SAMPLE_CYCLES + (SCREEN_WIDTH / 2) then
                case sample_state is
                    when standby =>
                        if trigg = '1' then
                            sample_state <= counting;
                            sample_delay <= (period - SAMPLE_CYCLES - (SCREEN_WIDTH / 2) + (wave_mem_index * zoom_factor));
                        end if;
                        if wave_mem_index = to_unsigned(SCREEN_WIDTH,7) then
                            wave_mem_index <= (others => '0');
                        end if;
                        
                    when counting =>
                        if sample_delay_cnt >= sample_Delay then
                            if adc_rdy = '1' then
                                sample_state <= converting;
                                sample_delay_cnt <= (others => '0');
                            end if;
                        else
                           sample_delay_cnt <= sample_delay_cnt + 1; 
                        end if;
                        
                    when converting =>
                        if adc_rdy = '1' then
                            wave_mem(to_integer(wave_mem_index)) <= adc_data;
                            sample_state <= standby;
                            wave_mem_index <= wave_mem_index + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
               zoom <= to_unsigned(DEFAULT_H_ZOOM ,5);
               zoom_factor <= (others => '0');
            else
                zoom_factor <= shift_left(to_unsigned(1, MAX_H_ZOOM + 1),to_integer(zoom));
                if h_zoom_in = '1' and zoom > 0 then 
                   zoom <= zoom - 1;
                elsif h_zoom_out = '1' and zoom < to_unsigned(MAX_H_ZOOM,5) then
                    zoom <= zoom + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
