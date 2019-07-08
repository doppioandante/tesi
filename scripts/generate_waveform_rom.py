import numpy as np

def get_waveform_rom(address_bits, sample_bits):
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

    return quantized_values.astype(int)

if __name__ == '__main__':
    address_bits = 13
    sample_bits = 11
    for x in get_waveform_rom(address_bits, sample_bits):
        print('{0:0{width}b}'.format(x, width=sample_bits))
