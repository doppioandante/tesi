# Simple syntheziser running on digilent NEXYS4 DDR board

## Testing instructions
Flash the board using the following files found in the `vhdl` folder:

* midi.vhd
* midi_to_phase_generic.vhd
* uart.vhd
* midi_decoder.vhd
* uart_midi_link.vhd
* sound_scheduler.vhd
* pwm_converter.vhd
* square_wave_generator.vhd
* synth_top.vhd
* note_phase_table.txt

The syntheziser can be operated through the serial usb port.
Baud rate must be 31250 (like native midi connection), with only one stop bit and no parity bit.
Testing under linux can be done using the `serial_test/test.sh` script, run under bash.
Make sure that your user is in the `dialout` group and that `gcc` is installed.

```bash
$ bash test.sh /dev/ttyUSB1
```

Note that `/dev/ttyUSB1` may be different on your system.
