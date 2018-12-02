library ieee;
use ieee.std_logic_1164.all;

entity tb_clock_process is
    generic (
        period: time
    );
    port (
        clock: out std_logic
    );
end tb_clock_process;

architecture behavioural of tb_clock_process is
begin
    clock_process: process
    begin
        clock <= '1';
        loop
            wait for period/2;
            clock <= not clock;
        end loop;
    end process clock_process;
end behavioural;
