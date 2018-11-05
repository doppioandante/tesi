library ieee;
use ieee.std_logic_1164.all;
use work.midi.all;

entity sound_scheduler is
    generic(
        phase_bits: positive
    );
    port(
        clock: in std_logic;

        -- activate for one clock cycle
        -- to read midi_in
        input_enable: in std_logic;
        midi_in: in midi_message;

        -- high for one clock cycle to signal
        -- a new output_phase_step
        update_tone_generator: out std_logic := '0';
        output_phase_step: out std_logic_vector(phase_bits-1 downto 0);
        
        -- low if no sound should be played
        sound_enable: out std_logic := '0'
    );
end sound_scheduler;

architecture behavioural of sound_scheduler is
    package mtp is new work.midi_to_phase_generic
    generic map(
        phase_update_frequency => 100_000_000,
        phase_bits => phase_bits,
        rom_filename => "note_phase_table.txt"
    );

    type state_type is (playing, off);
    signal state, next_state: state_type := off;
    signal current_note_on, next_note_on: std_logic_vector(6 downto 0);
begin  
    process (clock, next_state, next_note_on)
    begin
        if rising_edge(clock) then
            state <= next_state;
            current_note_on <= next_note_on;
        end if;
    end process;

    process (state, current_note_on, midi_in, input_enable)
    begin
        next_state <= state;
        next_note_on <= current_note_on;
        update_tone_generator <= '0';
        sound_enable <= '0';

        if state = playing then
            sound_enable <= '1';
        end if;

        if input_enable = '1' then
            case midi_in.msg_type is
                when note_on =>
                    next_note_on <= midi_in.data_1;
                    output_phase_step <= mtp.midi_note_to_phase_step(midi_in.data_1);
                    update_tone_generator <= '1';
                    next_state <= playing;

                when note_off =>
                    if current_note_on = midi_in.data_1 then
                        next_state <= off;
                        sound_enable <= '0';
                    end if;
            end case;
        end if;
    end process;
end behavioural;
