-------------------------------------------------------------------------------
-- Title       : Layer Compositor
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : layer_compositor.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module implements layer priority so that some display
--               features and objects may apppear on screen with the right priority
--               (for example : cursors are shown on top of waveforms in oscilloscope
--               window)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity layer_compositor is
    Port(   clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            lay_col : out STD_LOGIC_VECTOR (COL_INDEX_WIDTH - 1 downto 0);
            lay_row : out STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
            bg_active : in STD_LOGIC;
            bg_rgb : in STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
            ch1_active : in STD_LOGIC;
            ch1_rgb : in STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
            ch2_active : in STD_LOGIC;
            ch2_rgb : in STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
            ch1_curs_active : in STD_LOGIC;
            ch1_curs_rgb : in STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
            ch2_curs_active : in STD_LOGIC;
            ch2_curs_rgb : in STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
            pix_write : out STD_LOGIC;
            pix_col : out STD_LOGIC_VECTOR (COL_INDEX_WIDTH - 1 downto 0);
            pix_row : out STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
            pix_data : out STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0));
end layer_compositor;

architecture Behavioral of layer_compositor is

    signal col_cnt : unsigned(COL_INDEX_WIDTH - 1 downto 0) := (others => '0');
    signal row_cnt : unsigned(ROW_INDEX_WIDTH - 1 downto 0) := (others => '0'); 

begin

    col_delay_line : entity work.delay_line
    generic map ( WIDTH => COL_INDEX_WIDTH, DEPTH => COMPOSITOR_PIPELINE_LATENCY)
    port map(
        clk => clk,
        rst => rst,
        d   => std_logic_vector(col_cnt),
        q   => pix_col
    );
    
    row_delay_line : entity work.delay_line
    generic map ( WIDTH => ROW_INDEX_WIDTH, DEPTH => COMPOSITOR_PIPELINE_LATENCY)
    port map(
        clk => clk,
        rst => rst,
        d   => std_logic_vector(row_cnt),
        q   => pix_row
    );

    lay_col <= std_logic_vector(col_cnt);
    lay_row <= std_logic_vector(row_cnt);
    pix_data <= ch1_curs_rgb when ch1_curs_active = '1' else
                ch2_curs_rgb when ch2_curs_active = '1' else
                ch1_rgb when ch1_active = '1' else
                ch2_rgb when ch2_active = '1' else
                bg_rgb when bg_active = '1' else 
                (others => '0');

    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                row_cnt <= (others => '0');
                col_cnt <= (others => '0');
                pix_write <= '0';
             else
                pix_write <= '1';
                if  to_integer(col_cnt) = SCREEN_WIDTH - 1 then
                    if to_integer(row_cnt) = SCREEN_HEIGHT - 1 then
                        row_cnt <= (others => '0');
                        col_cnt <= (others => '0');   
                    else
                        row_cnt <= row_cnt + 1;
                        col_cnt <= (others => '0');
                    end if;
                else
                    col_cnt <= col_cnt + 1; 
                end if;       
            end if;
        end if;
    end process;

end Behavioral;
