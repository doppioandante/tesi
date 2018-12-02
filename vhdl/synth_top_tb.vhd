library ieee;
use ieee.std_logic_1164.all;
use work.tb_uart.all;

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
    begin
        uart_in <= '1';

        send_byte(8x"90", uart_in, bit_period); -- note on
        send_byte(8d"69", uart_in, bit_period); -- A 440Hz
        send_byte(8x"50", uart_in, bit_period);

        send_byte(8x"90", uart_in, bit_period); -- note on
        send_byte(8d"73", uart_in, bit_period);
        send_byte(8x"50", uart_in, bit_period);

        wait for 3 ms;
 
        send_byte(8x"80", uart_in, bit_period); -- note off
        send_byte(8d"69", uart_in, bit_period); -- A 440Hz
        send_byte(8x"50", uart_in, bit_period);
 
        wait for 100 us;

        stop_write <= true;
    end process;

    logger: entity work.tb_logger
    generic map(
        clock_frequency => 100_000_000,
        filename => "pwm_out.txt"
    )
    port map(
        i_clock => clock,
        i_pwm => pwm_out,
        i_stop => stop_write
    );
end testbench;
