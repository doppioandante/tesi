library ieee;
use ieee.std_logic_1164.all;
use work.midi.MAX_MIDI_NOTE_NUMBER;

entity poly_square_to_pwm_tb is
end poly_square_to_pwm_tb;

architecture testbench of poly_square_to_pwm_tb is
    constant clock_period: time := 10 ns;
    constant sampling_frequency: positive := 6250000;
    constant sample_bits: positive := 4;

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;

    package midi_to_phase is new work.midi_to_phase_generic
    generic map(
        phase_update_frequency => 100_000_000,
        phase_bits => phase_bits,
        rom_filename => "note_phase_table.txt"
    );

    constant note_number_1: std_logic_vector(6 downto 0) := 7d"69"; -- A 440 Hz
    constant note_number_2: std_logic_vector(6 downto 0) := 7d"73"; -- C#

    constant step_phase_1: std_logic_vector(phase_bits-1 downto 0) := midi_to_phase.midi_note_to_phase_step(note_number_1);
    constant step_phase_2: std_logic_vector(phase_bits-1 downto 0) := midi_to_phase.midi_note_to_phase_step(note_number_2);

    signal clock: std_logic;

    signal active_notes: std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0) :=
        (69 => '1', 73 => '1', others => '0');

    signal input_samples: std_logic_vector((MAX_MIDI_NOTE_NUMBER+1)*sample_bits-1 downto 0) := (others => '0');
    signal generate_output_sample: std_logic := '0';

    signal sample_1, sample_2: std_logic_vector(sample_bits-1 downto 0);
    signal mixed_sample: std_logic_vector(sample_bits downto 0) := (others => '0');

    signal sample_ready_1, sample_ready_2: std_logic := '0';
    signal rst: std_logic := '0';
    signal pwm_out: std_logic;

    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    sqr_generator_1: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        i_clock => clock,
        i_rst => rst,
        i_ftw => step_phase_1,
        o_sample_ready_reg => sample_ready_1,
        o_sample_reg => sample_1
    );

    sqr_generator_2: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        i_clock => clock,
        i_rst => rst,
        i_ftw => step_phase_2,
        o_sample_ready_reg => sample_ready_2,
        o_sample_reg => sample_2
    );

    input_samples((69+1)*sample_bits-1 downto 69*sample_bits) <= sample_1;
    input_samples((73+1)*sample_bits-1 downto 73*sample_bits) <= sample_2;

    generate_output_sample <= sample_ready_1 and sample_ready_2;
    rst <= generate_output_sample;

    mixer: entity work.mixer
    generic map (
        sample_bits => sample_bits,
        output_bits => sample_bits+1,
        number_of_inputs => MAX_MIDI_NOTE_NUMBER+1
    )
    port map (
        i_clock => clock,

        i_active_notes => active_notes,
        i_samples => input_samples,
        i_generate_output_sample => generate_output_sample,
        o_sample_reg => mixed_sample
    );

    pwm_generator: entity work.pwm_encoder
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        i_clk => clock,
        i_sample => mixed_sample(sample_bits downto 1),
        o_pwm_signal => pwm_out
    );

    test_process: process
    begin
        wait for 61 ms;

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
