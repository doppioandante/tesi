module PWM

import WAV
import DSP

function generate_pwm(sample, pwm_period, sampling_period, sampling_offset = 0.0)
    @assert -1.0 <= sample <= 1.0
    @assert pwm_period > sampling_period
    Ts = sampling_offset:sampling_period:pwm_period

    output = zeros(length(Ts))
    duty_cycle = pwm_period * abs(sample)
    for i in 1:length(Ts)
        if i * sampling_period <= duty_cycle
            output[i] = Float64(sign(sample))
        else
            output[i] = 0.0
        end
    end

    return output
end

function generate_sine_pwm(amplitude, freq, t_max, sine_sampling_frequency, pwm_sampling_frequency)
    sampling_step = 1/sine_sampling_frequency
    output = Array{Float64, 1}()
    for t in 0.0:sampling_step:t_max
        sample = amplitude * sin(2*pi*t * freq)
        offset = mod(t, 1/pwm_sampling_frequency)
        append!(output, generate_pwm(sample, 1/sine_sampling_frequency, 1/pwm_sampling_frequency, offset))
    end

    ts = 0:1/pwm_sampling_frequency:t_max
    return 0:1/pwm_sampling_frequency:t_max, output[1:length(ts)]
end

function lowpass_filter(data, freq, sampling_frequency)
    responsetype = DSP.Lowpass(freq; fs=sampling_frequency)
    designmethod = DSP.Butterworth(4)
    x = DSP.filt(DSP.digitalfilter(responsetype, designmethod), data)
    return x
end

function test_pwm_sine(amplitude, freq, t_max, Fs = 44200)
    pwm_clock_freq = 100_000_000
    ts, pwm_sine = generate_sine_pwm(amplitude, freq, t_max, 50000, pwm_clock_freq)
    filtered_pwm = lowpass_filter(pwm_sine, 22000, pwm_clock_freq)

    wav_time_points = 0:1/Fs:t_max
    samples = Array{Float64, 1}()
    for t in wav_time_points
        time_idx = searchsortedlast(ts, t)
        push!(samples, filtered_pwm[time_idx])
    end

    return wav_time_points, samples
end

function main()
    Fs = 44200
    ts, ys = test_pwm_sine(0.1, 440, 0.5, Fs)
    WAV.wavplay(ys, Fs)
end

end # end module
