library ieee;
use ieee.std_logic_1164.all;
use work.midi.MAX_MIDI_NOTE_NUMBER;

entity active_notes_lut_tb is
end active_notes_lut_tb;

architecture testbench of active_notes_lut_tb is
    constant clock_period: time := 10 ns;
    constant phase_bits: positive := 32;

    signal clock: std_logic;
    signal input_enable: std_logic;
    signal midi_in: work.midi.midi_message;

    signal active_notes: std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0);
begin
    clock_process: entity work.tb_clock_process
    generic map(
        period => clock_period
    )
    port map(
        clock => clock
    );

    uut: entity work.active_notes_lut
    port map(
        clock => clock,
        midi_in => midi_in,
        input_enable => input_enable,
        o_active_notes_reg => active_notes
    );

    test_process: process
    begin
        wait for clock_period;
        midi_in <= (
            msg_type => work.midi.note_on,
            channel  => 4x"0",
            data_1   => 7d"69", -- A4
            data_2   => 7d"100" -- velocity
        );
        input_enable <= '1';
        wait for clock_period;
        input_enable <= '0';

        wait for clock_period * 5;

        midi_in <= (
            msg_type => work.midi.note_on,
            channel  => 4x"0",
            data_1   => 7d"81", -- A5
            data_2   => 7d"123" -- velocity
        );
        input_enable <= '1';
        wait for clock_period;
        input_enable <= '0';

        wait for clock_period * 5;

        -- now switch off
        midi_in <= (
            msg_type => work.midi.note_off,
            channel  => 4x"0",
            data_1   => 7d"81", -- A5
            data_2   => 7d"100" -- velocity
        );
        input_enable <= '1';
        wait for clock_period;
        input_enable <= '0';

        wait for clock_period * 5;
        std.env.stop;
    end process;
end testbench;
