-- pwm encoder
-- converts the input sample to PWM
-- where logic '1' is attained by driving the output at high impedance

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use work.counter_utils.all;

entity pwm_encoder is
    generic (
        clock_frequency: positive := 100_000_000; -- in Hz
        input_sampling_frequency: positive;
        input_sample_bits: positive
    );
    port (
        i_clk: in std_logic;

        -- input sample to be converted to PWM
        i_sample: in std_logic_vector(input_sample_bits-1 downto 0);

        -- pwm output
        o_pwm_signal: out std_logic := 'Z'
    );
end pwm_encoder;

architecture behavioural of pwm_encoder is
    constant counter_limit: positive := clock_frequency/input_sampling_frequency;
    constant counter_bits: positive := get_counter_bits(clock_frequency, input_sampling_frequency);
    signal counter: std_logic_vector(counter_bits-1 downto 0);
begin
    -- assert output_pulse_frequency < input_sampling_frequency

    -- this assert may be to restrictive
    -- e.g. 10 possible sample values can be represented with 4 bits
    -- but 2**4 >= 10
    assert 2**input_sample_bits <= counter_limit
        report "PWM output may saturate under some values"
        severity warning;

    assert i_sample <= counter_limit
        report "PWM output saturated: " & integer'image(to_integer(unsigned(i_sample))) & " > " & positive'image(counter_limit)
        severity error;

    counter_inst: entity work.counter_impulse_generator
    generic map(
        clock_frequency => clock_frequency,
        impulse_frequency => input_sampling_frequency
    )
    port map(
        i_clk => i_clk,
        o_counter => counter,
        o_signal => open
    );

    o_pwm_signal <= 'Z' when counter < i_sample else '0';
end behavioural;
