library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity mixer is
    generic(
        sample_bits: positive;
        output_bits: positive;
        number_of_inputs: positive
    );
    port(
        i_clock: in std_logic;

        i_active_notes: in std_logic_vector(number_of_inputs-1 downto 0);
        -- samples to be processed
        -- i_samples((i+1) * sample_bits-1 downto i*sample_bits) is the i-th sample
        i_samples: in std_logic_vector(sample_bits*number_of_inputs-1 downto 0);

        -- active for one clock cycle
        i_generate_output_sample: in std_logic;
        o_sample_reg: out std_logic_vector(output_bits-1 downto 0) := (others => '0')
    );
end mixer;

architecture behavioural of mixer is
begin
    assert output_bits >= sample_bits;

    process (all) is
        variable sum: std_logic_vector(output_bits-1 downto 0);
        variable sample_value: std_logic_vector(output_bits-1 downto 0);
    begin
        if rising_edge(i_clock) and i_generate_output_sample = '1' then
            sum := (others => '0');
            sample_value(output_bits-1 downto sample_bits) := (others => '0');
            for i in i_active_notes'range loop
                if i_active_notes(i) then
                    sample_value(sample_bits-1 downto 0) := i_samples((i+1)*sample_bits-1 downto i*sample_bits);
                else
                    sample_value(sample_bits-1 downto 0) := (others => '0');
                end if;
                sum := sum + sample_value;
            end loop;

            o_sample_reg <= sum;
        end if;
    end process;
end behavioural;
