-------------------------------------------------------------------------------
-- Title       : Pmod AD1 (https://digilent.com/reference/pmod/pmodad1/reference-manual)
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : pmodAD1.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module interfaces with the Digilent AD1 Pmod extension board
--               which integrates two single-channel 12 bit 1MSPS ADC ICs 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity pmodAD1 is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           adc_read : in STD_LOGIC;
           adc_rdy : out STD_LOGIC;
           adc_data_a : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           adc_data_b : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           ad1_cs : out STD_LOGIC;
           ad1_data_a : in STD_LOGIC;
           ad1_data_b : in STD_LOGIC;
           ad1_sclk : out STD_LOGIC);
end pmodAD1;

architecture Behavioral of pmodAD1 is

    constant SCLK_DIV : integer := 6; -- relative to the system clock
    constant BITS_PER_MESSAGE : integer := 16;
    constant DOWNTIME_TARGET : integer := 2 * SCLK_DIV - 1; -- 2 SCLK cycles downtime between messages

    signal reg_a : STD_LOGIC_VECTOR(BITS_PER_MESSAGE - 1 downto 0) := (others => '0');
    signal reg_b : STD_LOGIC_VECTOR(BITS_PER_MESSAGE - 1 downto 0) := (others => '0');

    type state_t is (ready, read_high, read_low, downtime);
    signal state : state_t := ready;

    signal clk_div_cnt  : unsigned(3 downto 0) := (others => '0'); -- counts to SCLK_DIV/2 - 1
    signal shift_cnt    : unsigned(3 downto 0) := (others => '0'); -- shifts 16 bits
    signal downtime_cnt : unsigned(3 downto 0) := (others => '0'); -- counts through the downtime state

begin

    ad1_cs   <= '0' when state = read_high or state = read_low else '1'; 
    ad1_sclk <= '1' when state = read_high else '0';                   
    adc_rdy  <= '1' when state = ready else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= ready;
                reg_a <= (others => '0');
                reg_b <= (others => '0');
                shift_cnt <= (others => '0');
                clk_div_cnt <= (others => '0');
                downtime_cnt <= (others => '0');
                adc_data_a <= (others => '0');
                adc_data_b <= (others => '0');
            else 
                case state is
                    when ready =>
                        if adc_read = '1' then
                            state <= read_high;
                        end if;
                    when read_high =>
                        if to_integer(clk_div_cnt) = SCLK_DIV/2 - 1  then
                            state <= read_low;
                            clk_div_cnt <= (others => '0');
                            reg_a(BITS_PER_MESSAGE - 1 - to_integer(shift_cnt)) <= ad1_data_a;
                            reg_b(BITS_PER_MESSAGE - 1 - to_integer(shift_cnt)) <= ad1_data_b;
                        else
                            clk_div_cnt <= clk_div_cnt + 1;
                        end if;
                    when read_low =>
                        if to_integer(clk_div_cnt) = SCLK_DIV/2 - 1 then
                            clk_div_cnt <= (others => '0');
                             if to_integer(shift_cnt) = BITS_PER_MESSAGE - 1 then
                                state <= downtime;
                                adc_data_a <= reg_a(11 downto 0);
                                adc_data_b <= reg_b(11 downto 0);
                                shift_cnt <= (others => '0');
                            else
                                state <= read_high;
                                shift_cnt <= shift_cnt + 1;
                            end if;
                        else
                            clk_div_cnt <= clk_div_cnt + 1;
                        end if;
                    when downtime =>
                        if to_integer(downtime_cnt) = DOWNTIME_TARGET then
                            state <= ready;
                            downtime_cnt <= (others => '0');
                        else
                            downtime_cnt <= downtime_cnt + 1;
                        end if;            
                end case;
            end if;
        end if;
    end process;

end Behavioral;
