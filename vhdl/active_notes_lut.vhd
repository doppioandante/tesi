library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use work.midi.all;

entity active_notes_lut is
    port(
        i_clock: in std_logic;

        -- activate for one clock cycle
        -- to read midi_in
        i_enable: in std_logic;
        i_message: in midi_message;

        -- list of active notes
        o_active_notes_reg: out std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0) := (others => '0')
    );
end active_notes_lut;

architecture behavioural of active_notes_lut is
begin
    process (i_clock, i_enable, i_message)
        variable note_index: integer range 0 to MAX_MIDI_NOTE_NUMBER;
    begin
        if i_enable = '1' and rising_edge(i_clock) then
            note_index := to_integer(i_message.data_1);

            if i_message.msg_type = note_on then
                if to_integer(i_message.data_2) = 0 then
                    o_active_notes_reg(note_index) <= '0';
                else
                    o_active_notes_reg(note_index) <= '1';
                end if;
            else
                o_active_notes_reg(note_index) <= '0';
            end if;
        end if;
    end process;
end behavioural;
