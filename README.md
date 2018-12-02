# Simple syntheziser running on digilent NEXYS4 DDR board

## Testing instructions
Flash the board using the following files found in the `vhdl` folder:

* counter_utils_pkg.vhd
* counter_impulse_generator.vhd
* rom_pkg.vhd
* midi.vhd
* uart.vhd
* midi_decoder.vhd
* uart_midi_link.vhd
* active_notes_lut.vhd
* square_wave_generator.vhd
* mixer.vhd
* pwm_encoder.vhd
* synth_top.vhd
* note_phase_table.txt

The syntheziser can be operated through the serial usb port.
Baud rate must be 31250 (like native midi connection), with only one stop bit and no parity bit.

## Testing using the provided MATLAB script
Run the `serial_test/serial_test.m` script. The `serial_port` variable at the top
of the script containts the USB serial port name and may have to be modified under your system (e.g. 'COM1' for Windows).
Under UNIX-like systems, make sure that your user is in the `dialout` group and that `gcc` is installed.
Compile the `set_baud.c` in the `serial_test` folder before running the matlab script:
```bash
$ gcc set_baud.c -o set_baud
```

**WARNING**: a weird interaction between `set_baud` and `MATLAB` makes impossible to set the accurate baud rate
when running the serial test, so the windows program will be called out and `wine` is necessary under linux.
The binary is provided in the same folder and no compilation is needed.
