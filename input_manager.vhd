-------------------------------------------------------------------------------
-- Title       : Input Manager
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : input_manager.vhd
-- Author      : Justin Lalonde 
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module parses the raw button and switch input into usable,
--               synchronized pulsed signals for the other modules to use. 
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity input_manager is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           btnU : in STD_LOGIC;
           btnD : in STD_LOGIC;
           btnR : in STD_LOGIC;
           btnL : in STD_LOGIC;
           sw : in STD_LOGIC_VECTOR (2 downto 0);
           selected_ch : out STD_LOGIC;
           cursors_en  : out STD_LOGIC;
           h_zoom_in : out STD_LOGIC;
           h_zoom_out : out STD_LOGIC;
           v_zoom_in : out STD_LOGIC;
           v_zoom_out : out STD_LOGIC;
           curs0_up : out STD_LOGIC;
           curs0_down : out STD_LOGIC;
           curs1_up : out STD_LOGIC;
           curs1_down : out STD_LOGIC;
           amp_up : out STD_LOGIC;
           amp_down : out STD_LOGIC;
           freq_up : out STD_LOGIC;
           freq_down : out STD_LOGIC;
           type_up : out STD_LOGIC;
           type_down : out STD_LOGIC);
end input_manager;

architecture Behavioral of input_manager is

    signal btnu_db : STD_LOGIC;
    signal btnd_db : STD_LOGIC;
    signal btnl_db : STD_LOGIC;
    signal btnr_db : STD_LOGIC;
    
    signal r_btnu_db : STD_LOGIC;
    signal r_btnd_db : STD_LOGIC;
    signal r_btnl_db : STD_LOGIC;
    signal r_btnr_db : STD_LOGIC;

begin

    btnu_debounce : entity work.debounce
    port map(
        clk => clk,
        rst => rst,
        btn_in => btnu,
        btn_out => btnu_db
    );

    btnd_debounce : entity work.debounce
    port map(
        clk => clk,
        rst => rst,
        btn_in => btnd,
        btn_out => btnd_db
    );

    btnl_debounce : entity work.debounce
    port map(
        clk => clk,
        rst => rst,
        btn_in => btnl,
        btn_out => btnl_db
    );

    btnr_debounce : entity work.debounce
    port map(
        clk => clk,
        rst => rst,
        btn_in => btnr,
        btn_out => btnr_db
    );

    selected_ch <= sw(1);
    cursors_en <= '1' when sw(0) = '0' and sw(2) = '1' else '0';

    process(all)
    begin
        if r_btnr_db = '0' and btnr_db = '1' then
            if sw(0) = '0' then
                if sw(2) = '0' then
                    curs1_up <= '0';
                    freq_up <= '0';
                    h_zoom_in <= '1';
                else
                    h_zoom_in <= '0';
                    freq_up <= '0';
                    curs1_up <= '1';   
                end if;
            else
                if sw(2) = '0' then
                    h_zoom_in <= '0';
                    curs1_up <= '0';
                    freq_up <= '1';
                else
                    h_zoom_in <= '0';
                    curs1_up <= '0';
                    freq_up <= '0';
                end if;
            end if;
        else
            h_zoom_in <= '0';
            curs1_up <= '0';
            freq_up <= '0';
        end if;
        if r_btnd_db = '0' and btnd_db = '1' then
            if sw(0) = '0' then
                if sw(2) = '0' then
                    curs0_down <= '0';
                    amp_down <= '0';
                    type_down <= '0';
                    v_zoom_out <= '1';
                else
                    v_zoom_out <= '0';
                    amp_down <= '0';
                    type_down <= '0';
                    curs0_down <= '1';
                end if;
            else
                if sw(2) = '0' then
                    v_zoom_out <= '0';
                    curs0_down <= '0';
                    type_down <= '0';
                    amp_down <= '1';
                else
                    v_zoom_out <= '0';
                    curs0_down <= '0';
                    amp_down <= '0';
                    type_down <= '1';
                end if;
            end if;
        else
            v_zoom_out <= '0';
            curs0_down <= '0';
            amp_down <= '0';
            type_down <= '0';
        end if;
        if r_btnl_db = '0' and btnl_db = '1' then
            if sw(0) = '0' then
                if sw(2) = '0' then
                    curs1_down <= '0';
                    freq_down <= '0';
                    h_zoom_out <= '1';
                else
                    h_zoom_out <= '0';
                    freq_down <= '0';
                    curs1_down <= '1';  
                end if;
            else
                if sw(2) = '0' then
                    h_zoom_out <= '0';
                    curs1_down <= '0';
                    freq_down <= '1';
                else
                    h_zoom_out <= '0';
                    curs1_down <= '0';
                    freq_down <= '0';
                end if;
            end if;
        else
            h_zoom_out <= '0';
            curs1_down <= '0';
            freq_down <= '0';
        end if;
        if r_btnu_db = '0' and btnu_db = '1' then
            if sw(0) = '0' then
                if sw(2) = '0' then
                    curs0_up <= '0';
                    amp_up <= '0';
                    type_up <= '0';
                    v_zoom_in <= '1';
                else
                    v_zoom_in <= '0';
                    amp_up <= '0';
                    type_up <= '0';
                    curs0_up <= '1';
                end if;
            else
                if sw(2) = '0' then
                    v_zoom_in <= '0';
                    curs0_up <= '0';
                    type_up <= '0';
                    amp_up <= '1';
                else
                    v_zoom_in <= '0';
                    curs0_up <= '0';
                    amp_up <= '0';
                    type_up <= '1';
                end if;
            end if;
        else
            v_zoom_in <= '0';
            curs0_up <= '0';
            amp_up <= '0';
            type_up <= '0';
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                r_btnu_db <= '0';
                r_btnd_db <= '0';
                r_btnl_db <= '0';
                r_btnr_db <= '0';
            else
                r_btnu_db <= btnu_db;
                r_btnd_db <= btnd_db;
                r_btnl_db <= btnl_db;
                r_btnr_db <= btnr_db;
            end if;
        end if;
    end process;

end Behavioral;
