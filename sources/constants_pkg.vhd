-------------------------------------------------------------------------------
-- Title       : Constants Package
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : constants_pkg.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : contains most project constants 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package constants_pkg is

    constant SYS_CLK_FREQ : integer := 100_000_000; -- in Hz
    constant DEBOUNCE_HOLD_TIME : integer := 1; -- in ms

    constant COLOR_RESOLUTION : integer := 16; -- in bits
    constant SCREEN_WIDTH : integer := 96; -- in pixels  
    constant SCREEN_HEIGHT : integer := 64; -- in pixels
    constant COL_INDEX_WIDTH : integer := 7; -- in bits
    constant ROW_INDEX_WIDTH : integer := 6; -- in bits

    constant BG_COLOR     : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"0000"; -- black
    constant GRID_COLOR   : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"528a"; -- gray
    constant GRID_CENTER_COLOR : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"528a"; -- light gray
    constant GRID_DIV_WIDTH  : integer := 8; -- 96/8 = 12 horizontal divisions, in pixels
    constant GRID_DIV_HEIGHT : integer := 8; -- 64/8 = 8 horizontal divisions, in pixels

    constant CH1_COLOR    : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"ffc0"; -- yellow
    constant CH2_COLOR    : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"045f"; -- light blue
    constant CH1_CURSOR_COLOR : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"f640"; -- darker yellow
    constant CH2_CURSOR_COLOR : std_logic_vector(COLOR_RESOLUTION-1 downto 0) := x"029e"; -- blue

    constant DEFAULT_CURSOR_SPACING : integer := SCREEN_HEIGHT / 2; -- in pixels
    constant DEFAULT_CURS0_POS : integer := SCREEN_HEIGHT / 2 + DEFAULT_CURSOR_SPACING / 2; -- in pixels
    constant DEFAULT_CURS1_POS : integer := SCREEN_HEIGHT / 2 - DEFAULT_CURSOR_SPACING / 2; -- in pixels

    constant COMPOSITOR_PIPELINE_LATENCY : integer := 1; -- in system clock cycles

    constant DATA_WIDTH : integer := 12; -- in bits
    constant MID_SCALE : integer := 2**(DATA_WIDTH - 1); 
    constant PEAK_AMPLITUDE : integer := 2**(DATA_WIDTH - 1) - 1; 
    constant PHASE_WIDTH : integer := 24; -- in bits
    
    constant MAX_V_ZOOM     : integer := DATA_WIDTH / 2 - 1; 
    constant DEFAULT_V_ZOOM : integer := MAX_V_ZOOM; -- full scale display by default
    constant MAX_H_ZOOM : integer := 20; -- with 1Hz frequency in mind
    constant DEFAULT_H_ZOOM : integer := 7; -- with a 10kHz frequency in mind
    
end package constants_pkg; 
