clear;
fp = fopen('pwm_out.txt');
cell = textscan(fp, '%s', 'delimiter', '\n');
fclose(fp);

pwm_data = zeros(1, length(cell{1}));
pwm_frequency = str2double(cell{1}{1});
for i = 2:length(cell{1})
    pwm_data(i-1) = str2double(cell{1}{i});
end

cutoff_freq = 21000;
ts = (1:length(pwm_data))/pwm_frequency;
[b,a] = butter(4,cutoff_freq/(pwm_frequency/2), 'low');
filtered_pwm = filter(b, a, pwm_data);
L = length(pwm_data);

spectrum = fft(pwm_data - mean(pwm_data));
Y2 = abs(spectrum/L);
Y1 = Y2(1:floor(L/2+1));
Y1(2:end-1) = 2*Y1(2:end-1);

filtered_spectrum = fft(filtered_pwm - mean(filtered_pwm));
Z2 = abs(filtered_spectrum/L);
Z1 = Z2(1:floor(L/2+1));
Z1(2:end-1) = 2*Z1(2:end-1);

figure;
fs = pwm_frequency*(0:(L/2))/L;
subplot(2, 2, 1); 
plot(ts, pwm_data);
subplot(2, 2, 2);
plot(ts, filtered_pwm);
subplot(2, 2, 3);
semilogx(fs, mag2db(Y1));
subplot(2, 2, 4);
semilogx(fs, mag2db(Z1));
