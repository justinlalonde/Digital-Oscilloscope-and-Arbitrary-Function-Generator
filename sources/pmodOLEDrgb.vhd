-------------------------------------------------------------------------------
-- Title       : PmodOLEDrgb_bitmap (https://digilent.com/reference/pmod/pmodoledrgb/reference-manual)
--                                  (https://yannick-bornat.enseirb-matmeca.fr/wiki/doku.php/en202:pmodoledrgb)
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : pmodOLEDrgb.vhd
-- Author      : Yannick Bornat
-- Created     : 2017-08-04
-- Last update : 2026-08-01
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module interfaces with the Digilent OLEDrgb Pmod extension board
--               which integrates a 96x64 pixel OLED display with 16-bit color resolution
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.constants_pkg.all;

entity pmodOLEDrgb is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           pix_write : in STD_LOGIC;
           pix_col : in STD_LOGIC_VECTOR (COL_INDEX_WIDTH - 1 downto 0);
           pix_row : in STD_LOGIC_VECTOR (ROW_INDEX_WIDTH - 1 downto 0);
           pix_data : in STD_LOGIC_VECTOR (COLOR_RESOLUTION - 1 downto 0);
           OLEDrgb_cs : out STD_LOGIC;
           OLEDrgb_mosi : out STD_LOGIC;
           OLEDrgb_sck : out STD_LOGIC;
           OLEDrgb_dc : out STD_LOGIC;
           OLEDrgb_res : out STD_LOGIC;
           OLEDrgb_vccen : out STD_LOGIC;
           OLEDrgb_en : out STD_LOGIC);
end pmodOLEDrgb;

architecture Behavioral of pmodOLEDrgb is

    constant LEFT_SIDE               : boolean := False; -- True if the Pmod is on the left side of the Basys 3 board

    constant SPI_FREQ                : integer := 6_666_666; -- 150ns SPI clk period
    constant SPI_HALFPER             : integer := (SYS_CLK_FREQ-1) / (SPI_FREQ * 2); -- max counter value for SPI_SCK hal periods

    constant DELAY_AFTER_SET_EN      : integer := SYS_CLK_FREQ / 50; -- 20ms
    constant DELAY_AFTER_CLEAR_RES   : integer := SYS_CLK_FREQ / 333; -- 15ms (actually 15.151ms) officially 3ms
    constant DELAY_AFTER_SET_RES_2   : integer := SYS_CLK_FREQ / 333; -- 15ms (actually 15.151ms) officially 3ms
    constant DELAY_AFTER_SET_VCCEN   : integer := SYS_CLK_FREQ / 40; -- 25ms
    constant DELAY_FOR_DISP_OK       : integer := SYS_CLK_FREQ / 10; -- 100ms
   
    constant MAX_WAIT : integer := SYS_CLK_FREQ / 10;
    signal wait_cnt   : integer range 0 to MAX_WAIT - 1; -- the counter for waiting states

    type t_OLED_FSM is (waking,            -- the state in which we go from reset
                        set_EN,            -- set EN
                        w_set_EN,          -- wait
                        clear_RES,         -- clear RES
                        w_clear_RES,       -- wait
                        set_RES_2,         -- set RES again
                        w_set_RES_2,       -- wait
                        send_unlock,       -- sends the unlock command : 0xFD 0x12
                        w_unlock,
                        send_disp_off,     -- display off command 0xAE
                        w_disp_off,
                        send_geom,         -- command 0xA0 0x72 (fixme : what does this command do ? reverting the module is 0xA0 0x60)
                        w_send_geom,
                        send_master_cfg,   -- master config, select ext Vcc. 0xAD, 0x8E
                        w_master_cfg,
                        dis_pow_saving,    -- 0xB0 0x0B
                        w_dis_pow_sav,
                        set_phase_len,     -- 0xB1, 0x31
                        w_phase_len,
                        setup_disp_clk,    -- 0xB3 0xF0
                        w_set_disp_clk,
                        pre_charge_voltg,  -- Set the Pre-Charge Voltage, 0xBB, 0x3A
                        w_pcv,
                        set_MastCurrAtt,   -- 0x87, 0x06 (See page 23 of the datasheet)
                        w_set_MCA,
                        set_VCCEN,         -- set VCCEN
                        w_set_VCCEN,
                        disp_on,           -- display on, 0xAF
                        w_disp_on,
                        prep_w_disp_ok,    -- 1 clock cycle to prepare the long wait just after
                        w_disp_ok,
                        refreshing);       -- system is idle and ready
    signal OLED_FSM : t_OLED_FSM;
 
    signal spi_sck       : std_logic;                     
    signal spi_shift_reg : std_logic_vector(15 downto 0); 
    signal spi_rem_bits  : integer range 0 to 15;         
 
    signal spi_send_ack  : boolean;                       
    signal spi_active    : boolean;                       
 
    type t_bitmap is array(0 to 6143) of std_logic_vector(COLOR_RESOLUTION-1 downto 0);
    signal bitmap        : t_bitmap;                      
    signal read_addr     : integer range 0 to 6143;       
    signal user_addr     : std_logic_vector(12 downto 0); 
    signal buff_next_pix : std_logic_vector(COLOR_RESOLUTION-1 downto 0); 
    signal write_dly     : std_logic;                     
    signal datin_dly     : std_logic_vector(COLOR_RESOLUTION-1 downto 0); 
   
begin
   
   process(clk)
   begin
      if rising_edge(clk) then
         if OLED_FSM = w_disp_ok then
            OLEDrgb_dc <= '1';
         elsif OLED_FSM = waking then
            OLEDrgb_dc <= '0';
         end if;
         
         if OLED_FSM = waking or OLED_FSM = w_set_RES_2 then
            OLEDrgb_res <= '1';
         elsif OLED_FSM = clear_RES then
            OLEDrgb_res <= '0';
         end if;
         
         if rst = '1' then
            OLEDrgb_en <= '0';
         elsif OLED_FSM = set_EN then
            OLEDrgb_en <= '1';
         end if;
         
         if OLED_FSM = set_VCCEN then
            OLEDrgb_vccen <= '1';
         elsif OLED_FSM = waking then
            OLEDrgb_vccen <= '0';
         end if;
         
         if rst = '1' then
            OLEDrgb_cs <= '1';
         elsif OLED_FSM = w_set_RES_2 then
            OLEDrgb_cs <= '0';
         end if;         
      end if;
   end process;
   
   process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            OLED_FSM <= waking;
         else
            case OLED_FSM is
               when waking           =>                      OLED_FSM <= set_EN;
               when set_EN           =>                      OLED_FSM <= w_set_EN;
               when w_set_EN         => if wait_cnt = 0 then OLED_FSM <= clear_RES;        end if;
               when clear_RES        =>                      OLED_FSM <= w_clear_RES;
               when w_clear_RES      => if wait_cnt = 0 then OLED_FSM <= set_RES_2;        end if;
               when set_RES_2        =>                      OLED_FSM <= w_set_RES_2;
               when w_set_RES_2      => if wait_cnt = 0 then OLED_FSM <= send_unlock;      end if;
               when send_unlock      =>                      OLED_FSM <= w_unlock;
               when w_unlock         => if spi_send_ack then OLED_FSM <= send_disp_off;    end if;
               when send_disp_off    =>                      OLED_FSM <= w_disp_off;
               when w_disp_off       => if spi_send_ack then OLED_FSM <= send_geom;        end if;
               when send_geom        =>                      OLED_FSM <= w_send_geom;
               when w_send_geom      => if spi_send_ack then OLED_FSM <= send_master_cfg;  end if;
               when send_master_cfg  =>                      OLED_FSM <= w_master_cfg;
               when w_master_cfg     => if spi_send_ack then OLED_FSM <= dis_pow_saving;   end if;
               when dis_pow_saving   =>                      OLED_FSM <= w_dis_pow_sav;
               when w_dis_pow_sav    => if spi_send_ack then OLED_FSM <= set_phase_len;    end if;
               when set_phase_len    =>                      OLED_FSM <= w_phase_len;
               when w_phase_len      => if spi_send_ack then OLED_FSM <= setup_disp_clk;   end if;
               when setup_disp_clk   =>                      OLED_FSM <= w_set_disp_clk;
               when w_set_disp_clk   => if spi_send_ack then OLED_FSM <= pre_charge_voltg; end if;
               when pre_charge_voltg =>                      OLED_FSM <= w_pcv;
               when w_pcv            => if spi_send_ack then OLED_FSM <= set_MastCurrAtt;  end if;
               when set_MastCurrAtt  =>                      OLED_FSM <= w_set_MCA;
               when w_set_MCA        => if spi_send_ack then OLED_FSM <= set_VCCEN;        end if;
               when set_VCCEN        =>                      OLED_FSM <= w_set_VCCEN;
               when w_set_VCCEN      => if wait_cnt = 0 then OLED_FSM <= disp_on;          end if;
               when disp_on          =>                      OLED_FSM <= w_disp_on;
               when w_disp_on        => if spi_send_ack then OLED_FSM <= prep_w_disp_ok;   end if;
               when prep_w_disp_ok   =>                      OLED_FSM <= w_disp_ok;
               when w_disp_ok        => if wait_cnt = 0 then OLED_FSM <= refreshing;       end if;
               when refreshing       => null;
            end case;
         end if;
      end if;
   end process;

   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when set_EN           => wait_cnt <= DELAY_AFTER_SET_EN       - 1;
            when clear_RES        => wait_cnt <= DELAY_AFTER_CLEAR_RES    - 1;
            when set_RES_2        => wait_cnt <= DELAY_AFTER_SET_RES_2    - 1;
            when set_VCCEN        => wait_cnt <= DELAY_AFTER_SET_VCCEN    - 1;
            when prep_w_disp_ok   => wait_cnt <= DELAY_FOR_DISP_OK        - 1;
            when send_unlock
               | send_disp_off
               | send_geom
               | send_master_cfg
               | dis_pow_saving
               | set_phase_len
               | setup_disp_clk
               | pre_charge_voltg
               | set_MastCurrAtt
               | disp_on
                                  => wait_cnt <= SPI_HALFPER;
            when others           => 
                                     
               if wait_cnt > 0 then
                  wait_cnt <= wait_cnt - 1;
               else
                  wait_cnt <= SPI_HALFPER;
               end if;
         end case;
      end if;
   end process;

   process(OLED_FSM)
   begin
      case OLED_FSM is
         when w_unlock
            | w_disp_off
            | w_send_geom
            | w_master_cfg
            | w_dis_pow_sav
            | w_phase_len
            | w_set_disp_clk
            | w_pcv
            | w_set_MCA
            | w_disp_on
            | refreshing    => spi_active <= True;
         when others        => spi_active <= False;
      end case;
   end process;

   OLEDrgb_sck <= spi_sck;
   process(clk)
   begin
      if rising_edge(clk) then
         if rst = '1' then
            spi_sck <= '0';
         elsif spi_active then
            if wait_cnt = 0 then
               spi_sck <= not spi_sck;
            end if;
         else
            spi_sck <= '0';
         end if;
      end if;
   end process;

   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when send_unlock
               | send_geom
               | send_master_cfg
               | dis_pow_saving
               | set_phase_len
               | setup_disp_clk
               | pre_charge_voltg
               | set_MastCurrAtt
                                  => spi_rem_bits <= 15;
            when send_disp_off
               | disp_on          => spi_rem_bits <= 7;
            when others           => 
               if wait_cnt = 0 and spi_sck = '1' then
                  if spi_rem_bits > 0 then
                     spi_rem_bits <= spi_rem_bits - 1;
                  else
                     spi_rem_bits <= 15;
                  end if;
               end if;
         end case;
      end if;
   end process;

   OLEDrgb_mosi <= spi_shift_reg(15);
   process(clk)
   begin
      if rising_edge(clk) then
         case OLED_FSM is
            when send_unlock      => spi_shift_reg <= x"FD12";
            when send_geom        => if LEFT_SIDE then spi_shift_reg <= x"A061";
                                     else              spi_shift_reg <= x"A073"; end if;
            when send_master_cfg  => spi_shift_reg <= x"AD8E";
            when dis_pow_saving   => spi_shift_reg <= x"B00B";
            when set_phase_len    => spi_shift_reg <= x"B131";
            when setup_disp_clk   => spi_shift_reg <= x"B3F0";
            when pre_charge_voltg => spi_shift_reg <= x"BB2A";
            when set_MastCurrAtt  => spi_shift_reg <= x"8706";
            when send_disp_off    => spi_shift_reg <= x"AE00";
            when disp_on          => spi_shift_reg <= x"AF00";
            when w_disp_ok        => spi_shift_reg <= buff_next_pix;
            when others           => 
               if wait_cnt = 0 and spi_sck = '1' and spi_active then
                  if spi_rem_bits > 0 then
                     spi_shift_reg(15 downto 1) <= spi_shift_reg(14 downto 0);
                  else
                     spi_shift_reg <= buff_next_pix;
                  end if;
               end if;
         end case;
      end if;
   end process;

   spi_send_ack <= wait_cnt = 0 and spi_sck = '1' and spi_rem_bits = 0;

   process(clk)
   begin
      if rising_edge(clk) then
         if OLED_FSM /= refreshing then
            read_addr <= 0;
         elsif spi_rem_bits = 12 and wait_cnt = 0 and spi_sck = '1' then
            if read_addr = 6143 then
               read_addr <= 0;
            else
               read_addr <= read_addr + 1;
            end if;
         end if;
      end if;
   end process;
 
   process(clk)
   begin
      if rising_edge(clk) then
            write_dly     <= pix_write;
            user_addr     <= (pix_col(6) and not pix_col(5)) & pix_col(5 downto 0) & pix_row;
            datin_dly     <= pix_data;
            if write_dly = '1' then
               bitmap(to_integer(unsigned(user_addr))) <= datin_dly;
            end if;
            buff_next_pix <= bitmap(read_addr);
      end if;
   end process;
 
end Behavioral;
