library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
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
    constant clock_frequency: positive := 100_000_000;
    constant sampling_frequency: positive := 48_000;
    constant sample_bits: positive := 11;

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

    signal update_output: std_logic := '0';
    signal output_sample: signed(sample_bits-1 downto 0);
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
    port map(
        clock => CLK100MHZ,
        input_enable => read_midi_in,
        midi_in => midi_in,
        o_active_notes_reg => active_notes
    );

    synth_engine: entity work.synth_engine
    generic map(
        clock_frequency => clock_frequency,
        sampling_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => 32,
        waveform_address_bits => 13
    )
    port map(
        i_clock => CLK100MHZ,
        i_active_notes => active_notes,
        o_sample => output_sample,
        o_sample_ready => update_output
    );

    update_output_process:
    process (all)
        constant pwm_zero: signed(sample_bits-1 downto 0) := ('1', others => '0');
    begin
        if rising_edge(CLK100MHZ) and update_output = '1' then
            pwm_input <= std_logic_vector(output_sample + pwm_zero);
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
