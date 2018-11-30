library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity square_wave_generator is
    generic(
        -- how often the phase is updated
        -- TODO: generalize the architecture code
        -- another counter_limit must be used in case of
        -- update_frequency different from clock frequency
        -- and add clock_frequency to the generic parameters
        update_frequency: positive := 100_000_000;
        -- how often the output sample is produced
        output_frequency: positive;
        -- bits of the output sample
        sample_bits: positive;
        -- bits used for the fixed point phase representation
        phase_bits: positive
    );
    port(
        i_clock: in std_logic;
        i_rst: in std_logic;

        -- input frequency tuning word
        -- used to increment the phase accumulator
        i_ftw: in std_logic_vector(phase_bits-1 downto 0);

        o_sample_ready_reg: out std_logic := '0';
        o_sample_reg: out std_logic_vector(sample_bits-1 downto 0) := (others => 'U')
    );
end square_wave_generator;

architecture behavioural of square_wave_generator is
    constant counter_limit: positive := update_frequency/output_frequency;
    constant counter_bits: positive := positive(ceil(log2(real(counter_limit))));

    signal counter: std_logic_vector(counter_bits-1 downto 0) := (others => '0');

    signal phase_accumulator: std_logic_vector(phase_bits-1 downto 0) := (others => '0');
begin
    assert 2**sample_bits <= counter_limit
        report "Output frequency is not high enough to represent the input"
        severity error;

    process (i_clock, i_rst, counter, phase_accumulator)
    begin
        if rising_edge(i_clock) then
            if i_rst then
                o_sample_ready_reg <= '0';
                o_sample_reg <= (others => '0');
            elsif counter = 0 then
                o_sample_ready_reg <= '1';
                -- use first bit of the phase to determine the square wave
                if phase_accumulator(phase_accumulator'left) = '1' then
                    o_sample_reg <= (others => '1');
                else
                    o_sample_reg <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    process (i_clock, i_rst, counter, i_ftw, phase_accumulator)
    begin
        -- TODO: discuss why this shouldn't be reset
        -- i.e.: samples must be consumed before another one is produced
        if rising_edge(i_clock) then
            -- TODO (update_frequency)
            phase_accumulator <= phase_accumulator + i_ftw;
            if counter = counter_limit - 1 then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

end behavioural;
