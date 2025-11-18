function pulseTimes = ExtractSyncPulsesChunked(binName, path, chunkSize)
% Extract start/end times of sync pulses without loading entire file.
% Works on very large SpikeGLX .ap.bin recordings.
%
% binName   = filename of .ap.bin
% path      = folder containing binName
% chunkSize = number of samples to read per chunk (e.g. 1e6)

    if nargin < 3
        chunkSize = 1e6; % default: 1 million samples (~33 s at 30 kHz)
    end

    % --- Load metadata
    meta = SGLX_readMeta.ReadMeta(binName, path);
    sRate = SGLX_readMeta.SampRate(meta);
    nSavedChans = str2double(meta.nSavedChans);
    syncCh = nSavedChans;     % last channel
    bytesPerSamp = 2;         % int16

    % --- Figure out total samples
    nFileBytes = str2double(meta.fileSizeBytes);
    nSampTotal = nFileBytes / (nSavedChans * bytesPerSamp);

    % --- Open file
    fid = fopen(fullfile(path, binName), 'r');
    if fid < 0, error('Cannot open file %s', binName); end

    % --- Loop through chunks
    pulseTimes = [];
    carryOver = 0;  % last value of previous chunk

    nChunks = ceil(nSampTotal / chunkSize);
    fprintf('Processing %d chunks...\n', nChunks);

    for c = 1:nChunks
        startSamp = (c-1)*chunkSize;
        nRead = min(chunkSize, nSampTotal - startSamp);

        % Position to sync channel for this chunk
        offset = (startSamp * nSavedChans + (syncCh-1)) * bytesPerSamp;
        fseek(fid, offset, 'bof');

        % Read with stride to skip other channels
        syncData = fread(fid, [1 nRead], ...
            ['int16=>' 'double'], (nSavedChans-1)*bytesPerSamp);

        % Threshold
        syncData = syncData > 0;

        % Add carry-over at the start
        if carryOver
            syncData = [carryOver syncData];
            startIdxOffset = startSamp - 1; % adjust for added sample
        else
            startIdxOffset = startSamp;
        end

        % Find edges
        dSync = diff([0 syncData 0]);
        riseIdx = find(dSync == 1);
        fallIdx = find(dSync == -1);

        % Convert to absolute sample indices
        riseIdx = riseIdx + startIdxOffset;
        fallIdx = fallIdx + startIdxOffset;

        % Convert to time in seconds
        riseTime = (riseIdx - 1) / sRate;
        fallTime = (fallIdx - 1) / sRate;

        % Store
        nPulses = min(numel(riseTime), numel(fallTime));
        if nPulses > 0
            pulseTimes = [pulseTimes; [riseTime(1:nPulses)' fallTime(1:nPulses)']];
        end

        % Update carry-over
        carryOver = syncData(end);
    end

    fclose(fid);
    fprintf('Found %d pulses total.\n', size(pulseTimes,1));
end
