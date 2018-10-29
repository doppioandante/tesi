library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity square_to_pwm_tb is
end square_to_pwm_tb;

architecture testbench of square_to_pwm_tb is
    constant clock_period: time := 10 ns;
    -- 10 MHz sampling frequency (100ns sampling period)
    -- such an high sampling rate will allow only 10 datapoints
    -- counter_bits will be 3
    constant sampling_frequency: positive := 48_000;
    constant sample_bits: positive := 11;

    constant wave_frequency: positive := 440;
    constant phase_bits: positive := 32;
    constant step_phase: positive := 18897; --positive(ceil(real(2**phase_bits) * real(wave_frequency)/real(100_000_000))); 

    signal clock: std_logic;

    signal sample_ready: std_logic;
    signal sample: std_logic_vector(sample_bits-1 downto 0);
    signal sample_hold: std_logic_vector(sample_bits-1 downto 0) := (others => '0');
    signal pwm_out: std_logic;

    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    sqr_generator: entity work.square_wave_generator
    generic map (
        update_frequency => 100_000_000,
        output_frequency => sampling_frequency,
        sample_bits => sample_bits,
        phase_bits => phase_bits
    )
    port map (
        clock => clock,
        phase_input_enable => '1',
        phase_step => to_std_logic_vector(step_phase, phase_bits),
        output_enable => sample_ready,
        output_sample => sample
    );

    pwm_generator: entity work.pwm_converter
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        clock => clock,
        input_enable => '1',
        sample => sample_hold,
        pwm_out => pwm_out
    );

    -- hold sample received from square wave for the pwm generator
    holder: process (clock, sample_ready, sample)
    begin
        if rising_edge(clock) then
            if sample_ready = '1' then
                sample_hold <= sample;
            end if;
        end if;
    end process holder;

    test_process: process
    begin
        wait for 8 ms;

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
        while not stop_write loop 
            write(pwm_line, pwm_out, right, 1);
            writeline(output_file, pwm_line);
            wait for clock_period;
        end loop;

        file_close(output_file);
        std.env.stop;
    end process write_process;
end testbench;