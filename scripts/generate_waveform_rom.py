import numpy as np

address_bits = 13
sample_bits = 11

t = np.linspace(0, 2 * np.pi, 2 ** address_bits)
samples = 0.4 * np.sin(t)

# the range [-1,1] is mapped into [-2^(sample_bits-1), 2^(sample_bits-1)-1]
quantized_values = np.rint(2**(sample_bits-1) * samples)
# clamp out of range values
quantized_values = np.clip(quantized_values, -2**(sample_bits-1), 2**(sample_bits-1)-1)

# Apply 2-complement to negative values
for i in range(0, len(quantized_values)):
    if quantized_values[i] < 0:
        quantized_values[i] = 2**sample_bits + quantized_values[i]

for x in quantized_values:
    print('{0:0{width}b}'.format(int(x), width=sample_bits))



