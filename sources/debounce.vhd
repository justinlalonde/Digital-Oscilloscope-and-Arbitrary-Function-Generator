-------------------------------------------------------------------------------
-- Title       : Button Debounce
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : debounce.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module acts as a hardware debounce for button inputs. On
--               new button presses, a counter starts and the output is asserted 
--               when it reaches a set counter threshold
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity debounce is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           btn_in : in STD_LOGIC;
           btn_out : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is

    constant cnt_max : unsigned(17 downto 0) := to_unsigned(SYS_CLK_FREQ / 1000 * DEBOUNCE_HOLD_TIME, 18);
    signal cnt : unsigned(17 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                btn_out <= '0';
                cnt <= (others => '0');
            elsif btn_in = '1' then
                if cnt = (cnt_max - 1) then
                    btn_out <= '1';
                    cnt <= cnt_max - 1;
                else
                    btn_out <= '0';
                    cnt <= cnt + 1;
                end if;
            else
                btn_out <= '0';
                cnt <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;
