-- generic UART receiver
-- assumes no parity bit in the received data

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use work.counter_utils.all;

entity uart is
    generic (
        clock_frequency: positive := 100_000_000; -- in Hz
        bit_frequency: positive := 31250; -- in Hz
        bits_per_symbol: positive := 8
    );
    port (
        i_clock: in std_logic;
        -- receiving data line
        i_serial_input: in std_logic;
        -- data out when a symbol is completely received
        -- the first received bit will be the LSB
        o_data: out std_logic_vector(bits_per_symbol-1 downto 0);
        -- signals availability of data_out, either '1' or '0'
        o_data_available: out std_logic
    );
end uart;

architecture behavioural of uart is
    constant counter_limit: positive := clock_frequency/bit_frequency;
    constant half_counter_limit: positive := counter_limit/2;
    constant counter_bits: positive := get_counter_bits(clock_frequency, bit_frequency);

    signal reset_counter: std_logic := '0';
    signal counter: std_logic_vector(counter_bits-1 downto 0);
    signal read_serial_input: std_logic := '0';
    -- shift register containing the decoded input
    -- one high bit is used as a sentinel and will be present
    -- at the '0' position when reading has been completed
    signal symbol: std_logic_vector(bits_per_symbol downto 0) := (others => '0');

    type state_type is (idle, read_bit);
    signal state: state_type := idle;
begin
    o_data <= symbol(symbol'high downto 1);
    o_data_available <= symbol(0); -- when the sentinel reaches the end, new data is available

    impulse_generator: entity work.counter_impulse_generator
    generic map(
        clock_frequency => clock_frequency,
        impulse_frequency => bit_frequency
    )
    port map(
        i_clk => i_clock,
        i_rst => reset_counter,
        o_counter => counter,
        o_signal => read_serial_input
    );

    -- TODO: add reset
    sync_process: process (i_clock, state, symbol, i_serial_input, read_serial_input, counter)
    begin
        if rising_edge(i_clock) then
            case state is
                when idle =>
                    if counter = counter_limit/2 and i_serial_input = '0' then
                        state <= read_bit;
                        symbol <= (others => '0');
                        symbol(bits_per_symbol) <= '1';
                    end if;

                when read_bit =>
                    if read_serial_input then
                        if symbol(0) = '1' then
                            state <= idle;
                        else
                            symbol <= i_serial_input & symbol(symbol'high downto 1);
                        end if;
                    end if;
            end case;
        end if;
    end process sync_process;

    -- asynchronus output process for resetting the internal counter
    reset_process: process(state, counter, i_serial_input)
    begin
        if state = idle and counter = counter_limit/2 and i_serial_input = '0' then
            reset_counter <= '1';
        else
            reset_counter <= '0';
        end if;
    end process reset_process;

end behavioural;
