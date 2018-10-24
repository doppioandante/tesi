library ieee;
use ieee.std_logic_1164.all;

entity uart_midi_link_tb is
end uart_midi_link_tb;

architecture testbench of uart_midi_link_tb is
    constant clock_period: time := 10 ns;
    signal clock: std_logic;

    constant bit_period: time := 32 us; -- in Hz

    signal TX: std_logic;
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

    uut: entity work.uart_midi_link
    port map (
        clock => clock,
        RX => TX,
        output_enable => open,
        output_message => open
    );

    test_process: process
        procedure send_byte(byte: in std_logic_vector(7 downto 0)) is
        begin
            TX <= '0';
            wait for bit_period;
            for i in byte'reverse_range loop
                TX <= byte(i);
                wait for bit_period;
            end loop;
            TX <= '1';
            wait for bit_period;
        end;

    begin
        TX <= '1';
        wait for 1.20 * bit_period;

        send_byte(8x"90");
        send_byte(8x"3C");
        send_byte(8x"50");

        wait for bit_period;

        std.env.stop;
    end process test_process;
end testbench;