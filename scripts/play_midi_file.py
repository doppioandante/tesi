import serial
import mido

mid = mido.MidiFile('test_bach.mid')
with serial.Serial('/dev/ttyUSB1', 31250, timeout=1) as ser:
    for msg in mid.play():
        msg = msg.copy(channel=0)
        print(msg)
        bs = msg.bytes()
        ser.write(bytes(bs))


