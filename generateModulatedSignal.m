function generateModulatedSignal(numFrame, frameLen, modulationType, sps, fs, snr, ...
                                 fadingType, pathDelays, avgPathGains, maxDopplerShift, kFactor)

    % Determine the modulation order and constellation
    dataSrc = helperModClassGetSource(modulationType, sps, 2*frameLen, fs);
    modulator = helperModClassGetModulator(modulationType, sps, fs);

    % Design the SRRC filter
    %rrcFilter = rcosdesign(rolloff, filterSpan, sps);
    transDelay = 50;

    % Pre-allocate storage for signals
    signalMatrix = zeros(numFrame, frameLen);

    % Store prompt details for all frames
    prompts = strings(numFrame, 1);

   % Generate unique filename based on the parameters
    if strcmp(fadingType, 'AWGN')
        % If fading type is AWGN, do not include pathDelays, avgPathGains, or maxDopplerShift
        filenameBase = sprintf('signals_%s_SNR%.1f_fading_%s', ...
                               modulationType, snr, fadingType);
    else
        % For fading types like Rayleigh or Rician, include additional parameters
        filenameBase = sprintf('signals_%s_SNR%.1f_fading_%s_Delay%.2f_Gain%.2f_Doppler%.3f', ...
                               modulationType, snr, fadingType, pathDelays, avgPathGains, maxDopplerShift);
        
        % Append k-factor if Rician fading is used
        if strcmp(fadingType, 'Rician')
            filenameBase = sprintf('%s_KFactor%.2f', filenameBase, kFactor);
        end
    end

    % Generate the full file path (adjust the path as needed)
    hdf5Filename = fullfile('/Users/crumptrey/Documents/MATLAB/Examples/R2024a/deeplearning_shared/ModulationClassificationWithDeepLearningExample/data', ...
                            strcat(filenameBase, '.h5'));

    for i = 1:numFrame
        % Generate random data
        x = dataSrc();
          
        % Modulate
        txSignal = modulator(x);

        % Apply channel fading
        if ~strcmp(fadingType, 'AWGN')
            rxSignal = applyChannelFading(txSignal, sps, fs, fadingType, pathDelays, avgPathGains, maxDopplerShift, kFactor);
            rxSignal = awgn(rxSignal, snr); % Adding noise to the signal
        end

        % Add AWGN
        if strcmp(fadingType, 'AWGN')
            rxSignal = awgn(txSignal, snr);
        end
        

        % Apply SRRC filter to the received signal
        %rxSignal = filter(rrcFilter, 1, rxSignal);
        frame = helperModClassFrameGenerator(rxSignal, frameLen, frameLen, transDelay, sps);
        % Store the received signal
        signalMatrix(i,:,:) = frame;

        % Construct the prompt string for this frame
        prompt = sprintf('%d dB SNR %s signal in a %s fading channel', snr, modulationType, fadingType);
        if strcmp(fadingType, 'Rayleigh')
            pathDelaysStr = sprintf('%.2g ', pathDelays);
            avgPathGainsStr = sprintf('%.2g ', avgPathGains);
            if (pathDelays == 0) && (avgPathGains == 0)
                prompt = sprintf('%s, frequency-flat', ...
                    prompt);
            else
                prompt = sprintf('%s with path delays %s s, average path gains %s dB, maximum Doppler shift %.2f Hz', ...
                    prompt, strtrim(pathDelaysStr), strtrim(avgPathGainsStr), maxDopplerShift);
            end

        elseif strcmp(fadingType, 'Rician')
            pathDelaysStr = sprintf('%.2g ', pathDelays);
            avgPathGainsStr = sprintf('%.2g ', avgPathGains);
            if (pathDelays == 0) && (avgPathGains == 0)
                prompt = sprintf('%s frequency-flat with K-factor of  %.2f', ...
                    prompt, kFactor);
            else
                prompt = sprintf('%s with path delays %s s, average path gains %s dB, K-factor %.2f, maximum Doppler shift %.2f Hz', ...
                    prompt, strtrim(pathDelaysStr), strtrim(avgPathGainsStr), kFactor, maxDopplerShift);
            end
        end
        % Store the prompt for this frame
        prompts(i) = prompt;
    end
    size(signalMatrix);
    % Save all signals and prompts to an HDF5 file
    try
        % Split signalMatrix into real and imaginary parts
        realPart = real(signalMatrix);
        imagPart = imag(signalMatrix);

        % Save real part
        h5create(hdf5Filename, '/rxSignals/real', size(realPart), 'Datatype', 'double');
        h5write(hdf5Filename, '/rxSignals/real', realPart);

        % Save imaginary part
        h5create(hdf5Filename, '/rxSignals/imag', size(imagPart), 'Datatype', 'double');
        h5write(hdf5Filename, '/rxSignals/imag', imagPart);

        % Save prompts
        h5create(hdf5Filename, '/prompts', size(prompts), 'Datatype', 'string');
        h5write(hdf5Filename, '/prompts', prompts);

    catch ME
        disp(['Error saving signals and prompts: ', ME.message]);
    end
end

function fadedSignal = applyChannelFading(signal, sps, fs, fadingType, pathDelays, avgPathGains, maxDopplerShift, kFactor)
    if strcmp(fadingType, 'Rayleigh')
        fadingChannel = comm.RayleighChannel(...
            'SampleRate', fs, ...
            'PathDelays', pathDelays, ...
            'AveragePathGains', avgPathGains, ...
            'MaximumDopplerShift', maxDopplerShift);
    elseif strcmp(fadingType, 'Rician')
        fadingChannel = comm.RicianChannel(...
            'SampleRate', fs, ...
            'PathDelays', pathDelays, ...
            'AveragePathGains', avgPathGains, ...
            'KFactor', kFactor, ...
            'MaximumDopplerShift', maxDopplerShift);
    else
        error('Unsupported fading type.');
    end
    fadedSignal = fadingChannel(signal);
end
