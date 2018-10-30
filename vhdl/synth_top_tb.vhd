library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity synth_top_tb is
end synth_top_tb;

architecture testbench of synth_top_tb is
    constant clock_period: time := 10 ns;

    signal clock: std_logic;
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
        AUD_PWM => pwm_out,
        AUD_SD => open
    );

    test_process: process
    begin
        -- just wait for synth_top to end
        wait for 4 ms;
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
