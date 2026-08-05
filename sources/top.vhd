-------------------------------------------------------------------------------
-- Title       : Top Module
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : top.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : top module which instantiates and implements every other module
--               within the project
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity top is
    Port ( CLK100MHZ    : in STD_LOGIC;
           btnC         : in STD_LOGIC;
           btnU         : in STD_LOGIC;
           btnD         : in STD_LOGIC;
           btnR         : in STD_LOGIC;
           btnL         : in STD_LOGIC;
           sw           : in STD_LOGIC_VECTOR (15 downto 0);
           LED          : out STD_LOGIC_VECTOR (15 downto 0);
           JA           : inout STD_LOGIC_VECTOR (7 downto 0);
           JB           : inout STD_LOGIC_VECTOR (7 downto 0);
           JXADC        : inout STD_LOGIC_VECTOR (7 downto 0);
           seg          : out STD_LOGIC_VECTOR (6 downto 0);
           dp           : out STD_LOGIC;
           an           : out STD_LOGIC_VECTOR (3 downto 0)
           );
end top;

architecture Behavioral of top is

    -- oscilloscope 

    signal pix_write    : STD_LOGIC;
    signal pix_col      : STD_LOGIC_VECTOR(COL_INDEX_WIDTH - 1 downto 0);
    signal pix_row      : STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
    signal pix_data     : STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0);

    signal lay_col          : STD_LOGIC_VECTOR(COL_INDEX_WIDTH - 1 downto 0);
    signal lay_row          : STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1  downto 0);
    signal bg_active        : STD_LOGIC;
    signal bg_rgb           : STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0);
    signal ch1_active       : STD_LOGIC;
    signal ch1_rgb          : STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0);   
    signal ch2_active       : STD_LOGIC;
    signal ch2_rgb          : STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0); 
    signal ch1_curs_active  : STD_LOGIC;
    signal ch1_curs_rgb     : STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0); 
    signal ch2_curs_active  : STD_LOGIC;
    signal ch2_curs_rgb     : STD_LOGIC_VECTOR(COLOR_RESOLUTION - 1 downto 0); 

    signal point_index  : STD_LOGIC_VECTOR(COL_INDEX_WIDTH - 1 downto 0);
    signal point_data_a : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal point_data_b : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

    signal selected_ch  : STD_LOGIC;
    signal cursors_en   : STD_LOGIC;

    signal h_zoom_out   : STD_LOGIC;
    signal h_zoom_in    : STD_LOGIC;
    signal v_zoom_out   : STD_LOGIC;
    signal v_zoom_in    : STD_LOGIC;
    signal curs0_up     : STD_LOGIC;
    signal curs0_down   : STD_LOGIC;
    signal curs1_up     : STD_LOGIC;
    signal curs1_down   : STD_LOGIC;
    
    signal ch1_curs0 : STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
    signal ch1_curs1 : STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
    signal ch2_curs0 : STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
    signal ch2_curs1 : STD_LOGIC_VECTOR(ROW_INDEX_WIDTH - 1 downto 0);
    signal ch1_v_zoom : STD_LOGIC_VECTOR(2 downto 0);
    signal ch2_v_zoom : STD_LOGIC_VECTOR(2 downto 0);

    signal adc_rdy      : STD_LOGIC;
    signal adc_data_a   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal adc_data_b   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0); 

    -- function generator

    signal dac_rdy      : STD_LOGIC;
    signal dac_data_a   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal dac_data_b   : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

    signal amp_up       : STD_LOGIC;
    signal amp_down     : STD_LOGIC;
    signal freq_up      : STD_LOGIC;
    signal freq_down    : STD_LOGIC;
    signal type_up      : STD_LOGIC;
    signal type_down    : STD_LOGIC;
    
begin

    LED(2 downto 0) <= sw(2 downto 0);
    
    -- oscilloscope

    pmodOLEDrgb_inst : entity work.pmodOLEDrgb
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        pix_write       => pix_write,
        pix_col         => pix_col,
        pix_row         => pix_row,
        pix_data        => pix_data,
        OLEDrgb_cs      => JB(0),
        OLEDrgb_mosi    => JB(1),
        OLEDrgb_sck     => JB(3),
        OLEDrgb_dc      => JB(4),
        OLEDrgb_res     => JB(5),
        OLEDrgb_vccen   => JB(6),
        OLEDrgb_en      => JB(7)
    );

    layer_compositor_inst : entity work.layer_compositor
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        lay_col         => lay_col,
        lay_row         => lay_row,
        bg_active       => bg_active,  
        bg_rgb          => bg_rgb,    
        ch1_active      => ch1_active,
        ch1_rgb         => ch1_rgb,   
        ch2_active      => ch2_active,
        ch2_rgb         => ch2_rgb, 
        ch1_curs_active => ch1_curs_active,
        ch1_curs_rgb    => ch1_curs_rgb,  
        ch2_curs_active => ch2_curs_active,
        ch2_curs_rgb    => ch2_curs_rgb,   
        pix_write       => pix_write,
        pix_col         => pix_col,
        pix_row         => pix_row,
        pix_data        => pix_data
    );

    bg_layer_inst : entity work.bg_layer
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        lay_col         => lay_col,
        lay_row         => lay_row,
        active          => bg_active,
        rgb             => bg_rgb
    );

    ch1_layer_inst : entity work.ch_layer
    generic map(CH_INDEX => '0')
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        lay_col         => lay_col,
        lay_row         => lay_row,
        active          => ch1_active,
        rgb             => ch1_rgb,
        point_index     => point_index,
        point_data      => point_data_a,
        v_zoom_in       => v_zoom_in,
        v_zoom_out      => v_zoom_out,
        v_zoom          => ch1_v_zoom
    );
    
    ch2_layer_inst : entity work.ch_layer
    generic map(CH_INDEX => '1')
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        lay_col         => lay_col,
        lay_row         => lay_row,
        active          => ch2_active,
        rgb             => ch2_rgb,
        point_index     => open,
        point_data      => point_data_b,
        v_zoom_in       => v_zoom_in,
        v_zoom_out      => v_zoom_out,
        v_zoom          => ch2_v_zoom
    );
    
    ch1_wave_capture_inst : entity work.wave_capture
    generic map(CH_INDEX => '0')
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        point_index     => point_index,
        point_data      => point_data_a,
        adc_rdy         => adc_rdy,   
        adc_data        => adc_data_a,
        h_zoom_out      => h_zoom_out,
        h_zoom_in       => h_zoom_in
    );
    
    ch2_wave_capture_inst : entity work.wave_capture
    generic map(CH_INDEX => '1')
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        point_index     => point_index,
        point_data      => point_data_b,
        adc_rdy         => adc_rdy,   
        adc_data        => adc_data_b,
        h_zoom_out      => h_zoom_out,
        h_zoom_in       => h_zoom_in
    );

    pmodAD1_inst : entity work.pmodAD1
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        adc_read        => '1',
        adc_rdy         => adc_rdy,
        adc_data_a      => adc_data_a,
        adc_data_b      => adc_data_b,
        ad1_cs          => JXADC(4), 
        ad1_data_a      => JXADC(5),
        ad1_data_b      => JXADC(6), 
        ad1_sclk        => JXADC(7)  
    );

    ch1_cursor_layer_inst : entity work.ch_cursor_layer
    generic map (CH_INDEX => '0')
    port map(
        clk             => CLK100MHZ,        
        rst             => btnC,        
        lay_col         => lay_col,    
        lay_row         => lay_row,   
        active          => ch1_curs_active,     
        rgb             => ch1_curs_rgb,        
        cursors_en      => cursors_en, 
        selected_ch     => selected_ch,
        curs0_up        => curs0_up,   
        curs0_down      => curs0_down, 
        curs1_up        => curs1_up,   
        curs1_down      => curs1_down,
        curs0           => ch1_curs0,
        curs1           => ch1_curs1
    );
    
    ch2_cursor_layer_inst : entity work.ch_cursor_layer
    generic map (CH_INDEX => '1')
    port map(
        clk             => CLK100MHZ,        
        rst             => btnC,        
        lay_col         => lay_col,    
        lay_row         => lay_row,   
        active          => ch2_curs_active,     
        rgb             => ch2_curs_rgb,        
        cursors_en      => cursors_en, 
        selected_ch     => selected_ch,
        curs0_up        => curs0_up,   
        curs0_down      => curs0_down, 
        curs1_up        => curs1_up,   
        curs1_down      => curs1_down ,
        curs0           => ch2_curs0,
        curs1           => ch2_curs1
    );
    
    cursor_measure_inst : entity work.cursor_measure
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        cursors_en      => cursors_en,
        ch1_curs0       => ch1_curs0, 
        ch1_curs1       => ch1_curs1, 
        ch2_curs0       => ch2_curs0, 
        ch2_curs1       => ch2_curs1, 
        ch1_zoom        => ch1_v_zoom,  
        ch2_zoom        => ch2_v_zoom,  
        seg             => seg,       
        dp              => dp,        
        an              => an        
     );

    -- function generator

    function_generator_inst : entity work.function_generator
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        dac_rdy         => dac_rdy,
        dac_data_a      => dac_data_a,
        dac_data_b      => dac_data_b,
        selected_ch     => selected_ch,
        amp_up          => amp_up,         
        amp_down        => amp_down,     
        freq_up         => freq_up,    
        freq_down       => freq_down,  
        type_up         => type_up,    
        type_down       => type_down  
    );

    pmodDA2_inst : entity work.pmodDA2 
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        dac_write       => '1',
        dac_rdy         => dac_rdy,
        dac_data_a      => dac_data_a,
        dac_data_b      => dac_data_b,
        da2_sync        => JA(4),
        da2_data_a      => JA(5),
        da2_data_b      => JA(6),
        da2_sclk        => JA(7)
    );

    -- input manager

    input_manager_inst : entity work.input_manager
    port map(
        clk             => CLK100MHZ,
        rst             => btnC,
        btnU            => btnU,
        btnD            => btnD,
        btnR            => btnR,
        btnL            => btnL,
        sw              => sw(2 downto 0),
        selected_ch     => selected_ch,  
        cursors_en      => cursors_en,    
        h_zoom_in       => h_zoom_in,     
        h_zoom_out      => h_zoom_out,    
        v_zoom_in       => v_zoom_in,     
        v_zoom_out      => v_zoom_out,    
        curs0_up        => curs0_up,  
        curs0_down      => curs0_down,
        curs1_up        => curs1_up,  
        curs1_down      => curs1_down,
        amp_up          => amp_up,        
        amp_down        => amp_down,      
        freq_up         => freq_up,       
        freq_down       => freq_down,     
        type_up         => type_up,       
        type_down       => type_down     
    );

end Behavioral;
