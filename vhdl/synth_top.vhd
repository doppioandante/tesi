library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

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

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;

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

    signal update_tone_generator: std_logic;
    signal phase_step: std_logic_vector(phase_bits-1 downto 0);

    signal sample_ready: std_logic;
    signal sample: std_logic_vector(sample_bits-1 downto 0);
    signal sample_hold: std_logic_vector(sample_bits-1 downto 0) := (others => '0');

    signal sound_enable: std_logic := '1';
begin
    AUD_SD <= '1';

    uart_midi_link: entity work.uart_midi_link
    port map(
        clock => CLK100MHZ,
        RX => UART_TXD_IN,

        output_enable => new_midi_available,
        output_message => midi_in
    );

    sound_scheduler: entity work.sound_scheduler
    generic map(
        phase_bits => phase_bits
    )
    port map(
        clock => CLK100MHZ,
        input_enable => read_midi_in,
        midi_in => midi_in,
        update_tone_generator => update_tone_generator,
        output_phase_step => phase_step,
        sound_enable => sound_enable
    );

    sqr_generator: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        clock => CLK100MHZ,
        ce => sound_enable,
        phase_input_enable => update_tone_generator,
        phase_step => phase_step,
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
        input_enable => sound_enable,
        sample => sample_hold,
        pwm_out => AUD_PWM
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

    -- hold sample received from square wave for the pwm generator
    holder: process (CLK100MHZ, sample_ready, sample)
    begin
        if rising_edge(CLK100MHZ) then
            if sample_ready = '1' then
                sample_hold <= sample;
            end if;
        end if;
    end process holder;
end dataflow;
