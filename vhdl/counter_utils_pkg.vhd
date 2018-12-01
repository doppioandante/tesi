library ieee;
use ieee.math_real.log2;
use ieee.math_real.ceil;

package counter_utils is
    function get_counter_bits(clock_frequency: positive; reset_frequency: positive)
        return positive;
end package counter_utils;

package body counter_utils is
    function get_counter_bits(clock_frequency: positive; reset_frequency: positive) return positive is
    begin
        return positive(ceil(log2(real(clock_frequency/reset_frequency))));
    end function get_counter_bits;
end package body counter_utils;
