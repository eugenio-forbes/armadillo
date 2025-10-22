function alignment_info = n00_align_pulses(root_directory,session_info,recording_system)
warning off;
%%% Get session info
subject = session_info.subject;
task = session_info.task;
session = session_info.session;
n_event_pulses = session_info.n_event_pulses;

%%% List directories
list_directory = fullfile(root_directory,'lists');
resources_directory = fullfile(root_directory,'resources');
subject_directory = fullfile(root_directory,'subject_files',subject);
session_directory = fullfile(subject_directory,'behavioral',task,session);
data_directory = strrep(session_directory,'data');
alignment_directory = fullfile(subject_directory,'alignment',recording_system,task,session);
split_directory = fullfile(subject_directory,'split',recording_system);

nihon_kohden_list_file = fullfile(list_directory,'nihon_kohden_list.mat');
blackrock_list_file = fullfile(list_directory,'blackrock_list.mat');
event_pulses_file = fullfile(session_folder,'pulses.csv');

%%% Choose and filter appropriate recording list for recording system to be
%%% aligned
switch recording_system
    case 'blackrock'
        recording_IDs = session_info.blackrock_IDs{:};
        recording_list = load(blackrock_list_file,'blackrock_list');
        sync_sampling_rates = recording_list.sampling_rate;
    case 'nihon_kohden'
        recording_IDs = session_info.nihon_kohden_IDs{:};
        recording_list = load(nihon_kohden_list_file,'nihon_kohden_list');
end
recording_list(~ismember(recording_list.recording_ID,recording_IDs),:) = [];
n_recordings = height(recording_list);
sync_channel_numbers = recording_list.sync_channel_numbers;
session_folders = recording_list.session;
file_names = recording_list.file_name;
file_lengths = recording_list.n_samples;

%%% Variables for alignment info
no_pulses_file = false;
no_sync_signal = false;
n_event_pulses = NaN;
n_pulses_recording = NaN;
n_pulse_starts = {[]};
matched_starts = false;
equal_n_pulses = false;
good_ratios = false;
bad_idx = {[]};
n_bursts_events = NaN;
n_bursts_recording = NaN;
burst_n_pulses_events = {[]};
burst_n_pulses_recording = {[]};
n_bursts_mismatch = false;
n_breaks_events = NaN;
n_breaks_recording = NaN;
n_breaks_mismatch = false;
timespan_events = NaN;
timespan_recording = NaN;
timespan_mismatch = false;
timespan_error = 0;
pulse_start_mismatch = false;
pulse_start_error = 0;
offset_mismatch = false;
mean_offset_error = 0;
offset_error = {[]};
slope = 0;
intercept = 0;
R_squared = 0;

%%% To sprintf plot_type into file_name_holder
file_name_holder = fullfile(alignment_directory,'%s');

%%% Read event pulses
event_pulses = read_event_pulses(event_pulses_file);
event_pulses = event_pulses.time*1000;

modified_offset = event_pulses;
time_difference = zeros(n_recordings,1);
if length(file_names) > 1
    for idx = 2:length(file_names)
        time_difference(idx) = milliseconds(recording_list.start_time{idx} - recording_list.start_time{idx-1});
    end
end

min_pulses = min(event_pulses);
relative_event_pulses = event_pulses - min_pulses;

sync_recordings = cell(n_recordings,1);
pulse_starts = cell(n_recordings,1);
pulse_finishes = cell(n_recordings,1);
n_pulse_starts = NaN(n_recordings,1);
n_pulse_finishes = NaN(n_recordings,1);

for idx = 1:n_recordings
    sync_count = 1;
    session_folder = session_folders{idx};
    file_name = file_names{idx};
    sync_file_template = fullfile(split_directory,session_folder,[file_name,'.%03d']);
    file_length = file_lengths(idx);
    sync_channels = sync_channel_numbers{idx};
    file_exists = false;
    while ~file_exists && sync_count <= length(sync_channels)
        sync_file_name = sprintf(sync_file_template,sync_channels(sync_count));
        file_exists = isfile(sync_file_name);
        sync_count = sync_count + 1;
    end
    if file_exists
        file_id = fopen(sync_file_name,'rb');
        sync_recordings{idx} = fread(file_id,file_length,'int16');
        fclose(file_id);

        threshold = 0.6*max(vertcat(sync_recordings{idx}));
        threshold_pass = vertcat(sync_recordings{idx}) > threshold;
        differential = diff([0;threshold_pass;0]);

        pulse_starts{idx} = find(differential == 1);
        pulse_finishes{idx} = find(differential == -1);
        n_pulse_starts(idx) = length(pulse_starts{idx});
        n_pulse_finishes(idx) = length(pulse_finishes{idx});
        fprintf('%d pulses,\n',n_pulse_starts(idx))
    end
end

min_pulse_start = min(pulse_starts{1});
relative_pulse_starts = cellfun(@(x) x - min_pulse_start,pulse_starts,'UniformOutput',false);
relative_pulse_finishes = cellfun(@(x) x - min_pulse_start,pulse_finishes,'UniformOutput',false);
modified_offset = modified_offset - min_pulse_start;
eeg_starts = zeros(n_recordings,1);
eeg_ends = file_lengths-min_pulse_start;

if length(file_names) > 1
    for idx = 2:length(file_names)
        time_difference = milliseconds(eeg_dates{idx} - eeg_dates{1});
        eeg_starts(idx) = time_difference - min_pulse_start;
        eeg_ends(idx) = eeg_ends(idx) + time_difference;
        relative_pulse_starts{idx} = relative_pulse_starts{idx} + time_difference;
        relative_pulse_finishes{idx} = relative_pulse_finishes{idx} + time_difference;
    end
end

matched_starts = sum(n_pulse_starts == n_pulse_finishes) == n_recordings;
n_pulse_starts = n_pulse_starts;

eeg_pulses = vertcat(relative_pulse_starts{:});
n_pulses_recording = length(eeg_pulses);
all_pulse_ends = vertcat(relative_pulse_finishes{:});
pulse_widths = all_pulse_ends - eeg_pulses;


equal_n_pulses = n_event_pulses == n_pulses_recording;

if ~equal_n_pulses

    plot_file = sprintf(file_name_holder,'1-labeled-blocks');
    pulse_info = label_pulses(plot_file,event_pulses,eeg_pulses,eeg_starts,eeg_ends,do_plots);

    block_starts_events = pulse_info.block_starts_events;
    block_ends_events = pulse_info.block_starts_events;
    block_starts_eeg = pulse_info.block_starts_eeg;
    block_ends_eeg = pulse_info.block_ends_eeg;
    test_starts_eeg = pulse_info.test_starts_eeg;

    pulse_info = label_pulses('update_no_plot',event_pulses,eeg_pulses,eeg_starts,eeg_ends,false);
    [event_pulses,relative_event_pulses] = adjust_clock_stop(event_pulses,relative_event_pulses,eeg_pulses,pulse_info);

    if n_recordings >1
        pulse_info = label_pulses('update_no_plot',event_pulses,eeg_pulses,eeg_starts,eeg_ends,false);
        event_pulses = remove_pulses_between_split_eeg(event_pulses,eeg_pulses,pulse_info,eeg_starts,eeg_ends);
    end

    n_event_pulses = length(event_pulses);
    n_pulses_recording = length(eeg_pulses);

    if n_event_pulses ~= n_pulses_recording
        plot_file = sprintf(file_name_holder,'2-block-crosscorrelation');
        pulse_info = label_pulses('update_no_plot',event_pulses,eeg_pulses,eeg_starts,eeg_ends,false);
        [event_pulses,eeg_pulses] = block_crosscorrelation(plot_file,event_pulses,eeg_pulses,pulse_info);
    end

    plot_file = sprintf(file_name_holder,'3-matched-labeled-blocks');
    pulse_info = label_pulses(plot_file,event_pulses,eeg_pulses,eeg_starts,eeg_ends,do_plots);

    n_bursts_events = pulse_info.n_pulse_tests_events;
    n_bursts_recording = pulse_info.n_pulse_tests_eeg;
    n_bursts_mismatch = n_bursts_recording ~= n_bursts_events;

    n_breaks_events = pulse_info.n_breaks_events;
    n_breaks_recording = pulse_info.n_breaks_eeg;
    n_breaks_mismatch = n_breaks_recording ~= n_breaks_events;

    block_starts_events = pulse_info.block_starts_events;
    block_ends_events = pulse_info.block_ends_events;

    block_starts_eeg = pulse_info.block_starts_eeg;
    block_ends_eeg = pulse_info.block_ends_eeg;

    n_event_pulses = length(event_pulses);
    n_pulses_recording = length(eeg_pulses);

    n_pulses_recording = length(eeg_pulses);
    n_event_pulses = length(event_pulses);

    if do_plots
        plot_file = sprintf(file_name_holder,'1-colored-gradients');
        plot_colored_gradients(plot_file,event_pulses,eeg_pulses);

        plot_file = sprintf(file_name_holder,'3-differentials-before');
        plot_differentials(plot_file,event_pulses,eeg_pulses);
    end

    if n_event_pulses > n_pulses_recording
        bad_pulses_events = find_bad_pulses(event_pulses,eeg_pulses);
        event_pulses(bad_pulses_events) = [];
    elseif n_event_pulses < n_pulses_recording
        bad_pulses_eeg = find_bad_pulses(eeg_pulses,event_pulses);
        eeg_pulses(bad_pulses_eeg) = [];
    end

    crosscorrelations = cell(1,1);
    if n_event_pulses > n_pulses_recording
        [bad_pulses_events,crosscorrelations{1}] = crosscorrelate_pulses(event_pulses,eeg_pulses);
        event_pulses(bad_pulses_events) = [];
    else
        [bad_pulses_eeg,crosscorrelations{1}] = crosscorrelate_pulses(eeg_pulses,event_pulses);
        eeg_pulses(bad_pulses_eeg) = [];
    end
    plot_file = sprintf(file_name_holder,'2-session-crosscorrelation');
    plot_crosscorrelation(plot_file,crosscorrelations)
end

if do_plots
    plot_file = sprintf(file_name_holder,'2-matched-colored-gradients');
    plot_colored_gradients(plot_file,event_pulses,eeg_pulses);

    plot_file = sprintf(file_name_holder,'4-differentials-after');
    plot_differentials(plot_file,event_pulses,eeg_pulses);

    plot_file = sprintf(file_name_holder,'5-corresponding-pulses');
    plot_corresponding(plot_file,event_pulses,eeg_pulses);
end

time_ratios = diff(event_pulses)./diff(eeg_pulses);
bad_ratios = time_ratios>1.005 | time_ratios<0.995;
good_ratios = sum(bad_ratios)<= n_recordings-1;
bad_idx = find(bad_ratios,1,'first');

timespan_events = event_pulses(end) - event_pulses(1);
timespan_recording = eeg_pulses(end) - eeg_pulses(1);
timespan_mismatch = timespan_events ~= timespan_recording;
timespan_error =  timespan_recording - timespan_events;

pulse_start_mismatch = any(event_pulses ~= eeg_pulses);
pulse_start_error = mean(eeg_pulses-event_pulses);
coefficients = polyfit(event_pulses,eeg_pulses,1);
slope = coefficients(1);
intercept = coefficients(2);
fitted_pulse_starts = round(polyval(coefficients,event_pulses));
fitted_eegoffset = round(polyval(coefficients,relative_event_pulses));
R = corrcoef(eeg_pulses,fitted_pulse_starts);
R_squared = R(1,2)^2;

if do_plots
    plot_file = sprintf(file_name_holder,'6-mismatch');
    plot_mismatch(plot_file,event_pulses,eeg_pulses,fitted_pulse_starts,relative_event_pulses,modified_offset,fitted_eegoffset,eeg_starts,eeg_ends);
end

[corrected_event_pulses,corrected_event_times] = adjust_computer_time(event_pulses,relative_event_pulses,eeg_pulses);
coefficients = polyfit(corrected_event_pulses,eeg_pulses,1);
fitted_pulse_starts = round(polyval(coefficients,corrected_event_pulses));
fitted_eegoffset = round(polyval(coefficients,corrected_event_times));

if do_plots
    plot_file = sprintf(file_name_holder,'7-corrected');
    plot_mismatch(plot_file,corrected_event_pulses,eeg_pulses,fitted_pulse_starts,corrected_event_times,modified_offset,fitted_eegoffset,eeg_starts,eeg_ends);
end

offset_mismatch = any(modified_offset ~= fitted_eegoffset);
if offset_mismatch
    offset_error = modified_offset-fitted_eegoffset;
    mean_offset_error = mean(offset_error);
end

% fitted_eegoffset = floor(fitted_eegoffset) + min_pulse_start;
% adjusted_fitted_eegoffset = fitted_eegoffset;
% new_eegfile = repelem({''},n_events,1);
% corresponding = fitted_eegoffset >= eeg_starts(1) & fitted_eegoffset <= eeg_ends(1)+min_pulse_start-5000;
% n_corresponding = sum(corresponding);
% new_eegfile(corresponding) = repelem(unique_eegs(1),n_corresponding,1);
% if length(unique_eegs) > 1
%     for idx = 2:length(unique_eegs)
%         time_difference = milliseconds(eeg_dates{idx} - eeg_dates{1});
%         corresponding = fitted_eegoffset >= eeg_starts(idx) + min_pulse_start & fitted_eegoffset <= eeg_ends(idx) + min_pulse_start-5000;
%         adjusted_fitted_eegoffset(corresponding) = fitted_eegoffset(corresponding) - time_difference;
%         new_eegfile(corresponding) = repelem(unique_eegs(idx),sum(corresponding),1);
%     end
% end
% out_of_bounds = strcmp(new_eegfile,'') | adjusted_fitted_eegoffset <= 0;

writematrix(corrected_event_pulses,new_pulses_file);

alignment_info = struct;
alignment_info.no_pulses_file = no_pulses_file;
alignment_info.no_sync_signal = no_sync_signal;

alignment_info.n_pulses_events = n_event_pulses;
alignment_info.n_pulses_eeg = n_pulses_recording;

alignment_info.n_pulse_starts = n_pulse_starts;

alignment_info.n_pulse_tests_events = n_bursts_events;
alignment_info.n_pulse_tests_eeg = n_bursts_recording;
alignment_info.test_n_pulses_events = burst_n_pulses_events;
alignment_info.test_n_pulses_eeg = burst_n_pulses_recording;

alignment_info.block_starts_events = block_starts_events;
alignment_info.block_ends_events = block_ends_events;
alignment_info.block_starts_eeg = block_starts_eeg;
alignment_info.block_ends_eeg = block_ends_eeg;
alignment_info.n_breaks_events = n_breaks_events;
alignment_info.n_breaks_eeg = n_breaks_recording;
alignment_info.bad_idx = bad_idx;

alignment_info.matched_starts = matched_starts;
alignment_info.n_pulse_tests_mismatch = n_bursts_mismatch;
alignment_info.n_breaks_mismatch = n_breaks_mismatch;
alignment_info.equal_n_pulses = equal_n_pulses;
alignment_info.good_ratios = good_ratios;
alignment_info.eegoffset_mismatch = offset_mismatch;
alignment_info.mean_eegoffset_error = mean_offset_error;
alignment_info.offset_error = offset_error;
alignment_info.timespan_events = timespan_events;
alignment_info.timespan_eeg = timespan_recording;
alignment_info.timespan_mismatch = timespan_mismatch;
alignment_info.timespan_error = timespan_error;
alignment_info.pulse_start_mismatch = pulse_start_mismatch;
alignment_info.pulse_start_error = pulse_start_error;

alignment_info.slope = slope;
alignment_info.intercept = intercept;
alignment_info.R2 = R_squared;

save(fullfile(alignment_directory,'alignment_info.mat'),'alignment_info');
end