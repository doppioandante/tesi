library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use work.midi.MAX_MIDI_NOTE_NUMBER;
use work.counter_utils.all;

entity synth_top is
    port(
        CLK100MHZ: in std_logic;

        UART_TXD_IN: in std_logic;

        AUD_PWM: out std_logic;
        AUD_SD: out std_logic
    );
end synth_top;

architecture dataflow of synth_top is
    constant clock_frequency: positive := 100_000_000;
    constant sampling_frequency: positive := 48_000;
    constant sample_bits: positive := 11;
    -- 128 inputs of sample_bits are mixed
    -- thus the maximum possible value should be stored
    -- in sample_bits + log2(128) bits, although this is crazy
    constant mixer_output_bits: positive := sample_bits + 1;

    constant phase_bits: positive := 32;
    -- bits used to address the waveform rom
    constant waveform_address_bits: positive := 13;

    package phase_rom is new work.rom
    generic map(
        word_bits => phase_bits,
        address_bits => 7,
        rom_filename => "note_phase_table.txt"
    );

    package waveform_rom is new work.rom
    generic map(
        word_bits => sample_bits,
        address_bits => waveform_address_bits,
        rom_filename => "waveform_rom.txt"
    );

    subtype phase_type is std_logic_vector(phase_bits-1 downto 0);
    type phase_vec_type is array (0 to MAX_MIDI_NOTE_NUMBER) of phase_type;

    constant counter_limit: positive := clock_frequency/sampling_frequency;
    constant counter_bits: positive := get_counter_bits(clock_frequency, sampling_frequency);
    signal counter: std_logic_vector(counter_bits-1 downto 0);

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

    signal phase_vec: phase_vec_type;

    signal scanning_counter: std_logic_vector(6 downto 0) := (others => '0');

    signal update_output: std_logic := '0';
    signal mixed_output: signed(mixer_output_bits-1 downto 0) := (others => '0');
    signal pwm_input: std_logic_vector(sample_bits-1 downto 0) := (0 => '0', others => '1');
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

    -- instantiate the 128 indipendent NCOs
    oscillators:
    for i in 0 to MAX_MIDI_NOTE_NUMBER generate
        signal ftw: std_logic_vector(phase_bits-1 downto 0);
    begin
        ftw <= phase_rom.read_at(i);

        accumulator: entity work.phase_accumulator
        generic map (
            clock_frequency => clock_frequency,
            phase_bits => phase_bits
        )
        port map (
            i_clock => CLK100MHZ,
            i_rst_sync => '0',
            i_ftw => ftw,
            o_phase_reg => phase_vec(i)
        );
    end generate oscillators;

    -- this will generate an active high signal each time
    -- a new sample should be ready for output
    -- the counter is also exposed
    counter_inst: entity work.counter_impulse_generator
    generic map(
        clock_frequency => clock_frequency,
        impulse_frequency => sampling_frequency
    )
    port map(
        i_clk => CLK100MHZ,
        o_counter => counter,
        o_signal => update_output
    );

    -- for each phase accumulator, lookup the corresponding sample
    -- and add it to the total mix
    -- also keep count of the number of active notes
    sampling_process:
    process (CLK100MHZ, counter, scanning_counter, active_notes, phase_vec, mixed_output)
        variable sample_value: signed(sample_bits-1 downto 0);
        variable a: std_logic_vector(sample_bits-1 downto 0);
        variable note_index: integer;
    begin
        if rising_edge(CLK100MHZ) then
            if unsigned(counter) >= counter_limit - 2 - MAX_MIDI_NOTE_NUMBER
               and update_output = '0'
            then
                note_index := to_integer(scanning_counter);

                if active_notes(note_index) = '1' then
                    -- use the upper bits of the phase accumulator to select
                    -- the corresponding sample in waveform memory
                    sample_value := signed(waveform_rom.read_at(to_integer(
                        phase_vec(note_index)(phase_bits-1 downto phase_bits-waveform_address_bits)
                    )));
                else
                    sample_value := to_signed(0, sample_bits);
                end if;
                mixed_output <= mixed_output + sample_value;

                scanning_counter <= scanning_counter + 1;
            else
                scanning_counter <= (others => '0');
                mixed_output <= (others => '0');
            end if;
        end if;
    end process;

    update_output_process:
    process (all)
        constant pwm_zero: signed(sample_bits-1 downto 0) := ('1', others => '0');
    begin
        if rising_edge(CLK100MHZ) and update_output = '1' then
            pwm_input <= std_logic_vector(mixed_output(sample_bits downto 1) + pwm_zero);
        end if;
    end process update_output_process;

    pwm_generator: entity work.pwm_encoder
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        i_clk => CLK100MHZ,
        i_sample => pwm_input,
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
