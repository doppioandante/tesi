# midi notes go from 0 to 127
# that is C-1 to G9 respectively

# frequencies follow a geometric relationship
# A4 to A5 is 440 -> 880, an octave is a * 2 multiplication
# to divide the octaive in 12 steps, we must have
# base_note * step^12 = octave_higher_note
# where step^12 = 2
# This implies step = 2^(1/12)

using DelimitedFiles

A4 = 440 # reference
phase_bits = 32
phase_update_frequency = 100_000_000

table = zeros(128)
#table[69] = A4
table[1] = A4/2^6 * 2^(3/12) # A-1 to C-1

for i in 2:length(table)
    table[i] = table[i-1] * 2^(1/12)
end

table *= 2^32/phase_update_frequency
table = string.(Int.(round.(table, digits = 0, base = 2)), base = 2, pad = phase_bits)

writedlm("note_phase_table.txt", table)