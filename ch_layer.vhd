-------------------------------------------------------------------------------
-- Title       : Channel Layer
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : ch_layer.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module fetches 96 ADC values from the wave-capture module
--               (which in turn interfaces with the actual ADC module) and scales
--               these raw 12-bit values (depending on the selected vertical zoom) 
--               so that the channel's waveform can be properly displayed and 
--               interpreted by the layer_compositor module.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity ch_layer is
    Generic (CH_INDEX : STD_LOGIC);
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           lay_col : in STD_LOGIC_VECTOR (COL_INDEX_WIDTH - 1 downto 0);
           lay_row : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           active : out STD_LOGIC;
           rgb : out STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
           point_index : out STD_LOGIC_VECTOR(COL_INDEX_WIDTH - 1 downto 0);
           point_data : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           v_zoom_in : in STD_LOGIC;
           v_zoom_out : in STD_LOGIC;
           v_zoom : out STD_LOGIC_VECTOR(2 downto 0));
end ch_layer;

architecture Behavioral of ch_layer is

    signal row : integer;
    
    signal zoom        : unsigned(2 downto 0) := to_unsigned(DEFAULT_V_ZOOM, 3);
    signal zoom_factor : unsigned(MAX_V_ZOOM downto 0);         

    signal wave_delta : signed(DATA_WIDTH downto 0);
    
    signal zoom_factor_signed : signed(MAX_V_ZOOM + 1 downto 0);
    signal zoom_mult_result   : signed(DATA_WIDTH + MAX_V_ZOOM + 2 downto 0); 
    
    signal scaled_data_signed : signed(DATA_WIDTH downto 0); 
    signal scaled_data : unsigned(DATA_WIDTH - 1 downto 0); 
    
begin

    v_zoom <= std_logic_vector(zoom);
    row <= SCREEN_HEIGHT - 1 - to_integer(unsigned(lay_row));

    point_index <= lay_col;
    
    zoom_factor <= shift_left(to_unsigned(1, MAX_V_ZOOM + 1), to_integer(zoom));
    zoom_factor_signed <= signed('0' & std_logic_vector(zoom_factor));
     
    wave_delta <= signed(resize(unsigned(point_data), DATA_WIDTH + 1)) - to_signed(MID_SCALE, DATA_WIDTH + 1);
    
    scaled_data_signed <= resize(shift_right(zoom_mult_result, MAX_V_ZOOM), DATA_WIDTH + 1) + to_signed(MID_SCALE, DATA_WIDTH + 1);
    scaled_data <= unsigned(scaled_data_signed(DATA_WIDTH - 1 downto 0));
    
    active <= '1' when to_integer(scaled_data(11 downto 6)) = row and rst = '0' else '0';
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                zoom_mult_result   <= (others => '0');
            else
                zoom_mult_result   <= wave_delta * zoom_factor_signed;
            end if;
        end if;
    end process;
    
    process(clk)
    begin 
        if rising_edge(clk) then
            if rst = '1' then
                rgb <= (others => '0');
            else
                if CH_INDEX = '0' then
                    rgb <= CH1_COLOR;
                else
                    rgb <= CH2_COLOR;
                end if;
            end if;
        end if;
    end process;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
               zoom <= to_unsigned(DEFAULT_V_ZOOM ,3);
            else
                if v_zoom_out = '1' and zoom > 0 then 
                   zoom <= zoom - 1;
                elsif v_zoom_in = '1' and zoom < to_unsigned(MAX_V_ZOOM,3) then
                    zoom <= zoom + 1;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
