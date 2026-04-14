function pulseTimes = ExtractFixedPulsesByBit(binName, path, bit, chunkSize, pulseLen_s)
% ExtractFixedPulsesByBit  Extract start/end times using a chosen SY bit.
%   pulseTimes = ExtractFixedPulsesByBit(binName, path, bit, chunkSize, pulseLen_s)
%   - bit is 1-based bit index (1..16)
%   - pulseLen_s default 0.400
    if nargin < 4 || isempty(chunkSize), chunkSize = 1e6; end
    if nargin < 5 || isempty(pulseLen_s), pulseLen_s = 0.400; end

    meta = SGLX_readMeta.ReadMeta(binName, path);
    sRate = SGLX_readMeta.SampRate(meta);
    nSavedChans = str2double(meta.nSavedChans);
    syncCh = nSavedChans;
    bytesPerSamp = 2;
    nFileBytes = str2double(meta.fileSizeBytes);
    nSampTotal = nFileBytes / (nSavedChans * bytesPerSamp);

    fid = fopen(fullfile(path, binName), 'r');
    if fid < 0, error('Cannot open file %s', fullfile(path, binName)); end

    openStart = 0;
    pulseList = zeros(0,2);

    nChunks = ceil(nSampTotal / chunkSize);
    for c = 1:nChunks
        startSamp0 = (c-1)*chunkSize;
        nRead = min(chunkSize, nSampTotal - startSamp0);

        offset = (startSamp0 * nSavedChans + (syncCh-1)) * bytesPerSamp;
        fseek(fid, offset, 'bof');

        raw = fread(fid, nRead, 'int16', (nSavedChans-1)*bytesPerSamp);
        if isempty(raw), break; end
        sy = uint16(raw(:)');

        vec = logical(bitget(sy, bit));
        prevVec = [openStart>0, vec(1:end-1)];
        risePos = find(prevVec==0 & vec==1);
        fallPos = find(prevVec==1 & vec==0);

        % rises
        for i = 1:numel(risePos)
            if openStart == 0
                openStart = startSamp0 + risePos(i);  % 0-based
            else
                % unexpected, close old at this rise
                pulseList(end+1,:) = [openStart, startSamp0 + risePos(i)];
                openStart = startSamp0 + risePos(i);
            end
        end

        % falls
        for i = 1:numel(fallPos)
            if openStart ~= 0
                pulseList(end+1,:) = [openStart, startSamp0 + fallPos(i)];
                openStart = 0;
            end
        end
    end

    % close outstanding open pulse if any, use fixed pulse length if necessary
    if openStart ~= 0
        endSample = min(nSampTotal, openStart + round(pulseLen_s * sRate));
        pulseList(end+1,:) = [openStart, endSample];
        openStart = 0;
    end

    fclose(fid);

    % If pulses are fixed length, optionally override ends:
    pulseTimes = [(pulseList(:,1)-1)/sRate, (pulseList(:,1)-1)/sRate + pulseLen_s];

    fprintf('Extracted %d pulses (bit %d). Returned times in seconds.\n', size(pulseTimes,1), bit);
end
