library ieee;
use ieee.std_logic_1164.all;
use work.midi.all;

entity uart_midi_link is
    port(
        clock: in std_logic;

        -- UART input
        RX: in std_logic;

        -- high when a processed midi message is available
        output_enable: out std_logic;
        output_message: out midi_message
    );
end uart_midi_link;

architecture behavioural of uart_midi_link is
    signal decoder_in: std_logic_vector(7 downto 0);
    signal midi_read_enable: std_logic := '0';
    signal uart_data_available: std_logic := '0';

    -- stateful
    signal uart_data_available_prev: std_logic := '0';
begin
    uart_inst: entity work.uart
    port map (
        i_clock => clock,
        i_serial_input => RX,
        o_data => decoder_in,
        o_data_available => uart_data_available
    );

    decoder_inst: entity work.midi_decoder
    port map (
        clock => clock,
        read_enable => midi_read_enable,
        data_in => decoder_in,
        data_available => output_enable,
        data_out => output_message
    );

    generate_midi_read_enable: process (clock, uart_data_available_prev, uart_data_available)
    begin
        if rising_edge(clock) then
            if uart_data_available = '1' and uart_data_available_prev = '0' then
                midi_read_enable <= '1';
            else
                midi_read_enable <= '0';
            end if;

            uart_data_available_prev <= uart_data_available;
        end if;
    end process generate_midi_read_enable;
end behavioural;

