% midi notes go from 0 to 127
% that is C-1 to G9 respectively

% frequencies follow a geometric relationship
% A4 to A5 is 440 -> 880, an octave is a * 2 multiplication
% to divide the octaive in 12 steps, we must have
% base_note * step^12 = octave_higher_note
% where step^12 = 2
% This implies step = 2^(1/12)

clear;
A4 = 440; % reference, note #69
phase_bits = 32;
phase_update_frequency = 1e8;

indices = 0:127;
table = A4 * 2.^((indices - 69)/12);

% convert the frequencies in Hz to tuning words
table = round(table .* 2^phase_bits/phase_update_frequency);
% write out the padded binary strings
% each line will contain its own ftw, 128 lines in total
dlmwrite('note_phase_table.txt', num2cell(dec2bin(table, phase_bits)), 'delimiter', '');
