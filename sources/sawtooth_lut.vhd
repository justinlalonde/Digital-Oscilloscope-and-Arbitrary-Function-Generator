-------------------------------------------------------------------------------
-- Title       : Sawtooth Wave LUT
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : sawtooth_lut.vhd
-- Author      : Justin Lalonde
-- Created     : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : Generates a rising-ramp sawtooth wave from a 24-bit phase
--               input by taking the top DATA_WIDTH bits of the phase
--               accumulator directly. 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity sawtooth_lut is
    Port ( clk          : in  STD_LOGIC;
           rst          : in  STD_LOGIC;
           phase        : in  STD_LOGIC_VECTOR (PHASE_WIDTH - 1 downto 0);
           sawtooth_val : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0));
end sawtooth_lut;

architecture Behavioral of sawtooth_lut is
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sawtooth_val <= (others => '0');
            else
                sawtooth_val <= phase(PHASE_WIDTH - 1 downto PHASE_WIDTH - DATA_WIDTH);
            end if;
        end if;
    end process;

end Behavioral;
