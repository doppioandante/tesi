library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity tb_logger is
    generic (
        filename: string;
        clock_frequency: positive
    );
    port (
        i_clock: in std_logic;
        i_pwm: in std_logic;
        i_stop: in boolean
    );
end tb_logger;

architecture behavioural of tb_logger is
begin
    write_process: process
        file output_file: text;
        variable pwm_line: line;
    begin
        file_open(output_file, filename, write_mode);
        -- write out pwm sampling frequency
        write(pwm_line, positive'image(clock_frequency), left, 32);
        writeline(output_file, pwm_line);
        while not i_stop loop
            wait until rising_edge(i_clock);
            if i_pwm = 'Z' then
                write(pwm_line, 1, right, 1);
            else
                write(pwm_line, 0, right, 1);
            end if;
            writeline(output_file, pwm_line);
        end loop;

        file_close(output_file);
        std.env.stop;
    end process write_process;
end behavioural;
