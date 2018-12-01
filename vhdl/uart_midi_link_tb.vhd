library ieee;
use ieee.std_logic_1164.all;
use work.tb_uart.all;

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
    begin
        TX <= '1';
        wait for 1.20 * bit_period;

        send_byte(8x"90", TX, bit_period);
        send_byte(8x"3C", TX, bit_period);
        send_byte(8x"50", TX, bit_period);

        wait for bit_period;

        std.env.stop;
    end process test_process;
end testbench;
