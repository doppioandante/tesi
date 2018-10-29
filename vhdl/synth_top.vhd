library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity synth_top is
    port(
        CLK100MHZ: in std_logic;

        AUD_PWM: out std_logic;
        AUD_SD: out std_logic
    );
end synth_top;

architecture dataflow of synth_top is
    constant sampling_frequency: positive := 10_000_000;
    constant sample_bits: positive := 1;

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;
    constant step_phase: positive := 18897; --positive(ceil(real(2**phase_bits) * real(wave_frequency)/real(100_000_000)));pro  

    signal sample_ready: std_logic;
    signal sample: std_logic_vector(sample_bits-1 downto 0);
begin
    AUD_SD <= '1';

    sqr_generator: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        clock => CLK100MHZ,
        phase_input_enable => '1',
        phase_step => to_std_logic_vector(step_phase, phase_bits),
        output_enable => sample_ready,
        output_sample => sample
    );

    pwm_generator: entity work.pwm_converter
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        clock => CLK100MHZ,
        input_enable => sample_ready,
        sample => sample,
        pwm_out => AUD_PWM
    );
end dataflow;