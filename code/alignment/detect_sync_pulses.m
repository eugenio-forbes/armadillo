%%% This function loads a given session's sync recordings,
%%% sets a threshold for sync pulse detection, and counts
%%% number of sync pulses. Updates and returns input session
%%% list table rows.

function session_info = detect_sync_pulses(root_directory, session_info, recording_system)

%%% Get session info
subject = session_info.subject{:};

%%% Declare directories and files
list_directory         = fullfile(root_directory, 'lists');
subject_directory      = fullfile(root_directory, 'subject_files', subject);
split_directory        = fullfile(subject_directory, 'split', recording_system);
nihon_kohden_list_file = fullfile(list_directory, 'nihon_kohden_list.mat');
blackrock_list_file    = fullfile(list_directory, 'blackrock_list.mat');

%%% Choose and filter appropriate recording list to access sync recording
switch recording_system
    case 'blackrock'
        recording_IDs = session_info.blackrock_IDs{:};
        recording_list = load(blackrock_list_file, 'blackrock_list');
        recording_list = recording_list.blackrock_list;

    case 'nihon_kohden'
        recording_IDs = session_info.nihon_kohden_IDs{:};
        recording_list = load(nihon_kohden_list_file, 'nihon_kohden_list');
        recording_list = recording_list.nihon_kohden_list;
end

recording_list(~ismember(recording_list.recording_ID, recording_IDs), :) = [];

%%% Information from recording to extract sync pulses
sync_channel_numbers = recording_list.sync_channel_numbers;
recording_folders    = recording_list.session;
file_names           = recording_list.file_name;
file_lengths         = recording_list.n_samples;
sync_sampling_rate   = recording_list.sync_sampling_rate;

%%% Initialize variables with information to be gathered from sync pulse recordings
n_recordings = height(recording_list);

sync_channel_used = NaN(n_recordings, 1);
sync_recordings   = cell(n_recordings, 1);
pulse_starts      = cell(n_recordings, 1);
pulse_finishes    = cell(n_recordings, 1);
n_pulse_starts    = zeros(n_recordings, 1);
n_pulse_finishes  = zeros(n_recordings, 1);

%%% Detect recording pulses for each recording
for idx = 1:n_recordings

    sync_count = 1;
    
    recording_folder = recording_folders{idx};
    if strcmp(recording_system, 'nihon_kohden')
        recording_folder = append('PS_', recording_folder);
    end
    
    file_name = file_names{idx};
    sync_file_template = fullfile(split_directory, recording_folder, [file_name, '.%03d']);
    
    file_length = file_lengths(idx);
    sync_channels = sync_channel_numbers{idx};
    
    if sync_sampling_rate(idx) ~= 1000 %Hz
        sampling_ratio = sync_sampling_rate / 1000;
        file_length = file_length * sampling_ratio;
    end

    file_exists = false;
    while ~file_exists && sync_count <= length(sync_channels)
        sync_file_name = sprintf(sync_file_template, sync_channels(sync_count));
        file_exists = isfile(sync_file_name);
        sync_count = sync_count + 1;
    end
    
    if file_exists
    
        sync_channel_used(idx) = sync_channels(sync_count - 1);
        
        file_id = fopen(sync_file_name, 'rb');
        sync_recordings{idx} = fread(file_id, file_length, 'int16');
        fclose(file_id);

        if sync_sampling_rate(idx) ~= 1000 %Hz
            sync_recordings{idx} = downsample(sync_recordings{idx}, sampling_ratio);
        end

        threshold = max(0.5, 0.6 * max(vertcat(sync_recordings{idx})));
        threshold_pass = vertcat(sync_recordings{idx}) > threshold;
        differential = diff([0; threshold_pass; 0]);

        pulse_starts{idx} = find(differential == 1);
        pulse_finishes{idx} = find(differential == -1);
        n_pulse_starts(idx) = length(pulse_starts{idx});
        n_pulse_finishes(idx) = length(pulse_finishes{idx});
        
    end
    
end

%%% Add sync pulse information to session information table rows to be returned
session_info.(['n_pulses_', recording_system]) = {n_pulse_starts};
session_info.([recording_system, '_sync_channels']) = {sync_channel_used};

end