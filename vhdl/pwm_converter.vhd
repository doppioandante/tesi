-- pwm converter
-- converts the input sample to PWM
-- where logic '1' is attained by driving the output at high impedance
-- when no output is available, outputs a square wave (no sound)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity pwm_converter is
    generic (
        clock_frequency: positive := 100_000_000; -- in Hz
        --output_pulse_frequency: positive := clock_frequency; -- in Hz
        input_sampling_frequency: positive;
        input_sample_bits: positive
    );
    port (
        clock: in std_logic;

        -- a sample is available
        input_enable: in std_logic;
        -- input sample to be converted to PWM
        sample: in std_logic_vector(input_sample_bits-1 downto 0);

        -- pwm output
        pwm_out: out std_logic := 'Z'
    );
end pwm_converter;

architecture behavioural of pwm_converter is
    -- TODO: account for output_pulse_frequency
    constant counter_limit: positive := clock_frequency/input_sampling_frequency;
    constant counter_bits: positive := positive(ceil(log2(real(counter_limit))));

    signal counter: std_logic_vector(counter_bits-1 downto 0) := (others => '0');
begin
    -- assert output_pulse_frequency < input_sampling_frequency

    -- this assert may be to restrictive
    -- e.g. 10 possible sample values can be represented with 4 bits
    -- but 2**4 >= 10
    assert 2**input_sample_bits <= counter_limit
        report "PWM output may saturate under some values"
        severity warning;

    assert input_enable /= '1' or (input_enable = '1' and sample <= counter_limit)
        report "PWM output saturated: " & integer'image(to_integer(unsigned(sample))) & " > " & positive'image(counter_limit)
        severity error;

    process (counter, sample, input_enable)
    begin
        if (input_enable = '1' and counter <= sample)
            or (input_enable /= '1' and counter <= counter_limit/2) then
            pwm_out <= 'Z';
        else
            pwm_out <= '0';
        end if;
    end process;

    process (clock, counter)
    begin
        if rising_edge(clock) then
            if counter = counter_limit - 1 then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
end behavioural;