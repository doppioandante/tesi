using DSP
using Plots

function lowpass_filter(data, freq, sampling_frequency)
    responsetype = DSP.Lowpass(freq; fs=sampling_frequency)
    designmethod = DSP.Butterworth(4)
    x = DSP.filt(DSP.digitalfilter(responsetype, designmethod), data)
    return x
end

data = readlines("pwm_out.txt")
pwm_clock_freq = parse(Float64, data[1])
pwm_data = zeros(length(data) - 1)
for i in 2:length(data)
    if data[i] == "0"
        pwm_data[i-1] = 0
    else
        pwm_data[i-1] = 1
    end
end
ts = (1:length(pwm_data))/pwm_clock_freq
filtered_pwm = lowpass_filter(pwm_data, 22000, pwm_clock_freq)
plot(ts, [pwm_data filtered_pwm], layout=(2,1))
savefig("pwm.svg")