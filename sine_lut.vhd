-------------------------------------------------------------------------------
-- Title       : Sine Wave LUT
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : sine_lut.vhd
-- Author      : Justin Lalonde (AI assistance)
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module consists of a Look-up-table (LUT) which is calculated 
--               at compile time and stored in RAM. It works by taking in a 24-bit
--               phase input value and outputting an associated 12-bit value from
--               a full sine wave period
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.constants_pkg.all;

entity sine_lut is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           phase : in STD_LOGIC_VECTOR (PHASE_WIDTH - 1 downto 0);
           sine_val : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0));
end sine_lut;

architecture Behavioral of sine_lut is

    constant ADDR_WIDTH  : integer := 10; 
    
    type rom_array is array (0 to 2**ADDR_WIDTH - 1) of unsigned(DATA_WIDTH - 1 downto 0);

    function init_quarter_sine return rom_array is
        variable rom  : rom_array;
        variable ang  : real;
    begin
        for i in 0 to 2**ADDR_WIDTH - 1 loop
            ang := (real(i) / real(2**ADDR_WIDTH)) * (MATH_PI / 2.0); 
            rom(i) := to_unsigned(integer(round(sin(ang) * real(2**(DATA_WIDTH - 1) - 1))), DATA_WIDTH);
        end loop;
        return rom;
    end function;

    constant QUARTER_ROM : rom_array := init_quarter_sine;

    signal quadrant   : unsigned(1 downto 0);
    signal addr_raw   : unsigned(ADDR_WIDTH - 1 downto 0);
    signal addr_mux   : unsigned(ADDR_WIDTH - 1 downto 0);
    signal rom_data   : unsigned(DATA_WIDTH - 1 downto 0);
    signal mid_scale  : integer := 2**(DATA_WIDTH - 1);

begin

    quadrant <= unsigned(phase(PHASE_WIDTH-1 downto PHASE_WIDTH-2));
    addr_raw <= unsigned(phase(PHASE_WIDTH-3 downto PHASE_WIDTH-2-ADDR_WIDTH));
    addr_mux <= addr_raw when (quadrant = "00" or quadrant = "10") else (2**ADDR_WIDTH - 1) - addr_raw;

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                sine_val <= (others => '0'); 
                rom_data <= (others => '0');
            else 
                rom_data <= QUARTER_ROM(to_integer(addr_mux));
                if quadrant(1) = '0' then
                    sine_val <= std_logic_vector(to_unsigned(mid_scale + to_integer(rom_data), DATA_WIDTH));
                else
                    sine_val <= std_logic_vector(to_unsigned(mid_scale - to_integer(rom_data), DATA_WIDTH));
                end if;
            end if;
        end if;
    end process;

end Behavioral;
