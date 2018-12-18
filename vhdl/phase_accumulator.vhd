library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity phase_accumulator is
    generic(
        clock_frequency: positive := 100_000_000;
        -- bits used for the fixed point phase representation
        phase_bits: positive
    );
    port(
        i_clock: in std_logic;
        i_rst_sync: in std_logic;

        -- input frequency tuning word
        -- used to increment the phase accumulator
        i_ftw: in std_logic_vector(phase_bits-1 downto 0);

        o_phase_reg: out std_logic_vector(phase_bits-1 downto 0) := (others => '0')
    );
end phase_accumulator;

architecture behavioural of phase_accumulator is
begin
    process (i_clock, i_rst_sync, o_phase_reg)
    begin
        if rising_edge(i_clock) then
            if i_rst_sync then
                o_phase_reg <= (others => '0');
            else
                o_phase_reg <= o_phase_reg + i_ftw;
            end if;
        end if;
    end process;
end behavioural;
