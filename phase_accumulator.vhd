-------------------------------------------------------------------------------
-- Title       : Phase Accumulator
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : phase_accumulator.vhd
-- Author      : Justin Lalonde
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module takes for input 24-bit values and accumulates them
--               every clock cycle using an internal 24-bit signal. This accumulated
--               sum acts as the phase input for adjacent signal LUT's which are used
--               to generate a 12-bit full scale signals by the wave_generator module.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity phase_accumulator is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           phase_incr : in STD_LOGIC_VECTOR (PHASE_WIDTH - 1 downto 0);
           phase : out STD_LOGIC_VECTOR (PHASE_WIDTH - 1 downto 0));
end phase_accumulator;

architecture Behavioral of phase_accumulator is

    signal accum : unsigned(PHASE_WIDTH - 1 downto 0) := (others => '0');

begin

    phase <= std_logic_vector(accum);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                accum <= (others => '0');
            else 
                accum <= accum + unsigned(phase_incr);
            end if;
        end if;
    end process;

end Behavioral;
