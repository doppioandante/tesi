library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use work.midi.all;

entity active_notes_lut is
    port(
        clock: in std_logic;

        -- activate for one clock cycle
        -- to read midi_in
        input_enable: in std_logic;
        midi_in: in midi_message;

        -- list of active notes
        o_active_notes_reg: out std_logic_vector(MAX_MIDI_NOTE_NUMBER downto 0) := (others => '0')
    );
end active_notes_lut;

architecture behavioural of active_notes_lut is
begin
    process (clock, input_enable, midi_in)
        variable note_index: integer range 0 to MAX_MIDI_NOTE_NUMBER;
    begin
        if input_enable = '1' and rising_edge(clock) then
            note_index := to_integer(midi_in.data_1);

            if midi_in.msg_type = note_on then
                o_active_notes_reg(note_index) <= '1';
            else
                o_active_notes_reg(note_index) <= '0';
            end if;
        end if;
    end process;
end behavioural;
