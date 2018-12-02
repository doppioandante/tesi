library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity square_to_pwm_tb is
end square_to_pwm_tb;

architecture testbench of square_to_pwm_tb is
    constant clock_period: time := 10 ns;
    constant sampling_frequency: positive := 48_000;
    constant sample_bits: positive := 11;

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;

    package midi_to_phase is new work.midi_to_phase_generic
    generic map(
        phase_update_frequency => 100_000_000,
        phase_bits => phase_bits,
        rom_filename => "note_phase_table.txt"
    );

    constant note_number: std_logic_vector(6 downto 0) := 7d"105"; -- A 880 Hz

    constant step_phase: std_logic_vector(phase_bits-1 downto 0) :=
        midi_to_phase.midi_note_to_phase_step(note_number);

    signal clock: std_logic;

    signal sample: std_logic_vector(sample_bits-1 downto 0);
    signal pwm_out: std_logic;

    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    sqr_generator: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        i_clock => clock,
        i_rst => '0',
        i_ftw => step_phase,
        o_sample_ready_reg => open,
        o_sample_reg => sample
    );

    pwm_generator: entity work.pwm_encoder
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        i_clk => clock,
        i_sample => sample,
        o_pwm_signal => pwm_out
    );

    test_process: process
    begin
        wait for 20 ms;

        stop_write <= true;
    end process test_process;

    logger: entity work.tb_logger
    generic map(
        clock_frequency => 100_000_000,
        filename => "pwm_out.txt"
    )
    port map(
        i_clock => clock,
        i_pwm => pwm_out,
        i_stop => stop_write
    );
end testbench;
