library ieee;
use ieee.std_logic_1164.all;

package midi is
    type midi_message_type is (note_off, note_on);
    type midi_message is record
        msg_type: midi_message_type;
        channel: std_logic_vector(3 downto 0);
        data_1: std_logic_vector(6 downto 0);
        data_2: std_logic_vector(6 downto 0);
    end record midi_message;

    constant midi_message_init: midi_message := (
        msg_type => note_off,
        channel => 4x"0",
        data_1 => 7x"0",
        data_2 => 7x"0"
    );

    constant MAX_MIDI_NOTE_NUMBER: positive := 127;
end package midi;
