function s_out = open_serial_midi_port(device_name)
    if ispc
        system(['win_set_baud.exe ' device_name]);
    else
        % FIXME: set_baud doesn't work under matlab (ioctl doesn't set the
        % precise baud rate)
        % The windows program under wine works though...
        system(['wine win_set_baud.exe ' device_name]);
        %system('gcc set_baud.c -o set_baud');
        %system(['./set_baud ' device_name]);
    end

    s_out = serial(device_name, 'BaudRate', 31250);
    fopen(s_out);
end