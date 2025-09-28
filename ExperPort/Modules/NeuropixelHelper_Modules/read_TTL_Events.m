% This script demonstrates how to load and analyze TTL event data from an
% Open Ephys recording session saved in the binary (.npy) format.
%
% PRE-REQUISITES:
% 1. The 'npy-matlab' library must be downloaded from GitHub:
%    https://github.com/kwikteam/npy-matlab
% 2. The path to the 'npy-matlab' folder must be added to your MATLAB path.
%    e.g., addpath('C:\path\to\npy-matlab\npy-matlab')

clear; clc; close all;

%% --- User-Defined Parameters ---

% 1. Set the path to the folder containing your TTL event files.
%    This is typically a path like:
%    ...\<recording_folder>\events\Rhythm_FPGA-100.0\TTL_1
% ttl_folder_path = ['C:\Ephys_Experiment_Data\sound_cat_rat\rawdata\sub-002_id-LP12_expmtr-lida\ses-01_date-20250707T151043_dtype-ephys\ephys\2025-07-07_15-11-36\Record Node 101\experiment1\recording2...' ...
    % '\events\Neuropix-PXI-100.ProbeA\TTL'];

    ttl_folder_path = ['C:\Ephys_Experiment_Data\sound_cat_rat\rawdata\sub-003_id-LP12_expmtr-lida\ses-20_date-20250812T124748_dtype-ephys\ephys\2025-08-12_12-58-23\Record Node 101\experiment1\recording1\events\Neuropix-PXI-100.ProbeA-LFP\TTL'];
% 2. Define which TTL channel you want to analyze.
%    (e.g., channel 1, 2, 3, etc.)
channel_to_analyze = 1;


%% --- Check for Required Files and Library ---

% Verify that the npy-matlab library function exists
if ~exist('readNPY.m', 'file')
    error(['The ''readNPY.m'' function was not found. ' ...
           'Please ensure the npy-matlab library is downloaded ' ...
           'and added to your MATLAB path.']);
end

% Construct the full file paths
timestamps_file = fullfile(ttl_folder_path, 'timestamps.npy');
states_file = fullfile(ttl_folder_path, 'states.npy');

% Verify that the data files exist
if ~exist(timestamps_file, 'file') || ~exist(states_file, 'file')
    error('Could not find "timestamps.npy" or "states.npy" in the specified folder: %s', ttl_folder_path);
end


%% --- Load the Data using readNPY ---

fprintf('Loading data from: %s\n', ttl_folder_path);

try
    % readNPY will read the .npy file and convert it into a MATLAB array.
    % The data types are handled automatically.
    timestamps = readNPY(timestamps_file); % Timestamps in seconds
    channel_states = readNPY(states_file); % Channel state changes (+/- channel number)
    
    fprintf('Successfully loaded %d events.\n', length(timestamps));
    
catch ME
    error('Failed to read .npy files. Error details: %s', ME.message);
end


%% --- Analyze and Extract Specific Events ---

% Find the indices of all events related to the channel of interest.
% We are interested in both rising edges (ON state, positive number) and
% falling edges (OFF state, negative number).
indices_for_channel = find(abs(channel_states) == channel_to_analyze);

if isempty(indices_for_channel)
    fprintf('No events found for TTL channel %d.\n', channel_to_analyze);
    return;
end

% Extract the specific timestamps and states for our channel
channel_timestamps = timestamps(indices_for_channel);
channel_specific_states = channel_states(indices_for_channel);

% --- Find Rising Edges (Pulse Starts) ---
% A rising edge corresponds to a positive channel number in the states array.
rising_edge_indices = find(channel_specific_states > 0);
rising_edge_timestamps = channel_timestamps(rising_edge_indices);

% --- Find Falling Edges (Pulse Ends) ---
% A falling edge corresponds to a negative channel number.
falling_edge_indices = find(channel_specific_states < 0);
falling_edge_timestamps = channel_timestamps(falling_edge_indices);

fprintf('Found %d rising edges (pulse starts) for channel %d.\n', ...
        length(rising_edge_timestamps), channel_to_analyze);
fprintf('Found %d falling edges (pulse ends) for channel %d.\n', ...
        length(falling_edge_timestamps), channel_to_analyze);


%% --- Visualization ---

figure('Name', 'TTL Event Analysis', 'NumberTitle', 'off', 'Color', 'w');
hold on;
grid on;

% Plot all events for the specified channel as vertical lines
% Green for ON (rising edge), Red for OFF (falling edge)
for i = 1:length(rising_edge_timestamps)
    plot([rising_edge_timestamps(i), rising_edge_timestamps(i)], [0, 1], 'g-', 'LineWidth', 1.5);
end

for i = 1:length(falling_edge_timestamps)
    plot([falling_edge_timestamps(i), falling_edge_timestamps(i)], [0, 1], 'r--', 'LineWidth', 1.5);
end

% Make the plot informative
title(sprintf('TTL Events for Channel %d', channel_to_analyze));
xlabel('Time (seconds)');
ylabel('Event');
ylim([-0.1, 1.1]);
set(gca, 'YTick', [0, 1], 'YTickLabel', {'OFF', 'ON'});
legend({'Rising Edge (ON)', 'Falling Edge (OFF)'}, 'Location', 'best');

fprintf('Plot generated successfully.\n');

%% 
