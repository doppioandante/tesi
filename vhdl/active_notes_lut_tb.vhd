library ieee;
use ieee.std_logic_1164.all;

entity sound_scheduler_tb is
end sound_scheduler_tb;

architecture testbench of sound_scheduler_tb is
    constant clock_period: time := 10 ns;
    constant phase_bits: positive := 32;

    signal clock: std_logic;
    signal input_enable: std_logic;
    signal midi_in: work.midi.midi_message;
begin
    clock_process: entity work.tb_clock_process
    generic map(
        period => clock_period
    )
    port map(
        clock => clock
    );
    
    uut: entity work.sound_scheduler
    generic map(
        phase_bits => phase_bits
    )
    port map(
        clock => clock,
        midi_in => midi_in,
        input_enable => input_enable,
        update_tone_generator => open,
        output_phase_step => open,
        sound_enable => open
    );
    
    test_process: process
    begin
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
