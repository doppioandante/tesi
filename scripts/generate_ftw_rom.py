# midi notes go from 0 to 127
# that is C-1 to G9 respectively

# frequencies follow a geometric relationship
# A4 to A5 is 440 -> 880, an octave is a * 2 multiplication
# to divide the octaive in 12 steps, we must have
# base_note * step^12 = octave_higher_note
# where step^12 = 2
# This implies step = 2^(1/12)

A4 = 440 # A4 (midi number 69) is set to 440Hz in the standard midi tuning
phase_bits = 32
phase_update_frequency = 1e8 # the phase is updated at every clock cycle

frequencies = [A4 * 2**((i - 69)/12) for i in range(0, 128)]

with open('note_phase_table.txt', 'w') as fp:
    for freq in frequencies:
        ftw = round(freq/phase_update_frequency * 2**phase_bits)
        fp.write("{0:0{phase_bits}b}\n".format(ftw, phase_bits=phase_bits))
