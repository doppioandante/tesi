clear;

address_bits = 13;
sample_bits = 11;

t = linspace(0, 2*pi, 2^address_bits);
samples = sin(t);

% the range [-1,1] is mapped into [-2^(sample_bits-1), 2^(sample_bits-1)-1)
quantized_values = round(2^(sample_bits-1) .* samples);
% clamp out of range values
quantized_values(quantized_values >= 2^(sample_bits-1)) = 2^(sample_bits-1)-1;
quantized_values(quantized_values < -2^(sample_bits-1)) = -2^(sample_bits-1);

% Apply 2-complement to negative values
for i = 1:length(quantized_values)
    if quantized_values(i) < 0
        quantized_values(i) = 2^sample_bits + quantized_values(i);
    end
end

dlmwrite('waveform_rom.txt', num2cell(dec2bin(quantized_values, sample_bits)), 'delimiter', '');

