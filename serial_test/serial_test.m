serial_port = '/dev/ttyUSB1';

if ispc
    system(['win_set_baud.exe ' serial_port]);
else
    % FIXME: set_baud doesn't work under matlab (ioctl doesn't set the
    % precise baud rate)
    % The windows program under wine works though...
    system(['wine win_set_baud.exe ' serial_port]);
    %system('gcc set_baud.c -o set_baud');
    %system(['./set_baud ' serial_port]);
end

s_out = serial(serial_port, 'BaudRate', 31250);
fopen(s_out);
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