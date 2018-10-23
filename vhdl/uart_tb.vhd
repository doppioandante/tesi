library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity uart_tb is
end uart_tb;

architecture testbench of uart_tb is
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

    uut: entity work.uart
    port map (
        clock => clock,
        RX => TX,
        data_out => open,
        data_available => open
    );

    test_process: process
    begin
        TX <= '1';
        wait for 1.20 * bit_period;
        TX <= '0'; -- start bit
        wait for bit_period;
        for i in 0 to 3 loop
            TX <= '1';
            wait for bit_period;
            TX <= '0';
            wait for bit_period;
        end loop;
        TX <= '1'; -- stop bit
        wait for bit_period;

        wait for 0.7 * bit_period;

        TX <= '0'; -- start bit
        wait for bit_period;
        for i in 0 to 3 loop
            TX <= '1';
            wait for bit_period;
        end loop;
        for i in 0 to 3 loop
            TX <= '0';
            wait for bit_period;
        end loop;
        TX <= '1'; -- stop bit
        wait for bit_period;

        wait for bit_period;

        std.env.stop;
    end process test_process;
end testbench;