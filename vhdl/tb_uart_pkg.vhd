library ieee;
use ieee.std_logic_1164.all;

package tb_uart is
    procedure send_byte(byte: in std_logic_vector(7 downto 0); signal tx: out std_logic; constant bit_period: in time);
end package tb_uart;

package body tb_uart is
    procedure send_byte(byte: in std_logic_vector(7 downto 0); signal tx: out std_logic; constant bit_period: in time) is
    begin
        tx <= '0';
        wait for bit_period;
        for i in byte'reverse_range loop
            tx <= byte(i);
            wait for bit_period;
        end loop;
        tx <= '1';
        wait for bit_period;
    end;
end package body tb_uart;
