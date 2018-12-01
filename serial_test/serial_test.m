clear;

serial_port = '/dev/ttyUSB1';

s_out = open_serial_midi_port(serial_port);

% 90: noteon, 45 is A @ 440Hz, 50: velocity
note_on = hex2dec(['90';'45'; '50']);
note_on_2 = hex2dec(['90';'49'; '50']);
note_off = hex2dec(['89'; '45'; '50']);
note_off_2 = hex2dec(['89'; '49'; '50']);
fwrite(s_out, note_on);
pause(1);
fwrite(s_out, note_on_2);
pause(2);
fwrite(s_out, note_off);
pause(1);
fwrite(s_out, note_off_2);

fclose(s_out);