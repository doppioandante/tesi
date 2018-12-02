library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

package rom is
    generic (
        word_bits: positive;
        address_bits: positive;
        rom_filename: string
    );

    subtype word_type is std_logic_vector(word_bits-1 downto 0);

    impure function read_at(address: in integer range 0 to 2**address_bits-1) return word_type;
end package rom;

package body rom is

    impure function read_at(
        address: in integer range 0 to 2**address_bits-1
    ) return word_type is
        type rom_type is array(0 to 2**address_bits-1) of word_type;

        impure function init_rom_from_file (filename: in string) return rom_type is
            file rom_file: text;
            variable file_line : line;
            variable rom_array: rom_type;
        begin
            file_open(rom_file, filename, read_mode);
            for i in rom_type'range loop
                readline(rom_file, file_line);
                read(file_line, rom_array(i));
           end loop;
           file_close(rom_file);
           return rom_array;
        end function;
     constant rom_array: rom_type := init_rom_from_file(rom_filename);
    begin
        return rom_array(address);        
    end function read_at;
end package body rom;
