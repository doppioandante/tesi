import serial
import mido

port = 'Studiologic numaconcert:Studiologic numaconcert MIDI 1 20:0'
with mido.open_input(port) as port:
    with serial.Serial('/dev/ttyUSB1', 31250, timeout=1) as ser:
        for msg in port:
            msg = msg.copy(channel=0)
            print(msg)
            bs = msg.bytes()
            ser.write(bytes(bs))


