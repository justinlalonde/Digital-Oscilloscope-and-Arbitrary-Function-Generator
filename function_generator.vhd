-------------------------------------------------------------------------------
-- Title       : Function Generator
-- Project     : Digital Oscilloscope and Function Generator
-------------------------------------------------------------------------------
-- File        : function_generator.vhd
-- Author      : Justin Lalonde (AI assistance)
-- Created     : 2026-07-29
-- Last update : 2026-08-02
-- Platform    : Xilinx Artix-7
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description : this module implements the arbitrary function generator logic
--               for two independent channels (A and B). Each channel has an
--               adjustable frequency (power-of-two Hz steps), amplitude
--               (power-of-two fraction of full scale), and waveform type 
--               (sine / square / sawtooth). Although the actual analog front 
--               end is managed by the pmodDA2 module which interfaces with the 
--               DAC IC, this module manages the digital back end of signal generation.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;
use work.constants_pkg.all;

entity function_generator is
    Port ( clk         : in  STD_LOGIC;
           rst         : in  STD_LOGIC;
           dac_rdy     : in  STD_LOGIC;
           dac_data_a  : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           dac_data_b  : out STD_LOGIC_VECTOR (DATA_WIDTH - 1 downto 0);
           selected_ch : in  STD_LOGIC;   -- '0' = channel A, '1' = channel B
           amp_up      : in  STD_LOGIC;
           amp_down    : in  STD_LOGIC;
           freq_up     : in  STD_LOGIC;
           freq_down   : in  STD_LOGIC;
           type_up     : in  STD_LOGIC;
           type_down   : in  STD_LOGIC
           );
end function_generator;

architecture Behavioral of function_generator is

    constant SYS_CLK_FREQ_R : real := real(SYS_CLK_FREQ);
    constant SHIFT_BITS     : integer := 24; 

    constant MAX_FREQ     : integer := 19; -- 2^19 = 524.288 kHz
    constant DEFAULT_FREQ : integer := 13; -- 2^13 = 8.192 kHz
    signal a_freq        : unsigned(4 downto 0) := to_unsigned(DEFAULT_FREQ, 5);
    signal a_freq_factor : unsigned(MAX_FREQ downto 0);          -- = 2^a_freq
    signal b_freq        : unsigned(4 downto 0) := to_unsigned(DEFAULT_FREQ, 5);
    signal b_freq_factor : unsigned(MAX_FREQ downto 0);          -- = 2^b_freq

    constant MAX_AMP     : integer := DATA_WIDTH / 2 - 1; -- 5 for DATA_WIDTH=12
    constant DEFAULT_AMP : integer := MAX_AMP;             -- full amplitude by default
    signal a_amp        : unsigned(2 downto 0) := to_unsigned(DEFAULT_AMP, 3);
    signal a_amp_factor : unsigned(MAX_AMP downto 0);            -- = 2^a_amp
    signal b_amp        : unsigned(2 downto 0) := to_unsigned(DEFAULT_AMP, 3);
    signal b_amp_factor : unsigned(MAX_AMP downto 0);            -- = 2^b_amp

    type signal_type_t is (sine, square, sawtooth);
    signal a_type : signal_type_t := sine;
    signal b_type : signal_type_t := sine;

    constant PHASE_RECIP : unsigned(31 downto 0) :=
        to_unsigned(integer(round((2.0**PHASE_WIDTH / SYS_CLK_FREQ_R) * 2.0**SHIFT_BITS)), 32);

    signal a_phase_mult_result : unsigned(51 downto 0); 
    signal b_phase_mult_result : unsigned(51 downto 0);

    signal a_wave_delta        : signed(DATA_WIDTH downto 0); 
    signal b_wave_delta        : signed(DATA_WIDTH downto 0);
    signal a_amp_factor_signed : signed(MAX_AMP + 1 downto 0); 
    signal b_amp_factor_signed : signed(MAX_AMP + 1 downto 0);
    signal a_amp_mult_result   : signed(DATA_WIDTH + MAX_AMP + 2 downto 0); 
    signal b_amp_mult_result   : signed(DATA_WIDTH + MAX_AMP + 2 downto 0);
    signal a_dac_signed        : signed(DATA_WIDTH downto 0); 
    signal b_dac_signed        : signed(DATA_WIDTH downto 0);

    signal a_phase         : STD_LOGIC_VECTOR(PHASE_WIDTH - 1 downto 0);
    signal a_phase_shifted : STD_LOGIC_VECTOR(PHASE_WIDTH - 1 downto 0); 
    signal a_phase_incr    : STD_LOGIC_VECTOR(PHASE_WIDTH - 1 downto 0);
    signal a_sine_val      : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal a_square_val    : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal a_sawtooth_val  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal a_wave_val      : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

    signal b_phase         : STD_LOGIC_VECTOR(PHASE_WIDTH - 1 downto 0);
    signal b_phase_shifted : STD_LOGIC_VECTOR(PHASE_WIDTH - 1 downto 0);
    signal b_phase_incr    : STD_LOGIC_VECTOR(PHASE_WIDTH - 1 downto 0);
    signal b_sine_val      : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal b_square_val    : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal b_sawtooth_val  : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);
    signal b_wave_val      : STD_LOGIC_VECTOR(DATA_WIDTH - 1 downto 0);

begin

    a_sine_lut_inst : entity work.sine_lut
        port map(
            clk      => clk,
            rst      => rst,
            phase    => a_phase, --
            sine_val => a_sine_val
        );

    a_square_lut_inst : entity work.square_lut
        port map(
            clk        => clk,
            rst        => rst,
            phase      => a_phase, --
            square_val => a_square_val
        );

    a_sawtooth_lut_inst : entity work.sawtooth_lut
        port map(
            clk          => clk,
            rst          => rst,
            phase        => a_phase, --
            sawtooth_val => a_sawtooth_val
        );

    a_phase_accumulator_inst : entity work.phase_accumulator
        port map(
            clk        => clk,
            rst        => rst,
            phase_incr => a_phase_incr,
            phase      => a_phase 
        );

    b_sine_lut_inst : entity work.sine_lut
        port map(
            clk      => clk,
            rst      => rst,
            phase    => b_phase, -- 
            sine_val => b_sine_val
        );

    b_square_lut_inst : entity work.square_lut
        port map(
            clk        => clk,
            rst        => rst,
            phase      => b_phase, --
            square_val => b_square_val
        );

    b_sawtooth_lut_inst : entity work.sawtooth_lut
        port map(
            clk          => clk,
            rst          => rst,
            phase        => b_phase,--
            sawtooth_val => b_sawtooth_val
        );

    b_phase_accumulator_inst : entity work.phase_accumulator
        port map(
            clk        => clk,
            rst        => rst,
            phase_incr => b_phase_incr,
            phase      => b_phase
        );

    a_wave_val <= a_sine_val   when a_type = sine   else
                  a_square_val when a_type = square else
                  a_sawtooth_val;

    b_wave_val <= b_sine_val   when b_type = sine   else
                  b_square_val when b_type = square else
                  b_sawtooth_val;

    a_freq_factor <= shift_left(to_unsigned(1, a_freq_factor'length), to_integer(a_freq));
    b_freq_factor <= shift_left(to_unsigned(1, b_freq_factor'length), to_integer(b_freq));

    a_amp_factor <= shift_left(to_unsigned(1, a_amp_factor'length), to_integer(a_amp));
    b_amp_factor <= shift_left(to_unsigned(1, b_amp_factor'length), to_integer(b_amp));

    a_wave_delta <= signed(resize(unsigned(a_wave_val), DATA_WIDTH + 1)) - to_signed(MID_SCALE, DATA_WIDTH + 1);
    b_wave_delta <= signed(resize(unsigned(b_wave_val), DATA_WIDTH + 1)) - to_signed(MID_SCALE, DATA_WIDTH + 1);

    a_amp_factor_signed <= signed('0' & std_logic_vector(a_amp_factor));
    b_amp_factor_signed <= signed('0' & std_logic_vector(b_amp_factor));

    a_dac_signed <= resize(shift_right(a_amp_mult_result, MAX_AMP), DATA_WIDTH + 1) + to_signed(MID_SCALE, DATA_WIDTH + 1);
    b_dac_signed <= resize(shift_right(b_amp_mult_result, MAX_AMP), DATA_WIDTH + 1) + to_signed(MID_SCALE, DATA_WIDTH + 1);

    dac_data_a <= std_logic_vector(unsigned(a_dac_signed(DATA_WIDTH - 1 downto 0)));
    dac_data_b <= std_logic_vector(unsigned(b_dac_signed(DATA_WIDTH - 1 downto 0)));

    a_phase_incr <= std_logic_vector(a_phase_mult_result(SHIFT_BITS + PHASE_WIDTH - 1 downto SHIFT_BITS));
    b_phase_incr <= std_logic_vector(b_phase_mult_result(SHIFT_BITS + PHASE_WIDTH - 1 downto SHIFT_BITS));

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_phase_mult_result <= (others => '0');
                b_phase_mult_result <= (others => '0');
                a_amp_mult_result   <= (others => '0');
                b_amp_mult_result   <= (others => '0');
            else
                a_phase_mult_result <= a_freq_factor * PHASE_RECIP;
                b_phase_mult_result <= b_freq_factor * PHASE_RECIP;
                a_amp_mult_result   <= a_wave_delta * a_amp_factor_signed;
                b_amp_mult_result   <= b_wave_delta * b_amp_factor_signed;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge (clk) then
            if rst = '1' then
                a_type <= sine;
                b_type <= sine;
            else
                if selected_ch = '0' then
                    case a_type is
                        when sine =>
                            if type_up = '1' then a_type <= square; end if;
                        when square =>
                            if type_up = '1' then a_type <= sawtooth;
                            elsif type_down = '1' then a_type <= sine; end if;
                        when sawtooth =>
                            if type_down = '1' then a_type <= square; end if;
                    end case;
                else
                    case b_type is
                        when sine =>
                            if type_up = '1' then b_type <= square; end if;
                        when square =>
                            if type_up = '1' then b_type <= sawtooth;
                            elsif type_down = '1' then b_type <= sine; end if;
                        when sawtooth =>
                            if type_down = '1' then b_type <= square; end if;
                    end case;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_freq <= to_unsigned(DEFAULT_FREQ, a_freq'length);
                b_freq <= to_unsigned(DEFAULT_FREQ, b_freq'length);
            else
                if selected_ch = '0' then
                    if freq_up = '1' and a_freq < MAX_FREQ then
                        a_freq <= a_freq + 1;
                    elsif freq_down = '1' and a_freq > 0 then
                        a_freq <= a_freq - 1;
                    end if;
                else
                    if freq_up = '1' and b_freq < MAX_FREQ then
                        b_freq <= b_freq + 1;
                    elsif freq_down = '1' and b_freq > 0 then
                        b_freq <= b_freq - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                a_amp <= to_unsigned(DEFAULT_AMP, a_amp'length);
                b_amp <= to_unsigned(DEFAULT_AMP, b_amp'length);
            else
                if selected_ch = '0' then
                    if amp_up = '1' and a_amp < MAX_AMP then
                        a_amp <= a_amp + 1;
                    elsif amp_down = '1' and a_amp > 0 then
                        a_amp <= a_amp - 1;
                    end if;
                else
                    if amp_up = '1' and b_amp < MAX_AMP then
                        b_amp <= b_amp + 1;
                    elsif amp_down = '1' and b_amp > 0 then
                        b_amp <= b_amp - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
