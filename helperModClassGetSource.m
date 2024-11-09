function src = helperModClassGetSource(modType, sps, spf, fs)
%helperModClassGetSource Source selector for modulation types
%    SRC = helperModClassGetSource(TYPE,SPS,SPF,FS) returns the data source
%    for the modulation type TYPE, with the number of samples per symbol
%    SPS, the number of samples per frame SPF, and the sampling frequency
%    FS.
%   
%   See also ModulationClassificationWithDeepLearningExample.

%   Copyright 2019 The MathWorks, Inc.

switch modType
    case {"BPSK","GFSK","CPFSK","MSK","GMSK"}  % Binary modulations
        M = 2;
        src = @()randi([0 M-1],spf/sps,1);
    case {"QPSK","PAM4","OQPSK"}  % 4-level modulations
        M = 4;
        src = @()randi([0 M-1],spf/sps,1);
    case "8PSK"
        M = 8;
        src = @()randi([0 M-1],spf/sps,1);
    case "16QAM"
        M = 16;
        src = @()randi([0 M-1],spf/sps,1);
    case "64QAM"
        M = 64;
        src = @()randi([0 M-1],spf/sps,1);
end
end
