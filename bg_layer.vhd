-------------------------------------------------------------------------------
-- Title       : Background Layer
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : bg_layer.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : layer module which implements the background features for 
--               the oscilloscope window. "active" output is always '1' since
--               it is the least prioritized layer (background)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity bg_layer is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           lay_col : in STD_LOGIC_VECTOR (COL_INDEX_WIDTH - 1 downto 0);
           lay_row : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           active : out STD_LOGIC;
           rgb : out STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0));
end bg_layer;

architecture Behavioral of bg_layer is

    signal col, row     : integer;
    signal is_gridline  : std_logic;
    signal is_center    : std_logic;
    signal rgb_i       : std_logic_vector(COLOR_RESOLUTION - 1 downto 0);

begin

    col <= to_integer(unsigned(lay_col));
    row <= to_integer(unsigned(lay_row));

    is_gridline <= '1' when (col mod GRID_DIV_WIDTH = 0) or (row mod GRID_DIV_HEIGHT = 0) or
                        (col = SCREEN_WIDTH - 1) or (row = SCREEN_HEIGHT - 1) else '0';
    
    is_center   <= '1' when (col= SCREEN_WIDTH / 2) or (col = SCREEN_WIDTH / 2 + 1) or 
                            (row = SCREEN_HEIGHT / 2) or (row = SCREEN_HEIGHT / 2 + 1) else '0';

    rgb_i <= GRID_CENTER_COLOR when is_center   = '1' else
             GRID_COLOR   when is_gridline = '1' else
             BG_COLOR;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                rgb    <= (others=>'0');
                active <= '0';
            else
                rgb    <= rgb_i;
                active <= '1';
            end if;
        end if;
    end process;

end Behavioral;
