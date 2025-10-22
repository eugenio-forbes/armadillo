%%% This function will attempt alignment of behavioral data to EEG recording data
%%% using timing of sync pulses logged by behavioral task computer and timing
%%% of the sync pulses within the recording. It handles several issues that may
%%% arise, and uses sync pulse features, to ensure millisecond precision of alignment.
%%% Requires input session information gathered from get_PS_events_info function.

function [alignment_successful, alignment_info] = n00_align_sync_pulses(analysis_directory, session_info, recording_system)

%%% Initialize output
alignment_successful = false;
alignment_info = struct;

warning off;

%%% Get session info
subject          = session_info.subject{:};
task             = session_info.task{:};
session          = session_info.session{:};
inter_burst_time = max(session_info.inter_burst_time);
n_pulses_events  = session_info.n_pulses_events;

%%% Declare directories and files
list_directory         = fullfile(analysis_directory, 'lists');
subject_directory      = fullfile(analysis_directory, 'subject_files', subject);
session_directory      = fullfile(subject_directory, 'behavioral', task, session);
alignment_directory    = fullfile(subject_directory, 'alignment', recording_system, task, session);
split_directory        = fullfile(subject_directory, 'split', recording_system);
nihon_kohden_list_file = fullfile(list_directory, 'nihon_kohden_list.mat');
blackrock_list_file    = fullfile(list_directory, 'blackrock_list.mat');
event_pulses_file      = fullfile(session_directory, 'pulses.csv');

if ~isfolder(alignment_directory)
    mkdir(alignment_directory);
end

%%% Choose and filter recording list corresponding to recording system to be aligned
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

n_recordings = height(recording_list);

%%% Information of recorded channel with sync pulse data
sync_channel_numbers = recording_list.sync_channel_numbers;
recording_folders    = recording_list.session;
file_names           = recording_list.file_name;
file_lengths         = recording_list.n_samples;
sync_sampling_rate   = recording_list.sync_sampling_rate;

%%% Template file name for plots
file_name_holder = fullfile(alignment_directory, '%s');

%%% Read behavioral event pulse times and make them relative to first pulse
events_pulses = read_events_pulses(event_pulses_file);
original_events_pulses = events_pulses.time * 1000;

min_events_pulses = min(original_events_pulses);
relative_events_pulses = original_events_pulses - min_events_pulses;

%%% Initialize variables to get information about recording pulses
sync_recordings  = cell(n_recordings, 1);
pulse_starts     = cell(n_recordings, 1);
pulse_finishes   = cell(n_recordings, 1);
n_pulse_starts   = NaN(n_recordings, 1);
n_pulse_finishes = NaN(n_recordings, 1);

%%% Detect recording pulses and gather information
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
    
        file_id = fopen(sync_file_name, 'rb');
        sync_recordings{idx} = fread(file_id, file_length, 'int16');
        fclose(file_id);

        if sync_sampling_rate(idx) ~= 1000 %Hz
            sync_recordings{idx} = downsample(sync_recordings{idx}, sampling_ratio);
        end

        threshold = max(0.5, (0.6 * max(vertcat(sync_recordings{idx})));
        threshold_pass = vertcat(sync_recordings{idx}) > threshold;
        
        differential = diff([0; threshold_pass; 0]);

        pulse_starts{idx} = find(differential == 1);
        pulse_finishes{idx} = find(differential == -1);
        
        n_pulse_starts(idx) = length(pulse_starts{idx});
        n_pulse_finishes(idx) = length(pulse_finishes{idx});
    
    end
    
end

%%% Make recording pulse times relative to first pulse
min_pulse_start = min(pulse_starts{1});

relative_recording_pulse_starts = cellfun(@(x) x - min_pulse_start, pulse_starts, 'UniformOutput', false);
relative_recording_pulse_finishes = cellfun(@(x) x - min_pulse_start, pulse_finishes, 'UniformOutput', false);

recording_starts = zeros(n_recordings, 1);
recording_ends = file_lengths - min_pulse_start;

time_differences = zeros(n_recordings, 1);

if length(file_names) > 1
    
    for idx = 2:length(file_names)
    
        switch recording_system
            case 'nihon_kohden'
                time_differences(idx) = milliseconds(recording_list.start_time{idx} - recording_list.start_time{1});
        
            case 'blackrock'
                time_differences(idx) = sum(recording_list.n_samples(1:idx - 1));
        end

        recording_starts(idx) = time_differences(idx) - min_pulse_start;
        recording_ends(idx) = recording_ends(idx) + time_differences(idx);
        
        relative_recording_pulse_starts{idx} = relative_recording_pulse_starts{idx} + time_differences(idx);
        relative_recording_pulse_finishes{idx} = relative_recording_pulse_finishes{idx} + time_differences(idx);
    
    end

end

recording_pulses = vertcat(relative_recording_pulse_starts{:});
n_pulses_recording = length(recording_pulses);

%%% Get timespan of events and recording pulses
timespan_events = relative_events_pulses(end) - relative_events_pulses(1);
timespan_recording = recording_pulses(end) - recording_pulses(1);
timespan_mismatch = timespan_events ~= timespan_recording;
timespan_error = timespan_recording - timespan_events;

%%% Label pulses: green for bursts, red for breaks (long absence of pulses), blue for neither (regular pulses).
%%% This helps identify pulse burst or breaks that are present in one set of pulses, but not the other.
plot_file = sprintf(file_name_holder, '1-labeled-bursts-breaks');
pulse_info = label_bursts_breaks(plot_file, relative_events_pulses, recording_pulses, recording_starts, recording_ends, time_differences, inter_burst_time, true);

%%% Plot a colored gradient (each pulse gets a unique color based on elapsed time from previous pulse)
%%% This helps visually identify mismatch of pulses.
plot_file = sprintf(file_name_holder, '1-colored-gradient');
if ~isfile(plot_file)
    plot_colored_gradients(plot_file, relative_events_pulses, recording_pulses);
end

%%% Plot the pulse time differentials of matched number of starting pulses
%%% This helps identify missing pulses from differences of time elapsed between them
%%% and differential ratios between events and recording pulses significantly different from 1.
plot_file = sprintf(file_name_holder, '1-differentials-before');
if ~isfile(plot_file)
    plot_differentials(plot_file, relative_events_pulses, recording_pulses);
end

%%% Sync pulse burst info
n_bursts_events           = pulse_info.n_bursts_events;
burst_n_pulses_events     = pulse_info.burst_n_pulses_events;
n_bursts_recording        = pulse_info.n_bursts_recording;
burst_n_pulses_recording  = pulse_info.burst_n_pulses_recording;

%%% Sync pulse break info
n_breaks_events           = pulse_info.n_breaks_events;
n_breaks_recording        = pulse_info.n_breaks_recording;

%%% Information about blocks of regular pulses separated by breaks
n_blocks_events           = pulse_info.n_blocks_events;
block_starts_events       = pulse_info.block_starts_events;
block_ends_events         = pulse_info.block_ends_events;
block_timespans_events    = pulse_info.block_timespans_events;
n_blocks_recording        = pulse_info.n_blocks_recording;
block_starts_recording    = pulse_info.block_starts_recording;
block_ends_recording      = pulse_info.block_ends_recording;
block_timespans_recording = pulse_info.block_timespans_recording;

%%% New sync pulses explanation:
%%% - Sync pulses are sent continuously with a normally distributed
%%% interpulse interval with mean of 5 seconds and standard deviation of
%%% 300 ms. That way there are not too many pulses, while conserving the
%%% benefit of being able to more accurately identify slow drift error
%%% increments in computer time for any intervening events.
%%% - If the task code execution ends in the intended manner there will
%%% always be one burst of pulses at the end of session. 
%%% This would make it easier to identify whether there is more than one
%%% session in a single recording, and allow for matching to one of the
%%% sessions. Would make the code simpler since only have to check for
%%% burst at the end, and try to zip the pulses from end to start.
%%% - The distribution of interpulse intervals means that the chances that
%%% there are no pulses within a 7.5s interval are less than 1 in 15
%%% trillion. Used to identify breaks in the EEG or computer time glitches
%%% in events.

%%% List of bad things that could happen to pulses
%%% 1) Session starts before recording is started (or missing split EEG at
%%% start?)
%%% 2) Task code execution ends without delivery of pulse burst (or missing
%%% split EEG at end?)
%%% 3) Multiple behavioral sessions in one recording set
%%% 4) Automatically split recordings (with seconds of missing intervening data).

%%% Signs to help in fixing individual problems or simple combinations.
%%% More complex combinations would need to be taken care of manually if
%%% necessary.
n_pulses_match = n_pulses_events == n_pulses_recording;
n_blocks_match = n_blocks_events == n_blocks_recording;

%%% Handling of potentially missing data or multiple sessions in one recording set.
if ~n_blocks_match
    
    if n_blocks_events > n_blocks_recording
        
        if ~n_pulses_match
            
            if n_pulses_events > n_pulses_recording
                fprintf('Did not align %s %s %s. Potentially missing recording data.', subject, task, session);
            else
                fprintf('Did not align %s %s %s. Complex case of greater events blocks and lesser events pulses.', subject, task, session);
            end
            
            %%% Returning will return alignment success as false and alignment info as an empty struct
            return
        
        end
    
    else %%% Potential case of multiple sessions in same recording set. Attempting block selection
        
        bad_recording_blocks = false(n_recording_blocks, 1);
        
        for idx = 1:n_recording_blocks
        
            block_timespan_differences = block_timespans_events - block_timespans_recording(idx);
        
            close_differences = abs(block_timespan_differences) < 8000;
        
            bad_recording_blocks(idx) = ~any(close_differences);
        
        end
        
        if any(bad_recording_blocks)
        
            bad_recording_pulses = false(n_pulses_recording, 1);
            n_bad_blocks_recording = sum(bad_recording_blocks);
            bad_block_indices = find(bad_recording_blocks);
            
            for idx = 1:n_bad_blocks_recording
            
                block_start = block_starts_recording(bad_block_indices(idx));
                block_end = block_ends_recording(bad_block_indices(idx));
                bad_recording_pulses(block_start:block_end) = true;
                
            end
            
            recording_pulses(bad_recording_pulses) = [];
            n_pulses_recording = length(recording_pulses);
            
            n_pulses_match = n_pulses_events == n_pulses_recording;
            
            block_starts_recording(bad_recording_blocks) = [];
            block_ends_recording(bad_recording_blocks) = [];
            
            n_blocks_recording = n_blocks_recording < n_bad_blocks_recording;
        
        end
    
    end

end

%%% Handling of missing/extra detections

if ~n_pulses_match

    if n_pulses_events > n_pulses_recording
    
        bad_pulses_events = find_bad_pulses(relative_events_pulses, recording_pulses);
        relative_events_pulses(bad_pulses_events) = [];
        original_events_pulses(bad_pulses_events) = [];
        
    elseif n_pulses_events < n_pulses_recording
    
        bad_pulses_recording = find_bad_pulses(recording_pulses, relative_events_pulses);
        recording_pulses(bad_pulses_recording) = [];
        
    end
    
end

%%% Label matched pulses and plot
plot_file = sprintf(file_name_holder, '2-matched-labeled-pulses');
if ~isfile(plot_file)
    pulse_info = label_bursts_breaks(plot_file, relative_events_pulses, recording_pulses, recording_starts, recording_ends, time_differences, inter_burst_time, false);
end

%%% Plot matched pulses colored gradients
plot_file = sprintf(file_name_holder, '2-matched-colored-gradients');
if ~isfile(plot_file)
    plot_colored_gradients(plot_file, relative_events_pulses, recording_pulses);
end

%%% Plot differentials of matched pulses
plot_file = sprintf(file_name_holder, '2-differentials-after');
if ~isfile(plot_file)
    plot_differentials(plot_file, relative_events_pulses, recording_pulses);
end

%%% Plot matched pulse pairs with x axis being event time and y axis being recording time
%%% Should be a straight line
plot_file = sprintf(file_name_holder, '3-corresponding-pulses');
if ~isfile(plot_file)
    plot_corresponding(plot_file, relative_events_pulses, recording_pulses);
end

%%% Handling of missing data of automatically split recordings
if n_recordings > 1
    bad_events_pulses = remove_pulses_between_split_recordings(relative_events_pulses, recording_pulses, pulse_info, recording_starts, recording_ends);
    relative_events_pulses(bad_events_pulses) = [];
    original_events_pulses(bad_events_pulses) = [];
end

%%% Gather alignment results of matched pulses
pulse_start_mismatch = any(relative_events_pulses ~= recording_pulses);
pulse_start_error = mean(recording_pulses - relative_events_pulses);

coefficients = polyfit(relative_events_pulses, recording_pulses, 1);

slope = coefficients(1);
intercept = coefficients(2);

fitted_pulse_starts = round(polyval(coefficients, relative_events_pulses));

R = corrcoef(recording_pulses, fitted_pulse_starts);
R_squared = R(1, 2)^2;

n_pulses_match = n_pulses_events == n_pulses_recording;
n_bursts_match = n_bursts_events == n_bursts_recording;
n_breaks_match = n_breaks_events == n_breaks_recording;
n_blocks_match = n_blocks_events == n_blocks_recording;

%%% Save all pulse data and alignment results in struct

alignment_info.original_events_pulses   = original_events_pulses;
alignment_info.relative_events_pulses   = relative_events_pulses;
alignment_info.recording_pulses         = recording_pulses;
alignment_info.time_differences         = time_differences;
alignment_info.min_pulse_start          = min_pulse_start;
alignment_info.recording_starts         = recording_starts;
alignment_info.recording_ends           = recording_ends;
alignment_info.pulse_info               = pulse_info;
alignment_info.n_pulses_events          = n_pulses_events;
alignment_info.n_pulses_recording       = n_pulses_recording;
alignment_info.n_bursts_events          = n_bursts_events;
alignment_info.n_bursts_recording       = n_bursts_recording;
alignment_info.burst_n_pulses_events    = burst_n_pulses_events;
alignment_info.burst_n_pulses_recording = burst_n_pulses_recording;
alignment_info.n_breaks_events          = n_breaks_events;
alignment_info.n_breaks_recording       = n_breaks_recording;
alignment_info.n_blocks_events          = n_blocks_events;
alignment_info.n_blocks_recording       = n_blocks_recording;
alignment_info.block_starts_events      = block_starts_events;
alignment_info.block_ends_events        = block_ends_events;
alignment_info.block_starts_recording   = block_starts_recording;
alignment_info.block_ends_recording     = block_ends_recording;
alignment_info.n_pulses_match           = n_pulses_match;
alignment_info.n_bursts_match           = n_bursts_match;
alignment_info.n_breaks_match           = n_breaks_match;
alignment_info.n_blocks_match           = n_blocks_match;
alignment_info.timespan_events          = timespan_events;
alignment_info.timespan_recording       = timespan_recording;
alignment_info.timespan_mismatch        = timespan_mismatch;
alignment_info.timespan_error           = timespan_error;
alignment_info.pulse_start_mismatch     = pulse_start_mismatch;
alignment_info.pulse_start_error        = pulse_start_error;
alignment_info.slope                    = slope;
alignment_info.intercept                = intercept;
alignment_info.R2                       = R_squared;

alignment_successful = true;

save(fullfile(alignment_directory, 'alignment_info.mat'), 'alignment_info');

end