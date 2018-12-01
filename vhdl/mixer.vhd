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


-- architecture behavioural of mixer is
--     signal outputs: std_logic_vector(sample_bits*(MAX_MIDI_NOTE_NUMBER+1)-1 downto 0) := (others => '0');
-- begin
--     gen: for i in 0 to MAX_MIDI_NOTE_NUMBER generate
--         gen_if: if i = 0 generate
--             outputs(sample_bits-1 downto 0) <=
--                 i_samples(sample_bits-1 downto 0) when i_active_notes(i) = '1'
--                 else (others => '0');
--         else generate
--             outputs((i+1)*sample_bits-1 downto i*sample_bits) <=
--                 i_samples((i+1)*sample_bits-1 downto i*sample_bits)
--                 + outputs(i*sample_bits-1 downto (i-1)*sample_bits) when i_active_notes(i) = '1'
--                 else outputs(i*sample_bits-1 downto (i-1)*sample_bits);
--         end generate gen_if;
--     end generate gen;
--     
--     process (all) is
--     begin
--         if rising_edge(i_clock) and i_generate_output_sample = '1' then
--             o_sample_reg <= outputs((MAX_MIDI_NOTE_NUMBER+1)*sample_bits-1 downto MAX_MIDI_NOTE_NUMBER*sample_bits);
--         end if;
--     end process;
-- end behavioural;
