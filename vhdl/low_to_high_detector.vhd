library ieee;
use ieee.std_logic_1164.all;

entity low_to_high_detector is
    port(
        i_clock: in std_logic;
        i_signal: in std_logic;

        -- high for one clock when a 0 -> 1 transition is detected on i_signal
        o_detected: out std_logic
    );
end low_to_high_detector;

architecture behavioural of low_to_high_detector is
    signal signal_prev: std_logic := '0';
begin
    process (i_clock, i_signal, signal_prev)
    begin
        if rising_edge(i_clock) then
            if i_signal = '1' and signal_prev = '0' then
                o_detected <= '1';
            else
                o_detected <= '0';
            end if;

            signal_prev <= i_signal;
        end if;
    end process;
end behavioural;
