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
    constant sampling_frequency: positive := 48000;
    constant sample_bits: positive := 1; -- only one needed for a square wave

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;
    constant ftw: positive := positive(ceil(real(2**phase_bits) * real(wave_frequency)/real(100_000_000)));

    signal clock: std_logic;

    signal sample_ready: std_logic;
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
        i_clock => clock,
        i_rst => sample_ready,
        i_ftw => to_std_logic_vector(ftw, phase_bits),
        o_sample_ready_reg => sample_ready,
        o_sample_reg => sample
    );

    test_process: process
    begin
        wait for 4 ms;

        std.env.stop;
    end process test_process;
end testbench;
