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

    signal uart_data_available: std_logic := '0';
    signal uart_data: std_logic_vector(7 downto 0) := (others => '0');
    signal read_uart_in: std_logic := '0';

    signal midi_in: work.midi.midi_message;
    signal midi_msg_available: std_logic := '0';
    signal read_midi_in: std_logic := '0';

    signal active_notes: std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0);

    signal update_output: std_logic := '0';
    signal output_sample: signed(sample_bits-1 downto 0);
    signal pwm_input: std_logic_vector(sample_bits-1 downto 0) := (0 => '0', others => '1');
begin
    AUD_SD <= '1';

    uart_inst: entity work.uart
    generic map(
        clock_frequency => clock_frequency
    )
    port map (
        i_clock => CLK100MHZ,
        i_serial_input => UART_TXD_IN,
        o_data => uart_data,
        o_data_available => uart_data_available
    );

    uart_to_decoder_semaphore: entity work.low_to_high_detector
    port map(
        i_clock => CLK100MHZ,
        i_signal => uart_data_available,
        o_detected => read_uart_in
    );

    decoder_inst: entity work.midi_decoder
    port map (
        i_clock => CLK100MHZ,
        i_enable => read_uart_in,
        i_data => uart_data,
        o_message_available => midi_msg_available,
        o_message => midi_in
    );

    decoder_to_active_notes_semaphore: entity work.low_to_high_detector
    port map(
        i_clock => CLK100MHZ,
        i_signal => midi_msg_available,
        o_detected => read_midi_in
    );

    active_notes_lut: entity work.active_notes_lut
    port map(
        i_clock => CLK100MHZ,
        i_enable => read_midi_in,
        i_message => midi_in,
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
end dataflow;
