library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity pwm_encoder_tb is
end pwm_encoder_tb;

architecture testbench of pwm_encoder_tb is
    constant clock_period: time := 10 ns;
    -- 10 MHz sampling frequency (100ns sampling period)
    -- such an high sampling rate will allow only 10 datapoints
    constant sampling_frequency: positive := 10_000_000;
    constant sample_bits: positive := 4;
    signal clock: std_logic;

    signal sample: std_logic_vector(sample_bits-1 downto 0);

    signal pwm_out: std_logic;

    signal stop_write: boolean := false;
begin
    clock_proc: entity work.tb_clock_process generic map (clock_period)
    port map(
        clock => clock
    );

    uut: entity work.pwm_encoder
    generic map (
        input_sampling_frequency => sampling_frequency,
        input_sample_bits => sample_bits
    )
    port map (
        i_clk => clock,
        i_sample => sample,
        o_pwm_signal => pwm_out
    );

    test_process: process
    begin
        sample <= 4b"1010";
        wait for clock_period * 50;
        sample <= 4b"0010";
        wait for clock_period * 50;
        sample <= 4b"0000";
        wait for clock_period * 50;

        stop_write <= true;
    end process test_process;

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
