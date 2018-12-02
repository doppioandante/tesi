library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use work.midi.MAX_MIDI_NOTE_NUMBER;

entity synth_top is
    port(
        CLK100MHZ: in std_logic;

        UART_TXD_IN: in std_logic;

        AUD_PWM: out std_logic;
        AUD_SD: out std_logic
    );
end synth_top;

architecture dataflow of synth_top is
    constant sampling_frequency: positive := 48_000;
    constant sample_bits: positive := 11;
    constant mixer_output_bits: positive := sample_bits + 1;

    constant phase_bits: positive := 32;

    package mtp is new work.midi_to_phase_generic
    generic map(
        phase_update_frequency => 100_000_000,
        phase_bits => phase_bits,
        rom_filename => "note_phase_table.txt"
    );

    signal midi_in: work.midi.midi_message;
    -- high when a new midi message is available
    signal new_midi_available: std_logic;
    -- previous version of the signal, to generate read_midi_in
    signal new_midi_available_prev: std_logic := '0';
    -- high for one clock when a new midi message is available
    -- this will advance the scheduler fsm
    -- TODO: this is basically a 1-element queue
    -- and should be refactored to be used throughout the code
    signal read_midi_in: std_logic;

    signal active_notes: std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0);

    signal sample_ready_vec: std_logic_vector(active_notes'range) := (others => '1');
    signal sample_vec: std_logic_vector((MAX_MIDI_NOTE_NUMBER+1)*sample_bits-1 downto 0) := (others => '0');

    signal compute_mixer_output: std_logic;
    signal mixer_output_1, mixer_output_2, mixer_output_3, mixer_output: std_logic_vector(mixer_output_bits-1 downto 0);
begin
    AUD_SD <= '1';

    uart_midi_link: entity work.uart_midi_link
    port map(
        clock => CLK100MHZ,
        RX => UART_TXD_IN,

        output_enable => new_midi_available,
        output_message => midi_in
    );

    active_notes_lut: entity work.active_notes_lut
    generic map(
        phase_bits => phase_bits
    )
    port map(
        clock => CLK100MHZ,
        input_enable => read_midi_in,
        midi_in => midi_in,
        o_active_notes_reg => active_notes
    );

    sound_blocks:
    for i in 0 to MAX_MIDI_NOTE_NUMBER generate
        signal ftw: std_logic_vector(phase_bits-1 downto 0);
    begin
        -- TODO: remove to_std_logic_vector
        ftw <= mtp.midi_note_to_phase_step(to_std_logic_vector(i, 7));

        generator: entity work.square_wave_generator
        generic map (
            update_frequency => 100_000_000,
            output_frequency => sampling_frequency,
            sample_bits => sample_bits,
            phase_bits => phase_bits
        )
        port map (
            i_clock => CLK100MHZ,
            i_rst => compute_mixer_output,
            i_ftw => ftw,
            o_sample_ready_reg => sample_ready_vec(i),
            o_sample_reg => sample_vec((i+1)*sample_bits-1 downto i*sample_bits)
        );
    end generate sound_blocks;

    compute_mixer_output <= and sample_ready_vec;

    -- three parallell mixers
    -- ranges:
    --  [0 .. 42] [43 .. 85] [86 .. 127]
    mixer_1: entity work.mixer
    generic map (
        sample_bits => sample_bits,
        output_bits => mixer_output_bits,
        number_of_inputs => 42
    )
    port map (
        i_clock => CLK100MHZ,

        i_active_notes => active_notes(127 downto 86),
        i_samples => sample_vec((127+1)*sample_bits-1 downto 86*sample_bits),
        i_generate_output_sample => compute_mixer_output,
        o_sample_reg => mixer_output_1
    );

    mixer_2: entity work.mixer
    generic map (
        sample_bits => sample_bits,
        output_bits => mixer_output_bits,
        number_of_inputs => 43
    )
    port map (
        i_clock => CLK100MHZ,

        i_active_notes => active_notes(85 downto 43),
        i_samples => sample_vec((85+1)*sample_bits-1 downto 43*sample_bits),
        i_generate_output_sample => compute_mixer_output,
        o_sample_reg => mixer_output_2
    );

    mixer_3: entity work.mixer
    generic map (
        sample_bits => sample_bits,
        output_bits => mixer_output_bits,
        number_of_inputs => 43
    )
    port map (
        i_clock => CLK100MHZ,

        i_active_notes => active_notes(42 downto 0),
        i_samples => sample_vec((42+1)*sample_bits-1 downto 0*sample_bits),
        i_generate_output_sample => compute_mixer_output,
        o_sample_reg => mixer_output_3
    );

    mixer_output <= mixer_output_1 + mixer_output_2 + mixer_output_3;

    pwm_generator: entity work.pwm_encoder
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        i_clk => CLK100MHZ,
        i_sample => mixer_output(mixer_output_1'high downto 1),
        o_pwm_signal => AUD_PWM
    );

    -- TODO: exactly the same as generate_midi_read_enable process
    -- should be refactored using queues instead
    generate_read_midi_in: process (CLK100MHZ, new_midi_available, new_midi_available_prev)
    begin
        if rising_edge(CLK100MHZ) then
            if new_midi_available = '1' and new_midi_available_prev = '0' then
                read_midi_in <= '1';
            else
                read_midi_in <= '0';
            end if;
            new_midi_available_prev <= new_midi_available;
        end if;
    end process generate_read_midi_in;
end dataflow;
