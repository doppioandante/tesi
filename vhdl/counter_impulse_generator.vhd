-- counter based impulse generator
-- exposes the internal counter and generate an active output signal
-- for one clock cycle at the desired frequency

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use work.counter_utils.all;

entity counter_impulse_generator is
    generic (
        clock_frequency: positive;
        impulse_frequency: positive;

        counter_limit: positive := clock_frequency/impulse_frequency;
        counter_bits: positive := get_counter_bits(clock_frequency, impulse_frequency)
    );
    port (
        i_clk: in std_logic;
        o_signal: out std_logic;

        o_counter: out std_logic_vector(counter_bits-1 downto 0) := (others => '0')
    );
end counter_impulse_generator;

architecture behavioural of counter_impulse_generator is
begin
    process (i_clk, o_counter)
    begin
        if rising_edge(i_clk) then
            if o_counter = counter_limit - 1 then
                o_counter <= (others => '0');
            else
                o_counter <= o_counter + 1;
            end if;
        end if;
    end process;
end behavioural;
