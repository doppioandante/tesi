library ieee;
use ieee.std_logic_1164.all;
use work.midi.all;
use work.midi_decoder;

entity midi_decoder_tb is
end midi_decoder_tb;

architecture testbench of midi_decoder_tb is
    constant clock_period: time := 10 ns;
    signal clock: std_logic;

    signal read_enable: std_logic := '0';
    signal data_in: std_logic_vector(7 downto 0) := (others => '0');
begin
    clock_process: process
    begin
        clock <= '0';
        wait for clock_period;
        loop
            clock <= not clock;
            wait for clock_period/2;
        end loop;
    end process clock_process;

    uut: entity midi_decoder
    port map (
        i_clock => clock,
        i_enable => read_enable,
        i_data => data_in,
        o_message_available => open,
        o_message => open
    );

    test_process: process
    begin
        wait for 3 * clock_period;
        data_in <= 8X"90";
        read_enable <= '1';
        wait for clock_period;
        read_enable <= '0';
        wait for 4 * clock_period;

        -- note
        data_in <= 8X"3C"; -- middle C
        read_enable <= '1';
        wait for clock_period;
        read_enable <= '0';
        wait for 4 * clock_period;

        -- velocity
        data_in <= 8X"50";
        read_enable <= '1';
        wait for clock_period;
        read_enable <= '0';
        wait for 4 * clock_period;

        std.env.stop;
    end process test_process;
end testbench;
