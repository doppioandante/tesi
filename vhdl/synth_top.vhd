library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity synth_top is
    port(
        CLK100MHZ: in std_logic;

        AUD_PWM: out std_logic;
        AUD_SD: out std_logic
    );
end synth_top;

architecture dataflow of synth_top is
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

    constant note_number: std_logic_vector(6 downto 0) := 7d"69";

    constant step_phase: midi_to_phase.phase_type := midi_to_phase.midi_note_to_phase_step(note_number);

    signal sample_ready: std_logic;
    signal sample: std_logic_vector(sample_bits-1 downto 0);
    signal sample_hold: std_logic_vector(sample_bits-1 downto 0) := (others => '0');

    signal sound_enable: std_logic := '0';
begin
    AUD_SD <= '1';

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
        phase_input_enable => '1',
        phase_step => step_phase,
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
        input_enable => '1',
        sample => sample_hold,
        pwm_out => AUD_PWM
    );

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
