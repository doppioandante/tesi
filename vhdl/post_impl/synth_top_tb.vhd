library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity synth_top_tb is
end synth_top_tb;

architecture testbench of synth_top_tb is
    constant clock_period: time := 10 ns;
    constant bit_period: time := 32 us; -- in Hz

    signal clock: std_logic;
    signal uart_in: std_logic;
    signal pwm_out: std_logic;
    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    uut: entity work.synth_top
    port map(
        CLK100MHZ => clock,
        UART_TXD_IN => uart_in,
        AUD_PWM => pwm_out,
        AUD_SD => open
    );

    test_process: process
        -- TODO: factor out from uart_midi_link_tb
        procedure send_byte(byte: in std_logic_vector(7 downto 0)) is
        begin
            uart_in <= '0';
            wait for bit_period;
            for i in byte'reverse_range loop
                uart_in <= byte(i);
                wait for bit_period;
            end loop;
            uart_in <= '1';
            wait for bit_period;
        end;
    begin
        uart_in <= '1';

        send_byte(8x"90"); -- note on
        send_byte(8d"69"); -- A 440Hz
        send_byte(8x"50");

        send_byte(8x"90"); -- note on
        send_byte(8d"73");
        send_byte(8x"50");

        wait for 3 ms;
 
        send_byte(8x"80"); -- note off
        send_byte(8d"69"); -- A 440Hz
        send_byte(8x"50");
 
        wait for 100 us;

        stop_write <= true;
    end process;

    write_process: process
        file output_file: text;
        variable pwm_line: line;
    begin
        file_open(output_file, "pwm_out.txt", write_mode);
        -- write out pwm sampling frequency
        write(pwm_line, positive'image(100_000_000), left, 32);
        writeline(output_file, pwm_line);
        wait until rising_edge(clock);
        while not stop_write loop
            write(pwm_line, pwm_out, right, 1);
            writeline(output_file, pwm_line);
            wait for clock_period;
        end loop;

        file_close(output_file);
        std.env.stop;
    end process write_process;
end testbench;
