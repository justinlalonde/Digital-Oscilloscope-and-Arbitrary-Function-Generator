-------------------------------------------------------------------------------
-- Title       : Delay Line
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : delay_line.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module applies an arbitrary delay to an arbitrarely sized 
--               std_logic_vector signal. The delay and vector size are generic
--               parameters to the module
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity delay_line is
    Generic (
        WIDTH : integer;
        DEPTH : integer 
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           d : in STD_LOGIC_VECTOR (WIDTH - 1 downto 0);
           q : out STD_LOGIC_VECTOR (WIDTH - 1 downto 0));
end delay_line;

architecture Behavioral of delay_line is

    type shift_array is array (0 to DEPTH - 1) of std_logic_vector(WIDTH - 1 downto 0);
    signal shift_reg : shift_array := (others => (others => '0'));

begin

    q <= shift_reg(DEPTH - 1);

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                shift_reg <= (others => (others => '0'));
            else
                shift_reg(0) <= d;
                for i in 1 to DEPTH - 1 loop
                    shift_reg(i) <= shift_reg(i - 1);
                end loop;
            end if;
        end if;
    end process;

end Behavioral;
