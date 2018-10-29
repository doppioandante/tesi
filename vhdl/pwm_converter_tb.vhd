library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity pwm_converter_tb is
end pwm_converter_tb;

architecture testbench of pwm_converter_tb is
    constant clock_period: time := 10 ns;
    -- 10 MHz sampling frequency (100ns sampling period)
    -- such an high sampling rate will allow only 10 datapoints
    constant sampling_frequency: positive := 10_000_000;
    constant sample_bits: positive := 4;
    signal clock: std_logic;

    signal input_enable: std_logic := '0';
    signal sample: std_logic_vector(sample_bits-1 downto 0);

    signal pwm_out: std_logic;

    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    uut: entity work.pwm_converter
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        clock => clock,
        input_enable => input_enable,
        sample => sample,
        pwm_out => pwm_out
    );

    test_process: process
    begin
        sample <= 4b"1010";
        input_enable <= '1';
        wait for clock_period * 50;
        input_enable <= '0';
        wait for clock_period * 50;
        sample <= 4b"0000";
        input_enable <= '1';
        wait for clock_period * 50;

        stop_write <= true;
    end process test_process;

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