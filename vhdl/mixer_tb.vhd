library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use work.midi.MAX_MIDI_NOTE_NUMBER;

entity mixer_tb is
end mixer_tb;

architecture testbench of mixer_tb is
    constant clock_period: time := 10 ns;
    constant sample_bits: positive := 4;
    signal clock: std_logic;

    signal generate_output: std_logic := '0';
    signal sample: std_logic_vector(sample_bits-1 downto 0);

    signal input_samples: std_logic_vector(sample_bits*(MAX_MIDI_NOTE_NUMBER+1)-1 downto 0)
        := (others => '0');
    signal active_notes: std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0) := (others => '0');
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    uut: entity work.mixer
    generic map (
        sample_bits => sample_bits
    )
    port map (
        i_clock => clock,

        i_active_notes => active_notes,
        i_samples => input_samples,
        i_generate_output_sample => generate_output,
        o_sample_reg => sample
    );

    test_process: process
    begin
        wait for clock_period;
        active_notes(2) <= '1';
        input_samples(3*sample_bits-1 downto 2*sample_bits) <= "0100";
        active_notes(5) <= '1';
        input_samples(6*sample_bits-1 downto 5*sample_bits) <= "0010";
        generate_output <= '1';
        wait for clock_period * 2;
        generate_output <= '0';
        wait for clock_period * 2;

        std.env.stop;
    end process test_process;
end testbench;
