library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity mono_synth_engine_tb is
end mono_synth_engine_tb;

architecture testbench of mono_synth_engine_tb is
    constant clock_period: time := 10 ns;
    constant clock_frequency: positive := 100_000_000;
    constant sampling_frequency: positive := 48_000;
    constant sample_bits: positive := 11;
    constant phase_bits: positive := 32;
    constant waveform_address_bits: positive := 13;    

    constant pwm_zero: signed(sample_bits-1 downto 0) := ('1', others => '0');

    constant note_number: integer := 69;
    signal active_notes: std_logic_vector(127 downto 0) :=
        (note_number => '1', others => '0');

    signal clock: std_logic;

    signal update_output: std_logic := '0';
    signal sample: signed(sample_bits-1 downto 0) := (others => '0');

    signal pwm_input: std_logic_vector(sample_bits-1 downto 0) := std_logic_vector(pwm_zero);
    signal pwm_out: std_logic;

    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    synth_engine: entity work.synth_engine
    generic map(
        clock_frequency => clock_frequency,
        sampling_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits,
        waveform_address_bits => waveform_address_bits
    )
    port map(
        i_clock => clock,
        i_active_notes => active_notes,
        o_sample => sample,
        o_sample_ready => update_output
    );

    update_output_process:
    process (all)
    begin
        if rising_edge(clock) and update_output = '1' then
            pwm_input <= std_logic_vector(sample + pwm_zero);
        end if;
    end process update_output_process;

    pwm_generator: entity work.pwm_encoder
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        i_clk => clock,
        i_sample => pwm_input,
        o_pwm_signal => pwm_out
    );

    test_process: process
    begin
        wait for 20 ms;

        stop_write <= true;
    end process test_process;

    logger: entity work.tb_logger
    generic map(
        clock_frequency => clock_frequency,
        filename => "pwm_out.txt"
    )
    port map(
        i_clock => clock,
        i_pwm => pwm_out,
        i_stop => stop_write
    );
end testbench;
