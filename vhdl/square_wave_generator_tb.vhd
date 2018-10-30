library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity square_wave_generator_tb is
end square_wave_generator_tb;

architecture testbench of square_wave_generator_tb is
    constant clock_period: time := 10 ns;
    -- 10 MHz sampling frequency (100ns sampling period)
    -- such an high sampling rate will allow only 10 datapoints
    constant sampling_frequency: positive := 10_000_000;
    constant sample_bits: positive := 1; -- only one needed for a square wave

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;
    constant step_phase: positive := positive(ceil(real(2**phase_bits) * real(wave_frequency)/real(100_000_000)));

    signal clock: std_logic;

    signal input_enable: std_logic;
    signal sample: std_logic_vector(sample_bits-1 downto 0);
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    uut: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        clock => clock,
        ce => '1',
        phase_input_enable => input_enable,
        phase_step => to_std_logic_vector(step_phase, phase_bits),
        output_enable => open,
        output_sample => sample
    );

    test_process: process
    begin
        wait for clock_period;
        input_enable <= '1';
        wait for clock_period;
        input_enable <= '0';
        wait for 4 ms;

        std.env.stop;
    end process test_process;
end testbench;
