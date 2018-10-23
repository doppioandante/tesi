-- generic UART receiver
-- assumes no parity bit in the received data

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity uart is
    generic (
        clock_frequency: positive := 100_000_000; -- in Hz
        bit_frequency: positive := 31250; -- in Hz
        bits_per_symbol: positive := 8
    );
    port (
        clock: in std_logic;
        -- receiving data line
        RX: in std_logic;
        -- data out when a symbol is completely received
        -- the first received bit will be the LSB
        data_out: out std_logic_vector(bits_per_symbol-1 downto 0);
        -- signals availability of data_out, either '1' or '0'
        -- there's no guarantee that data_out will remaing valid
        -- when data_available goes back to zero
        data_available: out std_logic
    );
end uart;

architecture behavioural of uart is
    constant counter_limit: positive := clock_frequency/bit_frequency;
    constant half_counter_limit: positive := counter_limit/2;
    constant counter_bits: positive := positive(ceil(log2(real(clock_frequency/bit_frequency))));
    constant bit_counter_size: positive := positive(ceil(log2(real(bits_per_symbol))));

    -- clock counter
    signal counter, next_counter: std_logic_vector(counter_bits-1 downto 0) := (others => '0');
    -- partially read symbol
    signal symbol, next_symbol: std_logic_vector(bits_per_symbol-1 downto 0) := (others => '0');
    -- bit counter, up to bits_per_symbol
    signal bit_counter, next_bit_counter: std_logic_vector(bit_counter_size-1 downto 0) := (others => '0');

    type state_type is (idle, read_first_bit, read_bit, read_stop);
    signal state, next_state: state_type;
begin
    data_out <= symbol;

    -- TODO: add reset
    sync_process: process (clock, next_state, next_counter, next_symbol, next_bit_counter)
    begin
        if rising_edge(clock) then
            state <= next_state;
            counter <= next_counter;
            symbol <= next_symbol;
            bit_counter <= next_bit_counter;
        end if;
    end process sync_process;

    fsm_process: process(state, RX, counter, bit_counter, symbol)
    begin
        data_available <= '0';
        next_symbol <= symbol;
        next_bit_counter <= bit_counter;

        case state is
            when idle =>
                if counter = half_counter_limit then
                    if RX = '0' then
                        next_state <= read_first_bit;
                    else 
                        next_state <= idle;
                    end if;
                    next_counter <= (others => '0');
                else
                    next_state <= idle;
                    next_counter <= counter + 1;
                end if;

            when read_first_bit =>
                if counter = counter_limit then
                    next_symbol <= RX & symbol(symbol'high downto 1);
                    next_counter <= (others => '0');
                    next_state <= read_bit;
                else
                    next_counter <= counter + 1;
                    next_state <= read_first_bit;
                end if;

            when read_bit =>
                if counter = counter_limit then
                    next_symbol <= RX & symbol(symbol'high downto 1);
                    next_bit_counter <= bit_counter + 1;
                    next_counter <= (others => '0');
                else
                    next_counter <= counter + 1;
                end if;
                if bit_counter = bits_per_symbol - 1 then
                    next_state <= read_stop;
                    next_bit_counter <= (others => '0');
                else
                    next_state <= read_bit;
                end if;

            when read_stop =>
                data_available <= '1';
                if counter = counter_limit then
                    next_counter <= (others => '0');
                    next_state <= idle;
                else
                    next_counter <= counter + 1;
                    next_state <= read_stop;
                end if;
        end case;
    end process fsm_process;

end behavioural;