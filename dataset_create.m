numFrame = 1;
frameLen = 1024;
modulationType = ["BPSK","GFSK","CPFSK","QPSK","PAM4","8PSK", "16QAM", "64QAM","MSK","GMSK"];
sps = 8;
fs = 200e3;
snr = 0:0.1:30;
% Channel characteristics
fadingType = {'AWGN', 'Rayleigh','Rician'};

pathDelays = 0; % frequency-flat
avgPathGains = 0; % frequency-flat


maxDopplerShift = 0.001; % default
kFactor = [1, 3, 5, 7, 10];
rolloff = 0.35;
filterSpan = 4;
promptsFilename = 'prompts.txt';
% Specify the directory path
dirPath = '/Users/crumptrey/Documents/MATLAB/Examples/R2024a/deeplearning_shared/ModulationClassificationWithDeepLearningExample/data';

% Check if the directory exists
if exist(dirPath, 'dir')
    % If it exists, remove it along with all its contents
    rmdir(dirPath, 's');
    disp(['Directory "', dirPath, '" has been deleted.']);
else
    % If it doesn't exist, create the directory
    mkdir(dirPath);
    disp(['Directory "', dirPath, '" has been created.']);
end

% Calculate total number of parameter combinations for progress tracking
totalCombinations = numFrame * length(modulationType) * length(snr) * length(pathDelays) * length(avgPathGains) * ... 
    length(maxDopplerShift) * length(kFactor);
if strcmp(fadingType, 'Rician')
    totalCombinations = totalCombinations * length(kFactor);
end
totalCombinations
currentCombination = 0;

tic;
parfor fadingInd = 1:length(fadingType)
    for modType = 1:length(modulationType)
        for snrInd = 1:length(snr)
            fading = fadingType(fadingInd);
            fading = fading{1};
            if strcmp(fadingType(fadingInd), 'Rician')
                for kInd = 1:length(kFactor)
                    generateModulatedSignal(numFrame, frameLen, modulationType(modType), sps, fs, snr(snrInd), ...
                        fading, pathDelays, avgPathGains, maxDopplerShift, kFactor(kInd));
                end
            else
                % Loop through each frame
                   generateModulatedSignal(numFrame, frameLen, modulationType(modType), sps, fs, snr(snrInd), ...
                        fading, pathDelays, avgPathGains, maxDopplerShift, kFactor);
            end
        end
    end
end
% Stop the timer and display elapsed time
elapsedTime = toc;
fprintf('Total time for simulation: %.2f seconds\n', elapsedTime);





