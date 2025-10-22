function alignment_table = check_alignment(varargin)
if isempty(varargin)
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder = 'armadillo';
    alignment_type = 'NK'; %NK or BR
    sampling_rate = 1000; %HZ
    do_plot_mismatch = true;
    do_plot_labeled_pulses = true;
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder = varargin{3};
    alignment_type = varargin{4};
    sampling_rate = varargin{5};
    do_plot_mismatch = varargin{6};
    do_plot_labeled_pulses = varargin{7};
end

analysis_directory = fullfile(root_directory, username, analysis_folder);
subject_directory = fullfile(analysis_directory, 'subject_files');
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');
plot_directory = fullfile(analysis_directory, 'plots/alignment');

if ~isfolder(plot_directory)
    mkdir(plot_directory);
end

sync_channels = [259, 258, 130, 129];

load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'events_info.mat'), 'events_info');
n_sessions = height(session_list);

n_blocks_session = NaN(n_sessions, 1);
n_recordings = NaN(n_sessions, 1);
block_n_eegs = cell(n_sessions, 1);

no_pulses_file = false(n_sessions, 1);
no_sync_signal = false(n_sessions, 1);

n_pulses_events = NaN(n_sessions, 1);
n_pulses_eeg = NaN(n_sessions, 1);
n_pulse_starts = cell(n_sessions, 1);
matched_starts = false(n_sessions, 1);
equal_n_pulses = false(n_sessions, 1);

good_ratios = false(n_sessions, 1);
bad_idx = cell(n_sessions, 1);

n_pulse_tests_events = NaN(n_sessions, 1);
n_pulse_tests_eeg = NaN(n_sessions, 1);
test_n_pulses_events = cell(n_sessions, 1);
test_n_pulses_eeg = cell(n_sessions, 1);
n_pulse_tests_mismatch = false(n_sessions, 1);

n_breaks_events = NaN(n_sessions, 1);
n_breaks_eeg = NaN(n_sessions, 1);
n_breaks_mismatch = false(n_sessions, 1);

% n_pulse_blocks_events = NaN(n_sessions, 1);
% n_pulse_blocks_eeg = NaN(n_sessions, 1);
% block_n_pulses_events = cell(n_sessions, 1);
% block_n_pulses_eeg = cell(n_sessions, 1);

timespan_events = NaN(n_sessions, 1);
timespan_eeg = NaN(n_sessions, 1);
timespan_mismatch = false(n_sessions, 1);
timespan_error = zeros(n_sessions, 1);
pulse_start_mismatch = false(n_sessions, 1);
pulse_start_error = zeros(n_sessions, 1);
eegoffset_mismatch = false(n_sessions, 1);
mean_eegoffset_error = zeros(n_sessions, 1);

slope = zeros(n_sessions, 1);
intercept = zeros(n_sessions, 1);
R_squared = zeros(n_sessions, 1);

for idx = 1:n_sessions
    subject = session_list.subject{idx};
    task = session_list.task{idx};
    session = session_list.session{idx};
    is_aligned = events_info.is_aligned(idx);
    session_folder = fullfile(subject_directory, subject, 'behavioral', task, session);
    noreref_folder = fullfile(subject_directory, subject, 'eeg.noreref');
    data_folder = fullfile(data_directory, subject, task, session);
    
    plot_file1 = fullfile(plot_directory, sprintf('%s_%s_%s_autocorrelation', subject, task, session));
    plot_file2 = fullfile(plot_directory, sprintf('%s_%s_%s_labeled-pulses', subject, task, session));
    plot_file3 = fullfile(plot_directory, sprintf('%s_%s_%s_mismatch', subject, task, session));
    plot_file4 = fullfile(plot_directory, sprintf('%s_%s_%s_corrected', subject, task, session));

    events_file = fullfile(data_folder, 'events.mat');
    load(events_file, 'events')
    events = events(contains(events.event, {'ENC', 'RET'}), :);
    n_events = height(events);
    block = events.block;
    unique_blocks = unique(block);
    n_blocks_session(idx) = length(unique_blocks);
    
    if is_aligned
        eegfiles = events.eegfile;
        eegoffset = events.eegoffset;
        empty_eeg = cellfun(@isempty, eegfiles);
        unique_eegs = unique(eegfiles(~empty_eeg & eegoffset >= 0), 'stable');
        eeg_dates = cellfun(@(x) regexp(x, '\d+[A-Za-z]+\d+_\d+$', 'match'), unique_eegs, 'UniformOutput', false);
        eeg_dates = cellfun(@(x) datetime(x, 'InputFormat', 'ddMMMyy_HHmm', 'TimeZone', 'UTC'), eeg_dates, 'UniformOutput', false);
        eegfile = cellfun(@(x) find(strcmp(unique_eegs, x)), eegfiles, 'UniformOutput', false);
        eegfile(empty_eeg) = repelem({0}, sum(empty_eeg), 1);
        eegfile = vertcat(eegfile{:});
        block_n_eegs{idx} = arrayfun(@(x) length(unique(eegfile(block == x & ~empty_eeg))), unique_blocks);
        
        modified_eegoffset = eegoffset;
        if length(unique_eegs) > 1
            for jdx = 2:length(unique_eegs)
                time_difference = milliseconds(eeg_dates{jdx} - eeg_dates{1});
                this_file = eegfile == jdx;
                modified_eegoffset(this_file) = modified_eegoffset(this_file) + time_difference;
            end
        end
        n_recordings(idx) = events_info.n_recordings(idx);
        eeg_file_length = events_info.eeg_file_length{idx};
    elseif contains(task, 'Scopolamine')
        session_number = str2double(session(end));
        file_string = sprintf('%s_AR_Scop_%d*259', subject, session_number);
        eegfiles = dir(fullfile(noreref_folder, file_string));
        size_bytes = [eegfiles.bytes];
        eegfiles = fullfile({eegfiles.folder}, {eegfiles.name});
        eegfiles = strrep(eegfiles, '.259', '');
        unique_eegs = unique(eegfiles);
        eeg_dates = cellfun(@(x) regexp(x, '\d+[A-Za-z]+\d+_\d+$', 'match'), unique_eegs, 'UniformOutput', false);
        eeg_dates = cellfun(@(x) datetime(x, 'InputFormat', 'ddMMMyy_HHmm', 'TimeZone', 'UTC'), eeg_dates, 'UniformOutput', false);
        block_n_eegs{idx} = zeros(1, n_blocks_session(idx));
%         eegfile = zeros(n_events, 1);
%         eegoffset = zeros(n_events, 1);
        modified_eegoffset = zeros(n_events, 1);
        n_recordings(idx) = length(unique_eegs);
        eeg_file_length = size_bytes/2;
    else
        continue
    end
    
    pulses_file1 = fullfile(session_folder, 'pulses.csv');
    pulses_file2 = fullfile(session_folder, 'pulses.txt');
    pulses_file3 = fullfile(session_folder, 'eeg.eeglog.up');

    if isfile(pulses_file1)
        event_pulses = readtable(pulses_file1);
        event_pulses = event_pulses.pulse_time*1000;
    elseif isfile(pulses_file2)
        event_pulses = readcell(pulses_file2);
        event_pulses = vertcat(event_pulses{:});
    elseif isfile(pulses_file3)
        event_pulses = readcell(pulses_file3, 'FileType', 'text');
        if ~isempty(event_pulses)
            event_pulses = vertcat(event_pulses{:, 1});
        else
            no_pulses_file(idx) = true;
            continue
        end
    else
        no_pulses_file(idx) = true;
        continue
    end
    
    min_event_time = min(event_pulses);
    event_pulses = event_pulses - min_event_time;
    event_times = events.mstime-min_event_time;
%     block_starts = arrayfun(@(x) min(event_times(block == x)), unique_blocks);
%     block_ends = arrayfun(@(x) max(event_times(block == x)) + 10000, unique_blocks);
    
    n_pulses_events(idx) = length(event_pulses);
    
%     n_study_blocks= events_info.n_study_blocks(idx);
%     n_test_blocks = events_info.n_test_blocks(idx);
    sync_recordings = cell(n_recordings(idx), 1);
    pulse_starts = cell(n_recordings(idx), 1);
    pulse_finishes = cell(n_recordings(idx), 1);
    n_starts = NaN(n_recordings(idx), 1);
    n_finishes = NaN(n_recordings(idx), 1);
    
    for jdx = 1:n_recordings(idx)
        
        sync_count = 1;
        file_exists = false;
        while ~file_exists && sync_count <= length(sync_channels)
            sync_eeg = [unique_eegs{jdx} sprintf('.%03d', sync_channels(sync_count))];
            file_exists = isfile(sync_eeg);
            sync_count = sync_count + 1;
        end
        
        if file_exists
            
            file_length = eeg_file_length(jdx);
            
            file_id = fopen(sync_eeg, 'rb');
            sync_recordings{jdx} = fread(file_id, file_length, 'int16');
            fclose(file_id);
            
            threshold = 0.6*max(vertcat(sync_recordings{jdx}));
            threshold_pass = vertcat(sync_recordings{jdx}) > threshold;
            differential = diff([0;threshold_pass;0]);
            
            pulse_starts{jdx} = find(differential == 1);
            pulse_finishes{jdx} = find(differential == -1);
            n_starts(jdx) = length(pulse_starts{jdx});
            n_finishes(jdx) = length(pulse_finishes{jdx});
            
        else
            no_sync_signal(idx) = true;
            continue
        end
    end
    
    min_pulse_start = min(pulse_starts{1});
    modified_pulse_starts = cellfun(@(x) x - min_pulse_start, pulse_starts, 'UniformOutput', false);
    modified_pulse_finishes = cellfun(@(x) x - min_pulse_start, pulse_finishes, 'UniformOutput', false);
    modified_eegoffset = modified_eegoffset - min_pulse_start;
    eeg_starts = zeros(n_recordings(idx), 1);
    eeg_ends = eeg_file_length-min_pulse_start;
    
    if length(unique_eegs) > 1
        for jdx = 2:length(unique_eegs)
            time_difference = milliseconds(eeg_dates{jdx} - eeg_dates{1});
            eeg_starts(jdx) = time_difference - min_pulse_start;
            eeg_ends(jdx) = eeg_ends(jdx) + time_difference;
            modified_pulse_starts{jdx} = modified_pulse_starts{jdx} + time_difference;
            modified_pulse_finishes{jdx} = modified_pulse_finishes{jdx} + time_difference;
        end
    end
    
    matched_starts(idx) = sum(n_starts == n_finishes) == n_recordings(idx);
    n_pulses_eeg(idx) = max(sum(n_starts), sum(n_finishes));
    n_pulse_starts{idx} = n_starts;
    
    all_pulse_starts = vertcat(modified_pulse_starts{:});
    
    equal_n_pulses(idx) = n_pulses_events(idx) == sum(n_pulses_eeg(idx));
    
    if ~equal_n_pulses(idx)
        if events_info.subject_ID(idx) > 74
            if do_plot_labeled_pulses
                results = plot_labeled_pulses(plot_file2, event_pulses, all_pulse_starts, eeg_starts, eeg_ends);
            end
            n_pulse_tests_events(idx) = results.n_pulse_tests_events;
            n_pulse_tests_eeg(idx) = results.n_pulse_tests_eeg;
            test_n_pulses_events{idx} = results.test_n_pulses_events;
            test_n_pulses_eeg{idx} = results.test_n_pulses_eeg;
            n_breaks_events(idx) = results.n_breaks_events;
            n_breaks_eeg(idx) = results.n_breaks_eeg;
            n_pulse_tests_mismatch(idx) = n_pulse_tests_eeg(idx) ~= n_pulse_tests_events(idx);
            n_breaks_mismatch(idx) = n_breaks_eeg(idx) ~= n_breaks_events(idx);
            
            %         n_pulse_tests_eeg = NaN(n_sessions, 1);
            %         test_n_pulses_eeg = cell(n_sessions, 1);
            %         n_blocks = NaN(n_sessions, 1);
            %         block_mismatch_events = false(n_sessions, 1);
            %         n_pulse_blocks_events = NaN(n_sessions, 1);
            %         block_n_pulses_events = cell(n_sessions, 1);
            %         n_pulse_blocks_eeg = NaN(n_sessions, 1);
            %         block_n_eegs = cell(n_sessions, 1);
            %         block_n_pulses_eeg = cell(n_sessions, 1);
            %         block_mismatch_eeg = false(n_sessions, 1);
            %
            %         %         differential = diff(time_ratios);
            %         bad_ratios = time_ratios>1.005 & time_ratios<0.995;
            %         good_ratios(idx) = sum(bad_ratios)<= n_recordings(idx)-1;
            %         bad_idx{idx} = find(bad_ratios, 1, 'first');
            %
        else
            n_difference = n_pulses_events(idx) - length(all_pulse_starts);
            if n_difference > 0
                bigger = event_pulses;
                smaller = all_pulse_starts;
            else
                bigger = all_pulse_starts;
                smaller = event_pulses;
            end
            n_bigger = length(bigger);
            difference = abs(n_difference);
            auto_slopes = NaN(difference+1, 1);
            auto_intercepts = NaN(difference+1, 1);
            auto_R_squared = NaN(difference+1, 1);
            for jdx = 1:difference+1
                coefficients = polyfit(bigger(jdx:(n_bigger-difference+jdx-1)), smaller+bigger(jdx), 1);
                auto_slopes(jdx) = coefficients(1);
                auto_intercepts(jdx) = coefficients(2);
                fitted_pulses = round(polyval(coefficients, bigger(jdx:(n_bigger-difference+jdx-1))));
                R = corrcoef(smaller+bigger(jdx), fitted_pulses);
                auto_R_squared(jdx) = R(1, 2)^2;
            end
            
            figure
            subplot(1, 3, 1)
            plot(1:difference+1, auto_R_squared);
            subplot(1, 3, 2)
            plot(1:difference+1, auto_slopes);
            subplot(1, 3, 3)
            plot(1:difference+1, auto_intercepts);
            sgtitle(sprintf('%s %s %s Autocorrelation', subject, task, session));
            print(plot_file3, '-dpng')
            close all
            
            best_index = find(auto_R_squared == max(auto_R_squared));
            
            if n_difference > 0
                event_pulses = event_pulses(best_index:n_pulses_events-difference+best_index-1);
            else
                all_pulse_starts = all_pulse_starts(best_index:length(all_pulse_starts)-difference+best_index-1);
            end
            
            if do_plot_labeled_pulses
                results = plot_labeled_pulses(plot_file2, event_pulses, all_pulse_starts, eeg_starts, eeg_ends);
            end
            n_pulse_tests_events(idx) = results.n_pulse_tests_events;
            n_pulse_tests_eeg(idx) = results.n_pulse_tests_eeg;
            test_n_pulses_events{idx} = results.test_n_pulses_events;
            test_n_pulses_eeg{idx} = results.test_n_pulses_eeg;
            n_breaks_events(idx) = results.n_breaks_events;
            n_breaks_eeg(idx) = results.n_breaks_eeg;
            n_pulse_tests_mismatch(idx) = n_pulse_tests_eeg(idx) ~= n_pulse_tests_events(idx);
            n_breaks_mismatch(idx) = n_breaks_eeg(idx) ~= n_breaks_events(idx);
            
            time_ratios = diff(event_pulses)./diff(vertcat(pulse_starts{:}));
            bad_ratios = time_ratios>1.005 & time_ratios<0.995;
            good_ratios(idx) = sum(bad_ratios)<= n_recordings(idx)-1;
            bad_idx{idx} = find(bad_ratios, 1, 'first');
            
            timespan_events(idx) = event_pulses(end) - event_pulses(1);
            timespan_eeg(idx) = all_pulse_starts(end) - all_pulse_starts(1);
            timespan_mismatch(idx) = timespan_events(idx) ~= timespan_eeg(idx);
            timespan_error(idx) =  timespan_eeg(idx) - timespan_events(idx);
            
            pulse_start_mismatch(idx) = any(event_pulses ~= all_pulse_starts);
            pulse_start_error(idx) = mean(all_pulse_starts-event_pulses);
            coefficients = polyfit(event_pulses, all_pulse_starts, 1);
            slope(idx) = coefficients(1);
            intercept(idx) = coefficients(2);
            fitted_pulse_starts = round(polyval(coefficients, event_pulses));
            fitted_eegoffset = round(polyval(coefficients, event_times));
            R = corrcoef(all_pulse_starts, fitted_pulse_starts);
            R_squared(idx) = R(1, 2)^2;
            
            if is_aligned
                eegoffset_mismatch(idx) = any(modified_eegoffset ~= fitted_eegoffset);
                if eegoffset_mismatch(idx)
                    mean_eegoffset_error(idx) = mean(modified_eegoffset-fitted_eegoffset);
                end
            end
            
            if do_plot_mismatch
                plot_mismatch(plot_file1, event_pulses, all_pulse_starts, fitted_pulse_starts, event_times, modified_eegoffset, fitted_eegoffset, eeg_starts, eeg_ends);
            end
        end
    end
    time_ratios = diff(event_pulses)./diff(vertcat(pulse_starts{:}));
        bad_ratios = time_ratios>1.005 & time_ratios<0.995;
        good_ratios(idx) = sum(bad_ratios)<= n_recordings(idx)-1;
        bad_idx{idx} = find(bad_ratios, 1, 'first');
        
        timespan_events(idx) = event_pulses(end) - event_pulses(1);
        timespan_eeg(idx) = all_pulse_starts(end) - all_pulse_starts(1);
        timespan_mismatch(idx) = timespan_events(idx) ~= timespan_eeg(idx); 
        timespan_error(idx) =  timespan_eeg(idx) - timespan_events(idx);
        
        pulse_start_mismatch(idx) = any(event_pulses ~= all_pulse_starts);
        pulse_start_error(idx) = mean(all_pulse_starts-event_pulses);
        coefficients = polyfit(event_pulses, all_pulse_starts, 1);
        slope(idx) = coefficients(1);
        intercept(idx) = coefficients(2);
        fitted_pulse_starts = round(polyval(coefficients, event_pulses));
        fitted_eegoffset = round(polyval(coefficients, event_times));
        R = corrcoef(all_pulse_starts, fitted_pulse_starts);
        R_squared(idx) = R(1, 2)^2;
        
        if is_aligned
            eegoffset_mismatch(idx) = any(modified_eegoffset ~= fitted_eegoffset);
            if eegoffset_mismatch(idx)
                mean_eegoffset_error(idx) = mean(modified_eegoffset-fitted_eegoffset);
            end
        end
        
        if do_plot_mismatch
            plot_mismatch(plot_file1, event_pulses, all_pulse_starts, fitted_pulse_starts, event_times, modified_eegoffset, fitted_eegoffset, eeg_starts, eeg_ends);
        end
        
        if do_plot_labeled_pulses
            results = plot_labeled_pulses(plot_file2, event_pulses, all_pulse_starts, eeg_starts, eeg_ends);
        end
        n_pulse_tests_events(idx) = results.n_pulse_tests_events;
        n_pulse_tests_eeg(idx) = results.n_pulse_tests_eeg;
        test_n_pulses_events{idx} = results.test_n_pulses_events;
        test_n_pulses_eeg{idx} = results.test_n_pulses_eeg;
        n_breaks_events(idx) = results.n_breaks_events;
        n_breaks_eeg(idx) = results.n_breaks_eeg;
        n_pulse_tests_mismatch(idx) = n_pulse_tests_eeg(idx) ~= n_pulse_tests_events(idx);
        n_breaks_mismatch(idx) = n_breaks_eeg(idx) ~= n_breaks_events(idx);
end

alignment_table = events_info;
alignment_table.no_pulses_file = no_pulses_file;
alignment_table.no_sync_signal = no_sync_signal;
alignment_table.n_pulses_events = n_pulses_events;
alignment_table.n_pulses_eeg = n_pulses_eeg;
alignment_table.n_pulse_starts = n_pulse_starts;
alignment_table.n_pulse_tests_events = n_pulse_tests_events;
alignment_table.n_pulse_tests_eeg = n_pulse_tests_eeg;
alignment_table.test_n_pulses_events = test_n_pulses_events;
alignment_table.test_n_pulses_eeg = test_n_pulses_eeg;
alignment_table.n_breaks_events = n_breaks_events;
alignment_table.n_breaks_eeg = n_breaks_eeg;
alignment_table.bad_idx = bad_idx;
alignment_table.matched_starts = matched_starts;
alignment_table.n_pulse_tests_mismatch = n_pulse_tests_mismatch;
alignment_table.n_breaks_mismatch = n_breaks_mismatch;
alignment_table.equal_n_pulses = equal_n_pulses;
alignment_table.good_ratios = good_ratios;
alignment_table.eegoffset_mismatch = eegoffset_mismatch;
alignment_table.mean_eegoffset_error = mean_eegoffset_error;
alignment_table.timespan_events = timespan_events;
alignment_table.timespan_eeg = timespan_eeg;
alignment_table.timespan_mismatch = timespan_mismatch;
alignment_table.timespan_error = timespan_error;
alignment_table.pulse_start_mismatch = pulse_start_mismatch;
alignment_table.pulse_start_error = pulse_start_error;
alignment_table.slope = slope;
alignment_table.intercept = intercept;
alignment_table.R2 = R_squared;

save(fullfile(list_directory, 'alignment_table.mat'), 'alignment_table');
end

function plot_mismatch(plot_file, event_pulses, eeg_pulses, fitted_pulses, event_times, original_offsets, fitted_offsets, eeg_starts, eeg_ends)
n_pulses = length(event_pulses);
n_events = length(event_times);

differences_pulses = zeros(n_pulses, 3);
differences_pulses(:, 1) = eeg_pulses - event_pulses;
differences_pulses(:, 2) = fitted_pulses - eeg_pulses;
differences_pulses(:, 3) = fitted_pulses - event_pulses;

differences_offsets = zeros(n_events, 3);
differences_offsets(:, 1) = original_offsets - event_times;
differences_offsets(:, 2) = fitted_offsets - original_offsets;
differences_offsets(:, 3) = fitted_offsets - event_times;

min_time = min([0, fitted_pulses(1), fitted_offsets(1), original_offsets(1)]);
max_time = max([event_pulses(end), eeg_pulses(end), fitted_pulses(end), event_times(end), fitted_offsets(end), original_offsets(end)]);
span = max_time-min_time;

signals = false(6, ceil(max_time)-floor(min_time));
for idx = 1:n_pulses
    events_idx = floor(event_pulses(idx)-floor(min_time))+1;
    eeg_idx = floor(eeg_pulses(idx)-floor(min_time))+1;
    fitted_idx = floor(fitted_pulses(idx)-floor(min_time))+1;
    signals(1, events_idx) = true;
    signals(2, eeg_idx) = true;
    signals(3, fitted_idx) = true;
end
for idx = 1:n_events
    events_idx = floor(event_times(idx)-floor(min_time))+1;
    eeg_idx = floor(original_offsets(idx)-floor(min_time))+1;
    fitted_idx = floor(fitted_offsets(idx)-floor(min_time))+1;
    signals(4, events_idx) = true;
    signals(5, eeg_idx) = true;
    signals(6, fitted_idx) = true;
end

[~, red, blue, orange, purple, green, pink] = get_color_selection();

figure_width = 1920;
figure_height = 1080;

n5_min = 300000;
n1_hr = n5_min*12;
x_limits = [min_time-(span*0.1), max_time+(span*0.1)];
x_ticks = unique([min_time, 0:n5_min:max_time, max_time]);
x_tick_labels = repelem({''}, length(x_ticks), 1);
x_tick_labels{x_ticks == min_time} = [num2str(min_time), 'ms'];    
x_tick_labels{x_ticks == max_time} = [sprintf('%.2f', max_time/n1_hr), 'hr'];

figure_handle = figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off');

subplot_height_error = figure_height/3;
subplot_height = figure_height/2;
subplot_width = figure_width - (2 * subplot_height_error);

subplot_title = 'Pulses: Events(green), EEG (red), Fitted (blue)';
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [0 subplot_height subplot_width subplot_height], 'Visible', 'off')
plot_signals(subplot_title, signals(1:3, :), green, red, blue);

subplot_title = 'Offsets: Events(purple), Original (pink), Fitted (orange)';
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [0 0 subplot_width subplot_height], 'Visible', 'off')
plot_signals(subplot_title, signals(4:6, :), purple, pink, orange);

subplot_height = subplot_height_error;
subplot_x = subplot_width;

subplot_title = 'EEG Pulses - Event Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 1));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x subplot_height*2 subplot_height subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 1), n_pulses, blue, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Pulses - EEG Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 2));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x subplot_height subplot_height subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 2), n_pulses, green, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Pulses - Event Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 3));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x 0 subplot_height subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 3), n_pulses, red, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_x = subplot_width + subplot_height_error;

subplot_title = 'Original Offsets - Event times';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 1));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x subplot_height*2 subplot_height subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 1), n_events, purple, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Offsets - Original Offsets';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 2));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x subplot_height subplot_height subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 2), n_events, orange, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Offsets - Event Times';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 3));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x 0 subplot_height subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 3), n_events, pink, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);



print(plot_file, '-dpng')
close all
end

function results = plot_labeled_pulses(plot_file, events_pulses, eeg_pulses, eeg_starts, eeg_ends)
n_eeg_files = length(eeg_starts);

results = struct;
[diff_test_events, diff_event_events, diff_break_events, n_pulse_tests_events, n_breaks_events, test_n_pulses_events] = get_pulse_diff_types(events_pulses);
[diff_test_eeg, diff_event_eeg, diff_break_eeg, n_pulse_tests_eeg, n_breaks_eeg, test_n_pulses_eeg] = get_pulse_diff_types(eeg_pulses);

figure_width = 1920;
figure_height = 1080;
common_limits = [min(events_pulses(1), eeg_pulses(1)), max(events_pulses(end), eeg_pulses(end))];
[~, red, blue, ~, ~, green, ~] = get_color_selection();

figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off')

subplot(1, 2, 1)

hold on
scatter(events_pulses(diff_event_events), events_pulses(diff_event_events), [], repmat(blue, sum(diff_event_events), 1))
scatter(events_pulses(diff_test_events), events_pulses(diff_test_events), [], repmat(green, sum(diff_test_events), 1))
scatter(events_pulses(diff_break_events), events_pulses(diff_break_events), [], repmat(red, sum(diff_break_events), 1))
xlim(common_limits);xticks([]);xticklabels([]);
ylim(common_limits);yticks([]);yticklabels([]);
if n_eeg_files > 1
    for idx = 2:n_eeg_files
        plot([eeg_ends(idx-1), eeg_ends(idx-1)], common_limits, '--k')
        plot([eeg_starts(idx), eeg_starts(idx)], common_limits, '--k')
    end
end
hold off

subplot(1, 2, 2)

hold on
scatter(eeg_pulses(diff_event_eeg), eeg_pulses(diff_event_eeg), [], repmat(blue, sum(diff_event_eeg), 1))
scatter(eeg_pulses(diff_test_eeg), eeg_pulses(diff_test_eeg), [], repmat(green, sum(diff_test_eeg), 1))
scatter(eeg_pulses(diff_break_eeg), eeg_pulses(diff_break_eeg), [], repmat(red, sum(diff_break_eeg), 1))
if n_eeg_files > 1
    for idx = 2:n_eeg_files
        plot([eeg_ends(idx-1), eeg_ends(idx-1)], common_limits, '--k')
        plot([eeg_starts(idx), eeg_starts(idx)], common_limits, '--k')
    end
end
xlim(common_limits);xticks([]);xticklabels([]);
ylim(common_limits);yticks([]);yticklabels([]);
hold off

print(plot_file, '-dpng')
close all

results.diff_test_events = diff_test_events;
results.diff_event_events = diff_event_events;
results.diff_break_events = diff_break_events;
results.n_pulse_tests_events = n_pulse_tests_events;
results.n_breaks_events = n_breaks_events;
results.test_n_pulses_events = test_n_pulses_events;
results.diff_test_eeg = diff_test_eeg;
results.diff_event_eeg = diff_event_eeg;
results.diff_break_eeg = diff_break_eeg;
results.n_pulse_tests_eeg = n_pulse_tests_eeg;
results.n_breaks_eeg = n_breaks_eeg;
results.test_n_pulses_eeg = test_n_pulses_eeg;
end

function [gray, red, blue, orange, purple, green, pink] = get_color_selection()
gray = [.75 .75 .75];
red = [.75 0 0];
blue = [0 0 .75];
green = [0 .75 0];
pink = [.75 0 .5];
orange = [.75 .5 0];
purple = [.5 0 .75];
end

function [y_limits, y_ticks, y_tick_labels] = get_y_ticks(values)
min_value = min(values);
max_value = max(values);
range = max_value-min_value;
if range > 0
    y_limits = [min_value-(range*.1), max_value+(range*.1)];
    y_ticks = min_value:range/10:max_value;
    y_tick_labels = repelem({''}, length(y_ticks), 1);
    y_tick_labels{1} = num2str(min_value);
    y_tick_labels{end} = num2str(max_value);
else
    y_limits = [min_value-1, min_value+1];
    y_ticks = min_value;
    y_tick_labels = {num2str(min_value)};
end
end

function plot_difference(subplot_title, x, y, n_observations, color, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends)
n_eeg_files = length(eeg_starts);
hold on
scatter(x, y, [], repmat(color, n_observations, 1));
if n_eeg_files > 1
    for idx = 2:n_eeg_files
        plot([eeg_ends(idx-1), eeg_ends(idx-1)], y_limits, '--k')
        plot([eeg_starts(idx), eeg_starts(idx)], y_limits, '--k')
    end
end
for idx = 1:length(x_ticks)
    if idx == 1
        horizontal_alignment = 'left';
    elseif idx == length(x_ticks)
        horizontal_alignment = 'right';
    else
        horizontal_alignment = 'center';
    end
    plot([x_ticks(idx), x_ticks(idx)], [y_limits(1), y_limits(1)+diff(y_limits)/100], '-k')
    if ~strcmp(x_tick_labels{idx}, '')
        text(x_ticks(idx), y_limits(1)+diff(y_limits)/100, x_tick_labels{idx}, 'FontSize', 12, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'bottom');
    end
end
for idx = 1:length(y_ticks)
    if idx == 1
        horizontal_alignment = 'left';
    elseif idx == length(y_ticks)
        horizontal_alignment = 'right';
    else
        horizontal_alignment = 'center';
    end
    if ~strcmp(y_tick_labels{idx}, '')
        text(x_limits(1), y_ticks(idx), y_tick_labels{idx}, 'FontSize', 12, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'top', 'Rotation', 90);
    end
end
text(mean(x_limits), y_limits(2), subplot_title, 'FontSize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
xlim(x_limits);xticks([]);xticklabels([]);
ylim(y_limits);yticks([]);yticklabels([]);
hold off
end

function plot_signals(subplot_title, signals, color1, color2, color3)
ratio = (1 + sqrt(5))/2;
n5_min = 300000;
t5_min = 1:n5_min;
n_points = size(signals, 2);
n_lines = ceil(n_points/n5_min);
n_missing = (n_lines*n5_min) - n_points;
signals = [signals, zeros(3, n_missing)];
x_limits = [-5000, 305000];
y_limits = [0, ratio*(n_lines+2)];
hold on
for idx = 1:n_lines
chunk = t5_min + (n5_min*(idx-1));
offset = ratio*(n_lines-idx+1);
plot(t5_min, signals(3, chunk)+offset, 'Color', color3, 'LineWidth', 0.5)
plot(t5_min, signals(2, chunk)+offset, 'Color', color2, 'LineWidth', 0.5)
plot(t5_min, signals(1, chunk)+offset, 'Color', color1, 'LineWidth', 0.5)
end
text(150000, y_limits(2), subplot_title, 'FontSize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
hold off
xlim(x_limits);xticks([]);xticklabels([]);
ylim(y_limits);yticks([]);yticklabels([]);
end

function [diff_test, diff_break, diff_event, n_pulse_tests, n_breaks, test_n_pulses] = get_pulse_diff_types(pulses)
n_pulses = length(pulses);
differential = diff(pulses)/1000;

diff_test = false(n_pulses, 1);
diff_event = false(n_pulses, 1);
diff_break = false(n_pulses, 1);

diff_test(2:end) = differential < 1.1;
diff_event(2:end) = ~diff_test(2:end) & differential < 15;
diff_break(2:end) = differential > 15;

test_starts = find(diff(diff_test)==1);
test_ends = find(diff(diff_test)==-1);
diff_test(test_starts) = true;
diff_break(test_starts) = false;
break_starts = find(diff(diff_break)==1);

if length(test_starts) > length(test_ends)
    test_starts = test_starts(1:end-1);
end

n_pulse_tests = length(test_starts);
n_breaks = length(break_starts);
test_n_pulses = test_ends - test_starts + 1;
end
