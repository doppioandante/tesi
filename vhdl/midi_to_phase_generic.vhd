library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

package midi_to_phase_generic is
    generic (
        phase_update_frequency: positive;
        phase_bits: positive;
        rom_filename: string
    );

    subtype phase_type is std_logic_vector(phase_bits-1 downto 0);

    impure function midi_note_to_phase_step(note_number: in std_logic_vector(6 downto 0)) return phase_type;
end package midi_to_phase_generic;

package body midi_to_phase_generic is
    impure function midi_note_to_phase_step(
        note_number: in std_logic_vector(6 downto 0)
    ) return phase_type is
        type rom_type is array(0 to 127) of phase_type;

        impure function init_rom_from_file (filename: in string) return rom_type is
            file rom_file: text;
            variable file_line : line;
            variable phase: positive;
            variable rom: rom_type;
        begin
            file_open(rom_file, filename, read_mode);
            for i in rom_type'range loop
                readline(rom_file, file_line);
                read(file_line, rom(i));
           end loop;
           file_close(rom_file);
           return rom;
        end function;
     constant rom: rom_type := init_rom_from_file(rom_filename);
    begin
        return rom(to_integer(note_number));        
    end function midi_note_to_phase_step;
end package body midi_to_phase_generic;
