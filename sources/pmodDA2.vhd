-------------------------------------------------------------------------------
-- Title       : Pmod DA2 (https://digilent.com/reference/pmod/pmodda2/reference-manual)
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : pmodDA2.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module interfaces with the Digilent DA2 Pmod extension board
--               which integrates two single-channel 12 bit DACs
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity pmodDA2 is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           dac_write : in STD_LOGIC;
           dac_rdy : out STD_LOGIC;
           dac_data_a : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           dac_data_b : in STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           da2_sync : out STD_LOGIC;
           da2_data_a : out STD_LOGIC;
           da2_data_b : out STD_LOGIC;
           da2_sclk : out STD_LOGIC);
end pmodDA2;

architecture Behavioral of pmodDA2 is

    constant SCLK_DIV : integer := 6;
    constant BITS_PER_MESSAGE : integer := 16;

    signal reg_a : STD_LOGIC_VECTOR(BITS_PER_MESSAGE - 1 downto 0) := (others => '0');
    signal reg_b : STD_LOGIC_VECTOR(BITS_PER_MESSAGE - 1 downto 0) := (others => '0');

    type state_t is (ready, write_high, write_low);
    signal state : state_t := ready;

    signal clk_div_cnt : unsigned(3 downto 0) := (others => '0'); 
    signal shift_cnt   : unsigned(3 downto 0) := (others => '0'); 

begin

    da2_sync <= '0' when state = write_high or state = write_low else '1';
    da2_sclk <= '1' when state = write_high else '0';
    da2_data_a <= reg_a(BITS_PER_MESSAGE-1 - to_integer(shift_cnt)); 
    da2_data_b <= reg_b(BITS_PER_MESSAGE-1 - to_integer(shift_cnt));
    dac_rdy  <= '1' when state = ready else '0';

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= ready;
                reg_a <= (others => '0');
                reg_b <= (others => '0');
                shift_cnt <= (others => '0');
                clk_div_cnt <= (others => '0');
            else
                case state is
                    when ready =>
                        if dac_write = '1' then
                            state <= write_high;
                            reg_a <= "0000" & dac_data_a;
                            reg_b <= "0000" & dac_data_b;
                        end if;
                    when write_high =>
                        if to_integer(clk_div_cnt) = SCLK_DIV/2 - 1  then
                            state <= write_low;
                            clk_div_cnt <= (others => '0');
                        else
                            clk_div_cnt <= clk_div_cnt + 1;
                        end if;
                    when write_low =>
                        if to_integer(clk_div_cnt) = SCLK_DIV/2 - 1 then
                            clk_div_cnt <= (others => '0');
                            if to_integer(shift_cnt) = BITS_PER_MESSAGE - 1 then
                                state <= ready;
                                shift_cnt <= (others => '0');
                            else 
                                state <= write_high;   
                                shift_cnt <= shift_cnt + 1; 
                            end if;  
                        else    
                            clk_div_cnt <= clk_div_cnt + 1;    
                        end if;      
                end case;
            end if;       
        end if;   
    end process;

end Behavioral;
