% Load the generated signal data from the HDF5 file
hdf5Filename = '/Users/crumptrey/Documents/MATLAB/Examples/R2024a/deeplearning_shared/ModulationClassificationWithDeepLearningExample/data/signals_QPSK_SNR30.0_fading_AWGN.h5';  % Specify your file path

try
    % Load the real and imaginary parts of the received signals
    realPart = h5read(hdf5Filename, '/rxSignals/real');
    imagPart = h5read(hdf5Filename, '/rxSignals/imag');
    
    % Load the prompts (description of each frame)
    prompts = h5read(hdf5Filename, '/prompts');
    
    % Combine real and imaginary parts to form the received signals
    rxSignals = realPart + 1i * imagPart;
    
    % Check the dimensions of the loaded signals
    [numFrames, frameLen] = size(rxSignals);
    disp(['Number of frames: ', num2str(numFrames)]);
    disp(['Frame length: ', num2str(frameLen)]);
    
    % Power Normalization Check
    % Calculate the total power of the signal (sum of squares of real and imaginary parts)
    signalPower = sum(abs(rxSignals).^2, 2) / frameLen;  % Average power per frame
    
    % Check if the power is normalized (i.e., close to 1)
    tolerance = 1e-2;  % Allowable tolerance for normalization
    if all(abs(signalPower - 1) < tolerance)
        disp('Signal power is normalized.');
    else
        disp('Warning: Signal power is not normalized.');
        % Optionally, normalize the signals if needed
        rxSignals = rxSignals / sqrt(mean(signalPower));  % Normalize the signal to unit power
        disp('Signals have been normalized.');
    end
    
    % Visualize some of the signals in the time domain
    figure;
    subplot(2,1,1);
    plot(real(rxSignals(1,:)));
    title('Time-domain of First Frame (Real Part)');
    xlabel('Sample Index');
    ylabel('Amplitude');
    
    subplot(2,1,2);
    plot(imag(rxSignals(1,:)));
    title('Time-domain of First Frame (Imaginary Part)');
    xlabel('Sample Index');
    ylabel('Amplitude');
    
    % Visualize the frequency spectrum of the first signal frame
    figure;
    subplot(2,1,1);
    fftRx = abs(fft(rxSignals(1,:)));
    plot(fftRx);
    title('Frequency Spectrum of First Frame');
    xlabel('Frequency Index');
    ylabel('Magnitude');
    
    % Power Spectral Density (PSD) Plot
    nfft = 1024;  % Length of the FFT
    fs = 200e3;  % Sampling frequency (example)
    freqAxis = (-nfft/2:nfft/2-1) * (fs/nfft);  % Frequency axis for plotting
    fftRx = fftshift(fft(rxSignals(1,:), nfft));  % Frequency-shifted FFT
    psdRx = abs(fftRx).^2 / nfft;  % Normalized PSD

    % Plot PSD in dB
    subplot(2,1,2);
    plot(freqAxis/1e6, 10*log10(psdRx));  % Convert to dB scale
    title('Power Spectral Density of First Frame');
    xlabel('Frequency (MHz)');
    ylabel('Power (dB)');

    % Optionally, compute the bandwidth using -3 dB threshold
    threshold_dB = -3;  % -3 dB threshold for bandwidth estimation
    half_max = max(psdRx) * 10^(threshold_dB/10);  % -3dB point

    % Find the indices where the PSD crosses the -3 dB point
    bwIndices = find(psdRx >= half_max);
    bandwidth = (freqAxis(bwIndices(end)) - freqAxis(bwIndices(1)));  % Bandwidth in Hz
    disp(['Estimated Bandwidth: ', num2str(bandwidth), ' Hz']);

    % For further validation, compare with expected bandwidth based on modulation type
    % Example: For QPSK, the bandwidth should roughly match the symbol rate (sps)
    expectedBandwidth = sps;  % Assuming a symbol rate of sps samples per symbol
    % Assuming modulation order M and roll-off factor alpha are known
    M = 4;  % Example for QPSK
    alpha = 0.35;  % Roll-off factor, e.g., 0.35 for typical raised cosine filters
    
    % Symbol rate calculation based on the data rate
    dataRate = 1e6;  % Example data rate in bps
    symbolRate = dataRate / log2(M);  % Symbol rate in symbols per second
    
    % Bandwidth calculation using raised cosine filter with roll-off factor
    expectedBandwidth = (1 + alpha) * symbolRate;
    disp(['Expected Bandwidth: ', num2str(expectedBandwidth), ' Hz']);
    % Display some prompts
    disp('First 3 prompts for validation:');
    disp(prompts);
    
catch ME
    disp(['Error during validation: ', ME.message]);
end
