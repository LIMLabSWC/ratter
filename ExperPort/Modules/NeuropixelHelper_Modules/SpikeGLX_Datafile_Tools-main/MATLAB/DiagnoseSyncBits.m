function [stats] = DiagnoseSyncBits(binName, path, chunkSize, maxBits)
% DiagnoseSyncBits  Scan SY word bits and report pulse counts and mean durations.
%   stats = DiagnoseSyncBits(binName, path, chunkSize, maxBits)
%
%   - binName: filename of .ap.bin (string)
%   - path: folder containing the file (string)
%   - chunkSize: number of samples per chunk (default 1e6)
%   - maxBits: how many bits to scan (default 16)
%
%   Returns a struct array stats(b) with fields:
%     .bit            bit number (1-based)
%     .nPulses        number of completed pulses detected
%     .meanDur_s      mean pulse duration (seconds)
%     .medianDur_s    median pulse duration (seconds)
%     .durations_s    vector of durations (seconds) [may be large]
%
    if nargin < 3 || isempty(chunkSize), chunkSize = 1e6; end
    if nargin < 4 || isempty(maxBits), maxBits = 16; end

    meta = SGLX_readMeta.ReadMeta(binName, path);
    sRate = SGLX_readMeta.SampRate(meta);
    nSavedChans = str2double(meta.nSavedChans);
    syncCh = nSavedChans;
    bytesPerSamp = 2;

    nFileBytes = str2double(meta.fileSizeBytes);
    nSampTotal = nFileBytes / (nSavedChans * bytesPerSamp);

    fid = fopen(fullfile(path, binName), 'r');
    if fid < 0, error('Cannot open %s', fullfile(path, binName)); end

    % init
    openStart = zeros(1, maxBits);      % 0 if no open pulse; otherwise sample index of start
    pulses = cell(1, maxBits);          % will hold Nx2 arrays [startSample endSample]
    for b=1:maxBits, pulses{b} = zeros(0,2); end

    nChunks = ceil(nSampTotal / chunkSize);
    for c = 1:nChunks
        startSamp0 = (c-1)*chunkSize;             % 0-based sample index of chunk start
        nRead = min(chunkSize, nSampTotal - startSamp0);

        % seek to sync channel first sample of chunk
        offset = (startSamp0 * nSavedChans + (syncCh-1)) * bytesPerSamp;
        fseek(fid, offset, 'bof');

        % read nRead sync words with stride
        raw = fread(fid, nRead, 'int16', (nSavedChans-1)*bytesPerSamp);
        if isempty(raw), break; end
        sy = uint16(raw(:)');   % row vector of uint16

        % process each bit
        for b = 1:maxBits
            vec = logical(bitget(sy, b));   % 1..nRead logical vector
            prev = openStart(b) > 0;        % previous chunk state: 1 if currently inside a pulse
            % detect rising positions and falling positions in this chunk
            % prevVec is previous sample for first element
            if nRead==0, continue; end
            prevVec = [prev, vec(1:end-1)];
            risePos = find(prevVec==0 & vec==1);   % indices in 1..nRead
            fallPos = find(prevVec==1 & vec==0);

            % handle rises
            for i = 1:numel(risePos)
                if openStart(b) == 0
                    openStart(b) = startSamp0 + risePos(i);  % store 0-based sample index
                else
                    % a new rise found while previous open exists; treat as restart:
                    % close previous at this rise (best-effort) then start new
                    pulses{b}(end+1, :) = [openStart(b), startSamp0 + risePos(i)];
                    openStart(b) = startSamp0 + risePos(i);
                end
            end

            % handle falls
            for i = 1:numel(fallPos)
                if openStart(b) ~= 0
                    pulses{b}(end+1, :) = [openStart(b), startSamp0 + fallPos(i)];
                    openStart(b) = 0;
                else
                    % fall without open start: ignore
                end
            end
        end
    end

    fclose(fid);

    % if any open starts remain, close them at end of file
    for b = 1:maxBits
        if openStart(b) ~= 0
            pulses{b}(end+1, :) = [openStart(b), nSampTotal];
            openStart(b) = 0;
        end
    end

    % compute stats
    stats = struct();
    for b = 1:maxBits
        pairs = pulses{b};
        if isempty(pairs)
            stats(b).bit = b;
            stats(b).nPulses = 0;
            stats(b).meanDur_s = NaN;
            stats(b).medianDur_s = NaN;
            stats(b).durations_s = [];
        else
            durs = (pairs(:,2) - pairs(:,1)) / sRate;
            stats(b).bit = b;
            stats(b).nPulses = size(pairs,1);
            stats(b).meanDur_s = mean(durs);
            stats(b).medianDur_s = median(durs);
            stats(b).durations_s = durs;
        end
        fprintf('Bit %2d : pulses = %4d, mean dur = %0.4f s, median = %0.4f s\n', ...
                stats(b).bit, stats(b).nPulses, stats(b).meanDur_s, stats(b).medianDur_s);
    end
end
