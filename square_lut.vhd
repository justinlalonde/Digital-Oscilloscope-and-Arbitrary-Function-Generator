-------------------------------------------------------------------------------
-- Title       : Square Wave LUT
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : square_lut.vhd
-- Author      : Justin Lalonde
-- Created     : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : Generates a 50% duty-cycle square wave from a 24-bit phase
--               input
-------------------------------------------------------------------------------
-- Revisions   :
-- Date        Version  Author    Description
-- 2026-08-02  1.0      J.L.      File created
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity square_lut is
    Port ( clk        : in  STD_LOGIC;
           rst        : in  STD_LOGIC;
           phase      : in  STD_LOGIC_VECTOR (PHASE_WIDTH - 1 downto 0);
           square_val : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0));
end square_lut;

architecture Behavioral of square_lut is

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                square_val <= (others => '0');
            else
                if phase(PHASE_WIDTH - 1) = '0' then
                    square_val <= std_logic_vector(to_unsigned(MID_SCALE + PEAK_AMPLITUDE, DATA_WIDTH));
                else
                    square_val <= std_logic_vector(to_unsigned(MID_SCALE - PEAK_AMPLITUDE, DATA_WIDTH));
                end if;
            end if;
        end if;
    end process;

end Behavioral;