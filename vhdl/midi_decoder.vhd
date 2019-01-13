-- state machine component to decode midi messages

library ieee;
use ieee.std_logic_1164.all;
use work.midi.all;

entity midi_decoder is
    port (
        i_clock: in std_logic;

        -- when set for one clock cycle
        -- will read a byte from i_data
        -- advancing the internal state machine
        i_enable: in std_logic;
        i_data: in std_logic_vector(7 downto 0);

        -- high when the fsm has computed the result
        -- that will be present at o_message
        o_message_available: out std_logic := '0';
        o_message: out midi_message := midi_message_init
    );
end midi_decoder;

architecture behavioural of midi_decoder is
    type state_type is (idle, read_data_1, read_data_2, decoded);

    signal state, next_state: state_type;
    signal midi_msg, next_midi_msg: midi_message := midi_message_init;
begin
    o_message_available <= '1' when state = decoded else '0';

    sync: process (i_clock, next_state, next_midi_msg)
    begin
        if rising_edge(i_clock) then
            state <= next_state;
            midi_msg <= next_midi_msg;
        end if;
    end process sync;

    update_data_out: process(i_clock, next_state, midi_msg)
    begin
        if rising_edge(i_clock) and next_state = decoded then
            o_message <= midi_msg;
        end if;
    end process update_data_out;

    fsm: process (state, midi_msg, i_enable, i_data)
    begin
        next_midi_msg <= midi_msg;
        next_state <= state;

        if i_enable then
            case state is
                when idle | decoded =>
                    next_midi_msg <= midi_message_init;

                    case i_data(7 downto 4) is
                        when x"8" =>
                            next_midi_msg.msg_type <= note_off;
                            next_midi_msg.channel <= i_data(3 downto 0);
                            next_state <= read_data_1;
                        when x"9" =>
                            next_midi_msg.msg_type <= note_on;
                            next_midi_msg.channel <= i_data(3 downto 0);
                            next_state <= read_data_1;
                        when others =>
                            next_state <= state;
                    end case;  

                when read_data_1 =>
                    next_midi_msg.data_1 <= i_data(6 downto 0);

                    case midi_msg.msg_type is
                        when note_on | note_off =>
                            next_state <= read_data_2;

                        -- when only_data1_messages =>
                        --   data_available <= '1';
                        --   next_state <= decoded;
                    end case;

                when read_data_2 =>
                    next_midi_msg.data_2 <= i_data(6 downto 0);
                    next_state <= decoded;
            end case;
        end if;
    end process fsm;
end behavioural;
