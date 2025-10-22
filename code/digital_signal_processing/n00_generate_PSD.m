%%% Function to generate power spectral densities of input sample signals (n_channels x n_samples matrix).
%%% Returns power spectral density of selected frequency indices.

function PSD = n00_generate_PSD(data_samples, sampling_rate, min_idx, max_idx)

PSD = zeros(size(data_samples, 1), max_idx - min_idx + 1);
n_samples = size(data_samples, 2);
window = hamming(n_samples)';
data_samples = double(data_samples) .* window;

for idx = 1:size(data_samples, 1)
    
    sample = data_samples(idx, :);
    
    X = fft(sample); %%% Calculation of fourier coefficients
    
    Pxx = (abs(X(1:n_samples/2+1)).^2) * 2 / (sampling_rate * n_samples); %%% PSD calculation of real signal
    
    Pxx(1) = Pxx(1) / 2; %%% Correction of 0Hz DC value
    
    PSD(idx, :) = Pxx(min_idx:max_idx); %%% Only keeping the frequency range to be plotted
    
end

end