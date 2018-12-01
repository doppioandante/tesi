clear;

serial_port = '/dev/ttyUSB1';

s_out = open_serial_midi_port(serial_port);

for note = 0:127 
    fwrite(s_out, [hex2dec('90'); note; hex2dec('50')]);
    pause(0.2);
    fwrite(s_out, [hex2dec('89'); note; hex2dec('50')]);
end

fclose(s_out);