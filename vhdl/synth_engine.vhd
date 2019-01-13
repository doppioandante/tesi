library ieee;
use ieee.std_logic_1164.all;
use work.midi.MAX_MIDI_NOTE_NUMBER;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.counter_utils.all;

entity synth_engine is
    generic(
        sample_bits: positive;
        phase_bits: positive;
        waveform_address_bits: positive;
        clock_frequency: positive;
        sampling_frequency: positive
    );
    port(
        i_clock: in std_logic;

        i_active_notes: std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0);

        o_sample_ready: out std_logic;
        o_sample: out signed(sample_bits-1 downto 0)
    );
end synth_engine;

architecture behavioural of synth_engine is
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
    signal phase_vec: phase_vec_type;

    signal scanning_counter: std_logic_vector(6 downto 0) := (others => '0');

    constant counter_limit: positive := clock_frequency/sampling_frequency;
    constant counter_bits: positive := get_counter_bits(clock_frequency, sampling_frequency);
    signal counter: std_logic_vector(counter_bits-1 downto 0);
    signal sample_value: signed(sample_bits-1 downto 0) := (others => '0');
    signal mixed_output: signed(sample_bits-1 downto 0) := (others => '0');
    signal load_sample: boolean := true;
begin
    -- instantiate the 128 indipendent NCOs
    -- and 128 synchronous reset blocks.
    -- Each reset is triggered for its corresponding NCO
    -- when a 0 -> 1 transition is met in the LUT
    oscillators:
    for i in 0 to MAX_MIDI_NOTE_NUMBER generate
        signal ftw: std_logic_vector(phase_bits-1 downto 0);
        signal reset_signal: std_logic := '0';
    begin
        ftw <= phase_rom.read_at(i);

        reset_generator: entity work.low_to_high_detector
        port map (
            i_clock => i_clock,
            i_signal => i_active_notes(i),
            o_detected => reset_signal
        );

        accumulator: entity work.phase_accumulator
        generic map (
            clock_frequency => clock_frequency,
            phase_bits => phase_bits
        )
        port map (
            i_clock => i_clock,
            i_rst_sync => reset_signal,
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
        i_clk => i_clock,
        o_counter => counter,
        o_signal => o_sample_ready
    );

    -- for each phase accumulator, lookup the corresponding sample
    -- and add it to the total mix
    -- also keep count of the number of active notes
    sampling_process:

    process (i_clock, counter, scanning_counter, i_active_notes, phase_vec, load_sample, sample_value, mixed_output)
        variable note_index: integer;
    begin
        if rising_edge(i_clock) then
            if unsigned(counter) >= counter_limit-1 - 2*(MAX_MIDI_NOTE_NUMBER-1)
                and o_sample_ready = '0'
            then
                if load_sample then
                    note_index := to_integer(scanning_counter);

                    if i_active_notes(note_index) = '1' then
                        -- use the upper bits of the phase accumulator to select
                        -- the corresponding sample in waveform memory
                        sample_value <= signed(waveform_rom.read_at(to_integer(
                            phase_vec(note_index)(phase_bits-1 downto phase_bits-waveform_address_bits)
                        )));
                    else
                        sample_value <= to_signed(0, sample_bits);
                    end if;
                    scanning_counter <= scanning_counter + 1;

                else -- perform the sum
                    mixed_output <= mixed_output + sample_value;
                end if;
                load_sample <= not load_sample;
            elsif o_sample_ready = '1' then
                scanning_counter <= (others => '0');
                mixed_output <= (others => '0');
                load_sample <= true;
            end if;
        end if;
    end process;

    o_sample <= mixed_output;
end behavioural;
