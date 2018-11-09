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
        clock: in std_logic;
        ce: in std_logic;

        phase_input_enable: in std_logic;
        phase_step: in std_logic_vector(phase_bits-1 downto 0);

        output_enable: out std_logic := '0';
        output_sample: out std_logic_vector(sample_bits-1 downto 0)
    );
end square_wave_generator;

architecture behavioural of square_wave_generator is
    constant counter_limit: positive := update_frequency/output_frequency;
    constant counter_bits: positive := positive(ceil(log2(real(counter_limit))));

    signal counter: std_logic_vector(counter_bits-1 downto 0) := (others => '0');

    signal phase: std_logic_vector(phase_bits-1 downto 0) := (others => '0');
    signal m_phase_step: std_logic_vector(phase_bits-1 downto 0) := (others => '0');
begin
    assert 2**sample_bits <= counter_limit
        report "Output frequency is not high enough to represent the input"
        severity error;

    process (counter, phase)
    begin
        if counter = 0 then
            output_enable <= '1';
            -- use first bit of the phase to determine the square wave
            if phase(phase'left) = '1' then
                output_sample <= (others => '1');
            else
                output_sample <= (others => '0');
            end if;
        else
            output_enable <= '0';
            output_sample <= (others => '0');
        end if;
    end process;

    process (clock, phase_input_enable, phase_step, ce)
    begin
        if ce = '1' and rising_edge(clock) then
            if phase_input_enable then
                m_phase_step <= phase_step;
            end if;
        end if;
    end process;

    process (clock, counter, phase, m_phase_step, ce)
    begin
        if ce = '1' then
            if rising_edge(clock) then
                -- TODO...

                -- NOTE: in case a new m_phase_step was set,
                -- this update will be delayed by one clock cycle
                -- Could be corrected by reading phase_step here instead
                -- when input_enable is '1'
                phase <= phase + m_phase_step;
                if counter = counter_limit - 1 then
                    counter <= (others => '0');
                else
                    counter <= counter + 1;
                end if;
            end if;
        end if;
    end process;

end behavioural;
