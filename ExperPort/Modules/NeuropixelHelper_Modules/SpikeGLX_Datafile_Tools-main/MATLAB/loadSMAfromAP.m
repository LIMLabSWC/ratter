function DemoReadSync_IMEC()

    % Ask user for binary file
    [binName, path] = uigetfile('*.bin', 'Select .ap.bin File');
    if isequal(binName,0), return; end

    % Parse corresponding .meta file
    meta = SGLX_readMeta.ReadMeta(binName, path);

    % Sampling rate
    sRate = SGLX_readMeta.SampRate(meta);

    % Read first 2 seconds of data
    nSamp = floor(2.0 * sRate);
    dataArray = SGLX_readMeta.ReadBin(0, nSamp, meta, binName, path);

    % --- Channel indices ---
    nSavedChans = str2double(meta.nSavedChans);  % should be 385
    syncCh = nSavedChans;                        % last channel is sync
    apCh = 1;                                    % example: channel 1 (first electrode)

    % Gain-correct AP channel
    apData = SGLX_readMeta.GainCorrectIM(dataArray(apCh,:), apCh, meta);

    % Sync channel (already digital, no gain correction)
    syncData = dataArray(syncCh,:);

    % --- Plot ---
    figure;
    subplot(2,1,1);
    plot((0:nSamp-1)/sRate, 1e6*apData);
    xlabel('Time (s)');
    ylabel('Voltage (uV)');
    title('AP channel 1');

    subplot(2,1,2);
    plot((0:nSamp-1)/sRate, syncData);
    xlabel('Time (s)');
    ylabel('Sync (raw)');
    title('Sync channel');

end
