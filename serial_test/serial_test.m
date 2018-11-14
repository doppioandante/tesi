serial_port = '/dev/ttyUSB1';

if ispc
    system(['win_set_baud.exe ' serial_port]);
else
    system(['./set_baud ' serial_port]);
end

s_out = serial(serial_port, 'BaudRate', 31250);
fopen(s_out);
% 90: noteon, 45 is A @ 440Hz, 50: velocity
note_on = hex2dec(['90';'45'; '50']);
note_off = hex2dec(['89'; '45'; '50']);
fwrite(s_out, note_on);
pause(2);
fwrite(s_out, note_off);
fclose(s_out);