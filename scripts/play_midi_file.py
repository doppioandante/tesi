import serial
import mido

mid = mido.MidiFile('test_bach.mid')
with serial.Serial('/dev/ttyUSB1', 31250, timeout=1) as ser:
    for msg in mid.play():
        if msg.type == 'note_on' and msg.velocity == 0:
            note_off = mido.Message('note_off', note=msg.note, velocity=msg.velocity, time=msg.time)
            msg = note_off

        print(msg)
        bs = msg.copy(channel=0).bytes()
        ser.write(bytes(bs))


