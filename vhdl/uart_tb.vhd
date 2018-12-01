library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use work.tb_uart.all;

entity uart_tb is
end uart_tb;

architecture testbench of uart_tb is
    constant clock_period: time := 10 ns;
    signal clock: std_logic;

    constant bit_period: time := 32 us;

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

    uut: entity work.uart
    port map (
        i_clock => clock,
        i_serial_input => TX,
        o_data => open,
        o_data_available  => open
    );

    test_process: process
    begin
        TX <= '1';
        wait for 1.3 * bit_period;
        send_byte("10101010", TX, bit_period);
        wait for 0.7 * bit_period;
        send_byte("11110000", TX, bit_period);
        wait for bit_period;
        send_byte(8x"90", TX, bit_period);

        std.env.stop;
    end process test_process;
end testbench;
