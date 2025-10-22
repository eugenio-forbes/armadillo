function alignment_table = check_alignment(varargin)
if isempty(varargin)
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder = 'armadillo';
    alignment_type = 'NK'; %NK or BR
    sampling_rate = 1000; %HZ
    do_plots = true;
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder = varargin{3};
    alignment_type = varargin{4};
    sampling_rate = varargin{5};
    do_plots = varargin{6};
end

analysis_directory = fullfile(root_directory, username, analysis_folder);
subject_directory = fullfile(analysis_directory, 'subject_files');
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');
plot_directory = fullfile(analysis_directory, 'plots/alignment');
resources_directory = fullfile(analysis_directory, 'resources');

if ~isfolder(plot_directory)
    mkdir(plot_directory);

end
warning off;

sync_channels = [259, 258, 130, 129];

load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'events_info.mat'), 'events_info');
raw_list = get_raw_list(subject_directory, resources_directory, events_info);

exclusions = ~events_info.is_aligned & ~strcmp(events_info.task, 'AR_Scopolamine');
events_info(exclusions, :) = [];
n_sessions = height(events_info);

subjects = events_info.subject;
subjects = cellfun(@(x) str2double(regexp(x, '\d{3}', 'match')), subjects);
is_SMILE_session = subjects > 232;

nan_array = NaN(n_sessions, 1);
cell_array = cell(n_sessions, 1);
false_array = false(n_sessions, 1);
zero_array = zeros(n_sessions, 1);

n_blocks_session       = nan_array;
n_recordings           = nan_array;
block_n_eegs           = cell_array;

no_pulses_file         = false_array;
no_sync_signal         = false_array;

n_pulses_events        = nan_array;
n_pulses_eeg           = nan_array;
n_pulse_starts         = cell_array;
matched_starts         = false_array;
equal_n_pulses         = false_array;

good_ratios            = false_array;
bad_idx                = cell_array;

n_pulse_tests_events   = nan_array;
n_pulse_tests_eeg      = nan_array;
test_n_pulses_events   = cell_array;
test_n_pulses_eeg      = cell_array;
n_pulse_tests_mismatch = false_array;

n_breaks_events        = nan_array;
n_breaks_eeg           = nan_array;
n_breaks_mismatch      = false_array;

block_starts_events    = cell_array;
block_ends_events      = cell_array;
block_starts_eeg       = cell_array;
block_ends_eeg         = cell_array;

timespan_events        = nan_array;
timespan_eeg           = nan_array;
timespan_mismatch      = false_array;
timespan_error         = zero_array;
pulse_start_mismatch   = false_array;
pulse_start_error      = zero_array;
eegoffset_mismatch     = false_array;
mean_eegoffset_error   = zero_array;
offset_error           = cell_array;

slope                  = zero_array;
intercept              = zero_array;
R_squared              = zero_array;

error_count = 0;

for idx = 1:n_sessions
    
    try
        
        subject    = events_info.subject{idx};
        task       = events_info.task{idx};
        session    = events_info.session{idx};
        session_ID = events_info.session_ID(idx);
        is_aligned = events_info.is_aligned(idx);

        file_name_holder = [fullfile(plot_directory, sprintf('%s_%s_%s', subject, task, session)), '_%s'];
        
        fprintf('%s %s %s\n', subject, task, session);
        
        session_folder = fullfile(subject_directory, subject, 'behavioral', task, session);
        noreref_folder = fullfile(subject_directory, subject, 'eeg.noreref');
        data_folder = fullfile(data_directory, subject, task, session);
        
        events_file = fullfile(data_folder, 'events.mat');
        load(events_file, 'events')
        
        n_events = height(events);
        
        block = events.block;
        unique_blocks = unique(block);
        n_blocks_session(idx) = length(unique_blocks);
        
        eeg_dates = raw_list.eeg_dates{raw_list.session_ID == session_ID};
        
        if is_aligned
        
            eegfiles          = events.eegfile;
            eegoffset         = events.eegoffset;
            n_recordings(idx) = events_info.n_recordings(idx);
            eeg_file_length   = events_info.eeg_file_length{idx};

            empty_eeg = cellfun(@isempty, eegfiles);
            unique_eegs = unique(eegfiles(~empty_eeg & eegoffset >= 0), 'stable');
            
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
                    
        elseif contains(task, 'Scopolamine')
        
            session_number = str2double(session(end));
            
            file_string = sprintf('%s_AR_Scop_%d*259', subject, session_number);
            
            eegfiles = dir(fullfile(noreref_folder, file_string));
            size_bytes = [eegfiles.bytes];
            eegfiles = fullfile({eegfiles.folder}, {eegfiles.name});
            eegfiles = strrep(eegfiles, '.259', '');
            unique_eegs = unique(eegfiles);
            
            block_n_eegs{idx} = zeros(1, n_blocks_session(idx));
            modified_eegoffset = zeros(n_events, 1);
            n_recordings(idx) = length(unique_eegs);
            eeg_file_length = size_bytes / 2;
            
        else
            continue
        end
        
        pulses_file1 = fullfile(session_folder, 'pulses.csv');
        pulses_file2 = fullfile(session_folder, 'pulses.txt');
        pulses_file3 = fullfile(session_folder, 'eeg.eeglog.up');
        new_pulses_file = fullfile(data_folder, 'corrected_pulses.txt');
        
        if isfile(pulses_file1)
        
            fprintf('%s\n', pulses_file1)
            event_pulses = readtable(pulses_file1);
            event_pulses = event_pulses.pulse_time * 1000;
            
        elseif isfile(pulses_file2)
        
            fprintf('%s\n', pulses_file2)
            event_pulses = readcell(pulses_file2);
            event_pulses = vertcat(event_pulses{:});
        
        elseif isfile(pulses_file3)
            
            fprintf('%s\n', pulses_file3)
            event_pulses = readcell(pulses_file3, 'FileType', 'text');
            
            if ~isempty(event_pulses)
                event_pulses = vertcat(event_pulses{:, 1});
            else
                continue
            end
        
        else
            no_pulses_file(idx) = true;
            continue
        end
        
        event_times = events.mstime;
        min_event_time = min(event_pulses);
        max_event_time = max(event_times);
        event_pulses(event_pulses > max_event_time + 10000) = [];
        event_pulses = event_pulses - min_event_time;
        event_times = event_times - min_event_time;
        
        n_pulses_events(idx) = length(event_pulses);
        fprintf('%d initial event pulses, \n', n_pulses_events(idx))
        
        sync_recordings = cell(n_recordings(idx), 1);
        pulse_starts    = cell(n_recordings(idx), 1);
        pulse_finishes  = cell(n_recordings(idx), 1);
        n_starts        = NaN(n_recordings(idx), 1);
        n_finishes      = NaN(n_recordings(idx), 1);
        
        fprintf('%d recordings, \n', n_recordings(idx))

        for jdx = 1:n_recordings(idx)
            
            sync_count = 1;
            
            file_exists = false;
            
            while ~file_exists && sync_count <= length(sync_channels)
                sync_eeg = [unique_eegs{jdx} sprintf('.%03d', sync_channels(sync_count))];
                file_exists = isfile(sync_eeg);
                sync_count = sync_count + 1;
            end
            
            if file_exists
            
                fprintf('%s\n', sync_eeg)
                
                file_length = eeg_file_length(jdx);
                
                file_id = fopen(sync_eeg, 'rb');
                sync_recordings{jdx} = fread(file_id, file_length, 'int16');
                fclose(file_id);
                
                threshold = 0.6 * max(vertcat(sync_recordings{jdx}));
                threshold_pass = vertcat(sync_recordings{jdx}) > threshold;
                differential = diff([0; threshold_pass; 0]);
                
                pulse_starts{jdx} = find(differential == 1);
                pulse_finishes{jdx} = find(differential == -1);
                n_starts(jdx) = length(pulse_starts{jdx});
                n_finishes(jdx) = length(pulse_finishes{jdx});
                fprintf('%d pulses, \n', n_starts(jdx))
                
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
        eeg_ends = eeg_file_length - min_pulse_start;
        
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
        n_pulse_starts{idx} = n_starts;
        
        eeg_pulses = vertcat(modified_pulse_starts{:});
        n_pulses_eeg(idx) = length(eeg_pulses);
        all_pulse_ends = vertcat(modified_pulse_finishes{:});
        pulse_widths = all_pulse_ends - eeg_pulses;      
        fprintf('%d initial total EEG pulses, \n', n_pulses_eeg(idx))

        equal_n_pulses(idx) = n_pulses_events(idx) == n_pulses_eeg(idx);
        
        if ~equal_n_pulses(idx)
            
            if is_SMILE_session(idx)                
                
                plot_file = sprintf(file_name_holder, '1-labeled-blocks');
                
                pulse_info = label_pulses(plot_file, event_pulses, eeg_pulses, eeg_starts, eeg_ends, do_plots);
                
                block_starts_events{idx} = pulse_info.block_starts_events;
                block_ends_events{idx}   = pulse_info.block_starts_events;
                block_starts_eeg{idx}    = pulse_info.block_starts_eeg;
                block_ends_eeg{idx}      = pulse_info.block_ends_eeg;
                test_starts_eeg          = pulse_info.test_starts_eeg;
                
                switch subject
                    case 'UT235'
                        if strcmp(session, 'session_0')
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT238'
                        if strcmp(session, 'session_0')
                            event_pulses([11:18, 625:628]) = [];
                        end
                        
                        if strcmp(session, 'session_1')
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT248'
                        if strcmp(session, 'session_0')
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        else
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses([248, 266]) = [];
                            eeg_pulses([264, 288]) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT249'
                        if strcmp(session, 'session_0')
                            continue %%% Incomplete pulses on EEG, so can't correct all pulses
                        end
                    
                    case 'UT265'
                        if strcmp(session, 'session_1')
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT274'
                        if strcmp(session, 'session_0')
                            eeg_pulses(test_starts_eeg(2):end) = [];
                        end
                    
                    case 'UT275'
                        if strcmp(session, 'session_0')
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT311'
                        if strcmp(task, 'AR') && strcmp(session, 'session_0')
                            eeg_pulses(end) = [];
                        end
                    
                        if strcmp(task, 'AR_stim') && strcmp(session, 'session_0')
                            eeg_pulses(1:test_starts_eeg(3) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT325'
                        if strcmp(task, 'AR_Scopolamine') && strcmp(session, 'session_1')
                            eeg_pulses(1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                    case 'UT341'
                        if strcmp(task, 'AR_Scopolamine') && strcmp(session, 'session_0')
                            eeg_pulses(1:test_starts_eeg(2) - 1) = [];
                            event_pulses = event_pulses + eeg_pulses(1);
                            event_times = event_times + eeg_pulses(1);
                        end
                    
                        if strcmp(task, 'AR_Scopolamine') && strcmp(session, 'session_1')
                            event_pulses(block_starts_events{idx}(5):end) = [];
                        end
                    
                    case 'UT365'
                        if strcmp(task, 'AR_Scopolamine') && strcmp(session, 'session_0')
                            event_pulses(block_starts_events{idx}(4):end) = [];
                        end
                    
                    case 'UT385'
                        if strcmp(task, 'AR_Scopolamine') && strcmp(session, 'session_0')
                            event_pulses(1:6) = [];
                        end
                end
                
                pulse_info = label_pulses('update_no_plot', event_pulses, eeg_pulses, eeg_starts, eeg_ends, false);
                [event_pulses, event_times] = adjust_clock_stop(event_pulses, event_times, eeg_pulses, pulse_info);
                
                if n_recordings(idx) > 1
                    pulse_info = label_pulses('update_no_plot', event_pulses, eeg_pulses, eeg_starts, eeg_ends, false);
                    event_pulses = remove_pulses_between_split_eeg(event_pulses, eeg_pulses, pulse_info, eeg_starts, eeg_ends);
                end
                
                n_pulses_events(idx) = length(event_pulses);
                n_pulses_eeg(idx) = length(eeg_pulses);
                
                if n_pulses_events(idx) ~= n_pulses_eeg(idx)
                    plot_file = sprintf(file_name_holder, '2-block-crosscorrelation');
                    pulse_info = label_pulses('update_no_plot', event_pulses, eeg_pulses, eeg_starts, eeg_ends, false);
                    [event_pulses, eeg_pulses] = block_crosscorrelation(plot_file, event_pulses, eeg_pulses, pulse_info);
                end
                
                plot_file = sprintf(file_name_holder, '3-matched-labeled-blocks');
                
                pulse_info = label_pulses(plot_file, event_pulses, eeg_pulses, eeg_starts, eeg_ends, do_plots);
                
                n_pulse_tests_events(idx) = pulse_info.n_pulse_tests_events;
                n_pulse_tests_eeg(idx) = pulse_info.n_pulse_tests_eeg;
                n_pulse_tests_mismatch(idx) = n_pulse_tests_eeg(idx) ~= n_pulse_tests_events(idx);
                
                n_breaks_events(idx) = pulse_info.n_breaks_events;
                n_breaks_eeg(idx) = pulse_info.n_breaks_eeg;
                n_breaks_mismatch(idx) = n_breaks_eeg(idx) ~= n_breaks_events(idx);
                
                block_starts_events{idx} = pulse_info.block_starts_events;
                block_ends_events{idx} = pulse_info.block_ends_events;
                
                block_starts_eeg{idx} = pulse_info.block_starts_eeg;
                block_ends_eeg{idx} = pulse_info.block_ends_eeg;
                
                n_pulses_events(idx) = length(event_pulses);
                n_pulses_eeg(idx) = length(eeg_pulses);
                
            else
                switch subject
                    case 'UT059'
                        if strcmp(session, 'session_0')
                            eeg_pulses(11:13) = [];
                        elseif strcmp(session, 'session_1')
                            event_pulses(31:45) = [];
                        end
                    
                    case 'UT071'
                        event_pulses(1:46) = [];
                    
                    case 'UT074'
                        event_pulses(1:32) = [];
                    
                    case 'UT075'
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT077'
                        eeg_pulses([84]) = [];
                    
                    case 'UT087'
                        eeg_pulses(pulse_widths <= 7) = [];
                        eeg_pulses([1:2, 3746:3747]) = [];
                        event_pulses([1:154, 175, 206:208, 3658, 3903:3930, 4114:4117, 4121, 4373, 4994]) = [];
                    
                    case 'UT093'
                        event_pulses([2, 95, 99, 118, 120, 244]) = [];
                    
                    case 'UT097'
                        if strcmp(session, 'session_0')
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                            event_pulses(1:138) = [];
                        end
                    
                    case 'UT096'
                        event_pulses(1:21) = [];
                    
                    case 'UT098'
                        eeg_pulses(682:727) = [];
                        eeg_pulses(end - 39:end) = [];
                        event_pulses(682:787)= [];
                    
                    case 'UT104'
                        eeg_pulses([36, 38, 57, 4425]) = [];
                        event_pulses([4439, 4444, 4572]) = [];
                    
                    case 'UT111'
                        if strcmp(session, 'session_0')
                            event_pulses(1228) = [];
                            eeg_pulses([3258, 3261]) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        end
                    
                    case 'UT113'
                        if strcmp(session, 'session_0')
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                            eeg_pulses(1:5) = [];
                            event_pulses(1:28) = [];
                        end
                   
                    case 'UT118'
                        if strcmp(session, 'session_0')
                            event_pulses([709:722, 1364:1500]) = [];
                        elseif strcmp(session, 'session_1')
                            event_pulses([1:9, 27]) = [];
                            eeg_pulses(1) = [];
                        end
                    
                    case 'UT114'
                        event_pulses([1:28, 156:157]) = [];
                    
                    case 'UT123'
                        event_pulses(1:46) = [];
                    
                    case 'UT126'
                        eeg_pulses(1) = [];
                        event_pulses(1:140) = [];
                    
                    case 'UT134'
                        event_pulses([1:45, 111:113, 1427, 2342:2360, 2673, 4128, 4800:4803, 5250]) = [];
                        eeg_pulses([1:2, 68:70, 2298]) = [];
                    
                    case 'UT136'
                        event_pulses([1:57, 2146:2147, 3410:3411, 4143, 4166:4167]) = [];
                        eeg_pulses([1, 2090, 3342, 3354, 4103]) = [];
                    
                    case 'UT139'
                        if strcmp(session, 'session_0')
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                        end
                    
                    case 'UT140'
                        event_pulses([1:710, 751:752]) = [];
                        eeg_pulses(1034:end) = [];
                        event_pulses = event_pulses(1:length(eeg_pulses));
                    
                    case 'UT149'
                        event_pulses(1:90) = [];
                        eeg_pulses(3484) = [];
                        event_pulses = event_pulses(1:length(eeg_pulses));
                    
                    case 'UT151'
                        event_pulses([1:40, 3631:3919, 4076:4095]) = [];
                        eeg_pulses([1, 463, 3593:3626, 3783:3791]) = [];
                    
                    case 'UT154'
                        event_pulses(1:42) = [];
                    
                    case 'UT155'
                        event_pulses(1:39) = [];
                        eeg_pulses(1) = [];
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    
                    case 'UT159'
                        event_pulses(1:102) = [];
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT165'
                        event_pulses(1:134) = [];
                    
                    case 'UT171'
                        eeg_pulses(pulse_widths < 7) = [];
                        event_pulses([1:68, 310, 323:324, 332, 336, 339, 342, 571, 578, 597, 615]) = [];
                        eeg_pulses([1]) = [];
                    
                    case 'UT178'
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT182'
                        if strcmp(session, 'session_0')
                            event_pulses([2873:2886]) = [];
                            eeg_pulses([2873]) = [];
                        else
                            eeg_pulses(116) = [];
                        end
                    
                    case 'UT185'
                        if strcmp(session, 'session_0')
                            event_pulses([2762:2774]) = [];
                        elseif strcmp(session, 'session_1')
                            event_pulses([1:65, 89:393]) = [];
                            eeg_pulses(2199) = [];
                        end
                    
                    case 'UT186'
                        event_pulses(3637:3650) = [];
                        event_pulses = event_pulses(1:length(eeg_pulses));
                    
                    case 'UT187'
                        eeg_pulses([1:10, 512:557]) = [];
                        event_pulses([1:10, 512:2591, 4460:4474]) = [];
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT190'
                        eeg_pulses(pulse_widths < 7) = [];
                        eeg_pulses(1:9) = [];
                        event_pulses([1:35, 346, 894, 1241:1254]) = [];
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT191'
                        if strcmp(session, 'session_0')
                            event_pulses([1:164, 693:703]) = [];
                            eeg_pulses(905) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                            event_pulses(48:61) = [];
                            eeg_pulses(48) = [];
                        end
                    
                    case 'UT192'
                        event_pulses([1:7, 77:81]) = [];
                        eeg_pulses([1:7, 77:81]) = [];
                    
                    case 'UT195'
                        event_pulses(1:43) = [];
                        eeg_pulses(diff([0; eeg_pulses]) < 15) = [];
                        event_pulses(diff([0; event_pulses]) < 15) = [];
                    
                    case 'UT199'
                        if strcmp(session, 'session_0')
                            event_pulses(1:83) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                            event_pulses(1:88) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_2')
                            event_pulses(1:34) = [];
                        end
                    
                    case 'UT200'
                        if strcmp(session, 'session_0')
                            event_pulses(1:91) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                            event_pulses(58:69) = [];
                        end
                    
                    case 'UT214'
                        if strcmp(session, 'session_0')
                            event_pulses(1:32) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        end
                    
                    case 'UT217'
                        event_pulses(1:181) = [];
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT220'
                        if strcmp(session, 'session_0')
                            event_pulses(1:119) = [];
                            eeg_pulses(1) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        elseif strcmp(session, 'session_1')
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        else
                        end
                    
                    case 'UT229'
                        if strcmp(session, 'session_0')
                            event_pulses([1:96, 1498:1664]) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        else
                            event_pulses(3006:3047) = [];
                        end
                    
                    case 'UT231'
                        if strcmp(session, 'session_0')
                            event_pulses([629:1161, 2121:2137, 2944:2957]) = [];
                            eeg_pulses(629) = [];
                            eeg_pulses = eeg_pulses(1:length(event_pulses));
                        else
                            event_pulses(1:39) = [];
                        end
                    
                    case 'UT232'
                        event_pulses([1:1539]) = [];
                        eeg_pulses(1:53) = [];
                end
                
                n_pulses_eeg(idx) = length(eeg_pulses);
                n_pulses_events(idx) = length(event_pulses);
                
                if do_plots
                    plot_file = sprintf(file_name_holder, '1-colored-gradients');
                    plot_colored_gradients(plot_file, event_pulses, eeg_pulses);

                    plot_file = sprintf(file_name_holder, '3-differentials-before');
                    plot_differentials(plot_file, event_pulses, eeg_pulses);
                end
                
                if n_pulses_events(idx) > n_pulses_eeg(idx)
                    bad_pulses_events = find_bad_pulses(event_pulses, eeg_pulses);
                    event_pulses(bad_pulses_events) = [];
                elseif n_pulses_events(idx) < n_pulses_eeg(idx)
                    bad_pulses_eeg = find_bad_pulses(eeg_pulses, event_pulses);
                    eeg_pulses(bad_pulses_eeg) = [];
                end
                
                switch subject
                    case 'UT119'
                        eeg_pulses([1305:1498, 2187:2254]) = [];
                        event_pulses([1305:1507, 2196:2277]) = [];
                        eeg_pulses = eeg_pulses(1:length(event_pulses));
                    
                    case 'UT128'
                        eeg_pulses([1:7, 256:263]) = [];
                        event_pulses([1:7, 256:257]) = [];
                        event_pulses = event_pulses(1:length(eeg_pulses));
                end
                
%                 crosscorrelations = cell(1, 1);
%                 if n_pulses_events(idx) > n_pulses_eeg(idx)
%                     [bad_pulses_events, crosscorrelations{1}] = crosscorrelate_pulses(event_pulses, eeg_pulses);
%                     event_pulses(bad_pulses_events) = [];
%                 else
%                     [bad_pulses_eeg, crosscorrelations{1}] = crosscorrelate_pulses(eeg_pulses, event_pulses);
%                     eeg_pulses(bad_pulses_eeg) = [];
%                 end
%                 plot_file = sprintf(file_name_holder, '2-session-crosscorrelation');
%                 plot_crosscorrelation(plot_file, crosscorrelations)
            
                
                
            end
        else
            switch subject
                case 'UT182'
                    if strcmp(session, 'session_1')
                        eeg_pulses(116) = [];
                        event_pulses(447) = [];
                    end
            end
        end
        
        if do_plots
            plot_file = sprintf(file_name_holder, '2-matched-colored-gradients');
            plot_colored_gradients(plot_file, event_pulses, eeg_pulses);
            
            plot_file = sprintf(file_name_holder, '4-differentials-after');
            plot_differentials(plot_file, event_pulses, eeg_pulses);
            
            plot_file = sprintf(file_name_holder, '5-corresponding-pulses');
            plot_corresponding(plot_file, event_pulses, eeg_pulses);
        end
        
        time_ratios = diff(event_pulses) ./ diff(eeg_pulses);
        bad_ratios = time_ratios > 1.005 & time_ratios < 0.995;
        good_ratios(idx) = sum(bad_ratios) <= n_recordings(idx) - 1;
        bad_idx{idx} = find(bad_ratios, 1, 'first');
        
        timespan_events(idx) = event_pulses(end) - event_pulses(1);
        timespan_eeg(idx) = eeg_pulses(end) - eeg_pulses(1);
        timespan_mismatch(idx) = timespan_events(idx) ~= timespan_eeg(idx);
        timespan_error(idx) =  timespan_eeg(idx) - timespan_events(idx);
        
        pulse_start_mismatch(idx) = any(event_pulses ~= eeg_pulses);
        pulse_start_error(idx) = mean(eeg_pulses - event_pulses);
        coefficients = polyfit(event_pulses, eeg_pulses, 1);
        slope(idx) = coefficients(1);
        intercept(idx) = coefficients(2);
        fitted_pulse_starts = round(polyval(coefficients, event_pulses));
        fitted_eegoffset = round(polyval(coefficients, event_times));
        R = corrcoef(eeg_pulses, fitted_pulse_starts);
        R_squared(idx) = R(1, 2) ^ 2;
        
        if do_plots
            plot_file = sprintf(file_name_holder, '6-mismatch');
            plot_mismatch(plot_file, event_pulses, eeg_pulses, fitted_pulse_starts, event_times, modified_eegoffset, fitted_eegoffset, eeg_starts, eeg_ends);
        end
        
        [corrected_event_pulses, corrected_event_times] = adjust_computer_time(event_pulses, event_times, eeg_pulses);
        coefficients = polyfit(corrected_event_pulses, eeg_pulses, 1);
        fitted_pulse_starts = round(polyval(coefficients, corrected_event_pulses));
        fitted_eegoffset = round(polyval(coefficients, corrected_event_times));
        
        if do_plots
            plot_file = sprintf(file_name_holder, '7-corrected');
            plot_mismatch(plot_file, corrected_event_pulses, eeg_pulses, fitted_pulse_starts, corrected_event_times, modified_eegoffset, fitted_eegoffset, eeg_starts, eeg_ends);
        end
        
        if is_aligned
            eegoffset_mismatch(idx) = any(modified_eegoffset ~= fitted_eegoffset);
            if eegoffset_mismatch(idx)
                offset_error{idx} = modified_eegoffset-fitted_eegoffset;
                mean_eegoffset_error(idx) = mean(offset_error{idx});
            end
        end
        
        fitted_eegoffset = floor(fitted_eegoffset) + min_pulse_start;
        adjusted_fitted_eegoffset = fitted_eegoffset;
        new_eegfile = repelem({''}, n_events, 1);
        corresponding = fitted_eegoffset >= eeg_starts(1) & fitted_eegoffset <= eeg_ends(1) + min_pulse_start - 5000;
        n_corresponding = sum(corresponding);
        new_eegfile(corresponding) = repelem(unique_eegs(1), n_corresponding, 1);
        
        if length(unique_eegs) > 1
        
            for jdx = 2:length(unique_eegs)
        
                time_difference = milliseconds(eeg_dates{jdx} - eeg_dates{1});
                corresponding = fitted_eegoffset >= eeg_starts(jdx) + min_pulse_start & fitted_eegoffset <= eeg_ends(jdx) + min_pulse_start-5000;
                
                adjusted_fitted_eegoffset(corresponding) = fitted_eegoffset(corresponding) - time_difference;
                new_eegfile(corresponding) = repelem(unique_eegs(jdx), sum(corresponding), 1);
        
            end            
        
        end
        
        out_of_bounds = strcmp(new_eegfile, '') | adjusted_fitted_eegoffset <= 0;
        adjusted_fitted_eegoffset(out_of_bounds) = NaN(sum(out_of_bounds), 1);
        
        events.eegfile   = new_eegfile;
        events.eegoffset = adjusted_fitted_eegoffset;
        events.mstime    = corrected_event_times;

        if ~strcmp(subject, 'UT140')
            save(events_file, 'events');
        end

        writematrix(corrected_event_pulses, new_pulses_file);
    
    catch e
        error_count = error_count + 1;
    end
end

alignment_table = events_info;

alignment_table.no_pulses_file         = no_pulses_file;
alignment_table.no_sync_signal         = no_sync_signal;

alignment_table.n_pulses_events        = n_pulses_events;
alignment_table.n_pulses_eeg           = n_pulses_eeg;

alignment_table.n_pulse_starts         = n_pulse_starts;

alignment_table.n_pulse_tests_events   = n_pulse_tests_events;
alignment_table.n_pulse_tests_eeg      = n_pulse_tests_eeg;
alignment_table.test_n_pulses_events   = test_n_pulses_events;
alignment_table.test_n_pulses_eeg      = test_n_pulses_eeg;

alignment_table.block_starts_events    = block_starts_events;
alignment_table.block_ends_events      = block_ends_events;
alignment_table.block_starts_eeg       = block_starts_eeg;
alignment_table.block_ends_eeg         = block_ends_eeg;
alignment_table.n_breaks_events        = n_breaks_events;
alignment_table.n_breaks_eeg           = n_breaks_eeg;
alignment_table.bad_idx                = bad_idx;

alignment_table.matched_starts         = matched_starts;
alignment_table.n_pulse_tests_mismatch = n_pulse_tests_mismatch;
alignment_table.n_breaks_mismatch      = n_breaks_mismatch;
alignment_table.equal_n_pulses         = equal_n_pulses;
alignment_table.good_ratios            = good_ratios;
alignment_table.eegoffset_mismatch     = eegoffset_mismatch;
alignment_table.mean_eegoffset_error   = mean_eegoffset_error;
alignment_table.offset_error           = offset_error;
alignment_table.timespan_events        = timespan_events;
alignment_table.timespan_eeg           = timespan_eeg;
alignment_table.timespan_mismatch      = timespan_mismatch;
alignment_table.timespan_error         = timespan_error;
alignment_table.pulse_start_mismatch   = pulse_start_mismatch;
alignment_table.pulse_start_error      = pulse_start_error; 

alignment_table.slope                  = slope;
alignment_table.intercept              = intercept;
alignment_table.R2                     = R_squared;

save(fullfile(list_directory, 'alignment_table.mat'), 'alignment_table');

fprintf('%d', error_count);

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
max_time = max([event_pulses(end), eeg_pulses(end), fitted_pulses(end), max(event_times), fitted_offsets(end), original_offsets(end)]);
span = ceil(max_time) - floor(min_time);

n5_min = 300000;
n_lines = ceil(span / n5_min);
n_missing = (n_lines * n5_min) - span;

signals = false(6, span + n_missing);

for idx = 1:n_pulses

    events_idx = floor(event_pulses(idx)-floor(min_time))+1;
    eeg_idx = floor(eeg_pulses(idx)-floor(min_time))+1;
    fitted_idx = floor(fitted_pulses(idx)-floor(min_time))+1;

    if events_idx > 0
        signals(1, events_idx) = true;
    end

    if eeg_idx > 0
        signals(2, eeg_idx) = true;
    end

    if fitted_idx > 0
        signals(3, fitted_idx) = true;
    end

end

for idx = 1:n_events

    events_idx = floor(event_times(idx)-floor(min_time))+1;
    eeg_idx = floor(original_offsets(idx)-floor(min_time))+1;
    fitted_idx = floor(fitted_offsets(idx)-floor(min_time))+1;

    if events_idx > 0
        signals(4, events_idx) = true;
    end

    if eeg_idx > 0
        signals(5, eeg_idx) = true;
    end

    if fitted_idx > 0
        signals(6, fitted_idx) = true;
    end

end

[~, red, blue, orange, purple, green, pink] = get_color_selection();

figure_width = 1920;
figure_height = 1080;

n1_hr = n5_min * 12;

x_limits = [min_time - (span * 0.1), max_time + (span * 0.1)];

x_ticks = unique([min_time, 0:n5_min:max_time, max_time]);
x_tick_labels = repelem({''}, length(x_ticks), 1);
x_tick_labels{x_ticks == min_time} = [num2str(min_time), 'ms'];    
x_tick_labels{x_ticks == max_time} = [sprintf('%.2f', max_time / n1_hr), 'hr'];

figure_handle = figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off');

subplot_height_error = figure_height / 3;
subplot_height = figure_height / 2;
subplot_width = figure_width - (2 * subplot_height_error);

subplot_title = 'Pulses: Events(green), EEG (red), Fitted (blue)';
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [0, subplot_height, subplot_width, subplot_height], 'Visible', 'off')
plot_signals(subplot_title, signals(1:3, :), green, red, blue);

subplot_title = 'Offsets: Events(purple), Original (pink), Fitted (orange)';
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [0, 0, subplot_width, subplot_height], 'Visible', 'off')
plot_signals(subplot_title, signals(4:6, :), purple, pink, orange);

subplot_height = subplot_height_error;
subplot_x = subplot_width;

subplot_title = 'EEG Pulses - Event Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 1));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height * 2, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 1), n_pulses, blue, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Pulses - EEG Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 2));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 2), n_pulses, green, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Pulses - Event Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 3));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, 0, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 3), n_pulses, red, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_x = subplot_width + subplot_height_error;

subplot_title = 'Original Offsets - Event times';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 1));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height * 2, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 1), n_events, purple, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Offsets - Original Offsets';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 2));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 2), n_events, orange, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Offsets - Event Times';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 3));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, 0, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 3), n_events, pink, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

print(plot_file, '-dpng')

close all

end

function pulse_info = label_pulses(plot_file, events_pulses, eeg_pulses, eeg_starts, eeg_ends, do_plot)

n_eeg_files = length(eeg_starts);

[diff_test_events, diff_break_events, diff_event_events, ...
    n_pulse_tests_events, n_breaks_events, test_n_pulses_events, ...
    test_starts_events, block_starts_events, block_ends_events] = get_pulse_diff_types(events_pulses);

[diff_test_eeg, diff_break_eeg, diff_event_eeg, ...
    n_pulse_tests_eeg, n_breaks_eeg, test_n_pulses_eeg, ...
    test_starts_eeg, block_starts_eeg, block_ends_eeg] = get_pulse_diff_types(eeg_pulses);

pulse_info = struct;

pulse_info.diff_test_events     = diff_test_events;
pulse_info.diff_event_events    = diff_event_events;
pulse_info.diff_break_events    = diff_break_events;
pulse_info.n_pulse_tests_events = n_pulse_tests_events;
pulse_info.n_breaks_events      = n_breaks_events;
pulse_info.test_n_pulses_events = test_n_pulses_events;
pulse_info.test_starts_events   = test_starts_events;
pulse_info.block_starts_events  = block_starts_events;
pulse_info.block_ends_events    = block_ends_events;
pulse_info.diff_test_eeg        = diff_test_eeg;
pulse_info.diff_event_eeg       = diff_event_eeg;
pulse_info.diff_break_eeg       = diff_break_eeg;
pulse_info.n_pulse_tests_eeg    = n_pulse_tests_eeg;
pulse_info.n_breaks_eeg         = n_breaks_eeg;
pulse_info.test_n_pulses_eeg    = test_n_pulses_eeg;
pulse_info.test_starts_eeg      = test_starts_eeg;
pulse_info.block_starts_eeg     = block_starts_eeg;
pulse_info.block_ends_eeg       = block_ends_eeg;

if do_plot

    figure_width = 1920;
    figure_height = 1080;
    
    common_limits = [min(events_pulses(1), eeg_pulses(1)), max(events_pulses(end), eeg_pulses(end))];
    
    [~, ~, blue, ~, ~, green, pink] = get_color_selection();
    
    figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off')
    
    subplot(1, 2, 1)
    hold on
    
    scatter(events_pulses(diff_event_events), events_pulses(diff_event_events), [], repmat(green, sum(diff_event_events), 1), 'o')
    scatter(events_pulses(block_starts_events), events_pulses(block_starts_events), [], repmat(pink, length(block_starts_events), 1), 'o', 'filled')
    scatter(events_pulses(block_ends_events), events_pulses(block_ends_events), [], repmat(pink, length(block_ends_events), 1), 'o', 'filled')
    scatter(events_pulses(diff_test_events), events_pulses(diff_test_events), [], repmat(blue, sum(diff_test_events), 1), 'o')
    
    xlim(common_limits); xticks([]); xticklabels([]);
    ylim(common_limits); yticks([]); yticklabels([]);
    
    if n_eeg_files > 1
    
        for idx = 2:n_eeg_files
            plot([eeg_ends(idx-1), eeg_ends(idx-1)], common_limits, '--k')
            plot([eeg_starts(idx), eeg_starts(idx)], common_limits, '--k')
        end
    
    end
    
    hold off
    
    subplot(1, 2, 2)
    hold on
    
    scatter(eeg_pulses(diff_event_eeg), eeg_pulses(diff_event_eeg), [], repmat(green, sum(diff_event_eeg), 1), 'o')
    scatter(eeg_pulses(block_starts_eeg), eeg_pulses(block_starts_eeg), [], repmat(pink, length(block_starts_eeg), 1), 'o', 'filled')
    scatter(eeg_pulses(block_ends_eeg), eeg_pulses(block_ends_eeg), [], repmat(pink, length(block_ends_eeg), 1), 'o', 'filled')
    scatter(eeg_pulses(diff_test_eeg), eeg_pulses(diff_test_eeg), [], repmat(blue, sum(diff_test_eeg), 1), 'o')
    
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

end

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
    y_limits = [min_value - (range * .1), max_value + (range * .1)];
    y_ticks = min_value:(range / 10):max_value;
    y_tick_labels = repelem({''}, length(y_ticks), 1);
    y_tick_labels{1} = num2str(min_value);
    y_tick_labels{end} = num2str(max_value);
else
    y_limits = [min_value - 1, min_value + 1];
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
        plot([eeg_ends(idx - 1), eeg_ends(idx - 1)], y_limits, '--k')
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

    plot([x_ticks(idx), x_ticks(idx)], [y_limits(1), y_limits(1) + diff(y_limits) / 100], '-k')

    if ~strcmp(x_tick_labels{idx}, '')
        text(x_ticks(idx), y_limits(1) + diff(y_limits) / 100, x_tick_labels{idx}, 'FontSize', 12, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'bottom');
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

xlim(x_limits); xticks([]); xticklabels([]);
ylim(y_limits); yticks([]); yticklabels([]);

hold off

end


function plot_signals(subplot_title, signals, color1, color2, color3)

ratio = (1 + sqrt(5)) / 2;

n5_min = 300000;
t5_min = 1:n5_min;

n_points = size(signals, 2);
n_lines = ceil(n_points / n5_min);

x_limits = [-5000, 305000];
y_limits = [0, ratio * (n_lines + 2)];

hold on

for idx = 1:n_lines

    chunk = t5_min + (n5_min * (idx - 1));

    offset = ratio * (n_lines - idx + 1);
    
    plot(t5_min, signals(3, chunk) + offset, 'Color', color3, 'LineWidth', 0.5)
    plot(t5_min, signals(2, chunk) + offset, 'Color', color2, 'LineWidth', 0.5)
    plot(t5_min, signals(1, chunk) + offset, 'Color', color1, 'LineWidth', 0.5)

end

text(150000, y_limits(2), subplot_title, 'FontSize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

hold off

xlim(x_limits); xticks([]); xticklabels([]);
ylim(y_limits); yticks([]); yticklabels([]);

end


function [diff_test, diff_break, diff_event, n_pulse_tests, n_breaks, test_n_pulses, ...
    test_starts, block_starts, block_ends] = get_pulse_diff_types(pulses)

n_pulses = length(pulses);
differential = diff(pulses) / 1000;

diff_test = false(n_pulses, 1);
diff_event = false(n_pulses, 1);
diff_break = false(n_pulses, 1);

diff_test(2:end) = differential < 1.1;
diff_event(2:end) = ~diff_test(2:end) & differential < 100;
diff_break(2:end) = differential >= 100;

isolated_test_pulses = find(diff(diff(diff_test)) == -2);
if ~isempty(isolated_test_pulses)
    indices = isolated_test_pulses + 1;
    diff_test(indices) = false(length(indices), 1);
    diff_event(indices) = true(length(indices), 1);
end

test_starts = find(diff(diff_test) == 1);
test_ends = find(diff(diff_test) == -1);

diff_test(test_starts) = true;
diff_break(test_starts) = false;

if length(test_starts) > length(test_ends)
    test_starts = test_starts(1:end-1);
end

for idx = 1:length(test_starts)
    diff_event(test_starts(idx):test_ends(idx)) = false;
    diff_test(test_starts(idx):test_ends(idx)) = true;
end

first_event = find(diff_event, 1, 'first');

block_starts = [first_event; find(diff(diff_event) == 1)];
block_ends =  [find(diff(diff_event) == -1); n_pulses];

block_starts(block_starts < first_event) = [];
block_ends(block_ends < first_event) = [];

test_n_pulses = test_ends - test_starts + 1;

n_pulse_tests = length(test_starts);
n_breaks = length(block_starts);

end


function [corrected_event_pulses, corrected_event_times] = adjust_computer_time(event_pulses, event_times, eeg_pulses)

time_difference = eeg_pulses - event_pulses;
corrected_event_pulses = eeg_pulses;
n_events = length(event_times);
corrected_event_times = NaN(n_events, 1);

for idx = 1:n_events

    current_time = event_times(idx);

    event_index = find(event_pulses<current_time, 1, 'last');

    if ~isempty(event_index)
        corrected_event_times(idx) = current_time+time_difference(event_index);        
    end

end

end


function raw_list = get_raw_list(subject_directory, resources_directory, session_list)

subjects    = session_list.subject;
tasks       = session_list.task;
sessions    = session_list.session;
session_IDs = session_list.session_ID;

raw_list_file = fullfile(resources_directory, 'raw_list.txt');
raw_list = readtable(raw_list_file);

n_sessions = height(raw_list);
session_ID = NaN(n_sessions, 1);
eeg_dates = cell(n_sessions, 1);

for idx = 1:n_sessions

    subject = raw_list.subject{idx};
    task    = raw_list.task{idx};
    session = raw_list.session{idx};
    
    session_index = strcmp(subjects, subject) & strcmp(tasks, task) & strcmp(sessions, session);
    
    if sum(session_index) == 1
        session_ID(idx) = session_IDs(session_index);
    end
    
    raw_eeg_files = regexp(raw_list.raw_eeg_files{idx}, '<([^<>]+)>', 'tokens');
    raw_eeg_files = [raw_eeg_files{:}];
    
    if ~isempty(raw_eeg_files)

        n_files = length(raw_eeg_files);
        dates = cell(n_files, 1);

        for jdx = 1:n_files

            eeg_file_stem = raw_eeg_files{jdx};
            files = dir(fullfile(subject_directory, subject, 'raw', '**', sprintf('%s.EEG', eeg_file_stem)));

            if ~isempty(files)
                eeg_file_name = fullfile({files(1).folder}, {files(1).name});
                dates{jdx} = get_EEG_date(eeg_file_name{:});
            end

        end

        eeg_dates{idx} = dates;

    end

end

raw_list.eeg_dates  = eeg_dates;
raw_list.session_ID = session_ID;

end

function eeg_date_ms = get_EEG_date(eeg_file_name)

% Modified nk_split_2 function to get EEG recording start date in seconds  

fid = fopen(eeg_file_name);
deviceBlockLen=128;
fseek(fid, deviceBlockLen + 18, 'bof');
blockAddress=fread(fid, 1, '*int32');  %fprintf('address of block %d: %d\n', i, blockAddress);
fseek(fid, blockAddress + 18, 'bof'); %fprintf('\nin EEG21 block!\n')
blockAddress=fread(fid, 1, '*int32');  %fprintf('address of block %d: %d\n', i, blockAddress);
fseek(fid, blockAddress + 20, 'bof'); %fprintf('\nin EEG waveform block!\n')
T_year=bcdConverter(fread(fid, 1, '*uint8'));
T_month=bcdConverter(fread(fid, 1, '*uint8'));
T_day=bcdConverter(fread(fid, 1, '*uint8'));
T_hour=bcdConverter(fread(fid, 1, '*uint8'));
T_minute=bcdConverter(fread(fid, 1, '*uint8'));
T_second=bcdConverter(fread(fid, 1, '*uint8'));
dateVector = [T_year, T_month, T_day, T_hour, T_minute, T_second];
eeg_date_ms = datetime(dateVector, 'Format', 'uuuu-MM-dd HH:mm:ss.SSS');
fclose(fid);

end


function out = bcdConverter(bits_in)
  x = dec2bin(bits_in, 8);
  out = 10 * bin2dec(x(1:4)) + bin2dec(x(5:8));
end


function [event_pulses, event_times] = adjust_clock_stop(event_pulses, event_times, all_pulse_starts, pulse_info)

block_starts_events = sort([pulse_info.test_starts_events;pulse_info.block_starts_events]);
block_starts_eeg = sort([pulse_info.test_starts_eeg;pulse_info.block_starts_eeg]);
n_breaks_events = length(block_starts_events);

for idx = 1:n_breaks_events

    start_time = event_pulses(block_starts_events(idx));

    if idx < n_breaks_events
        end_time = event_pulses(block_starts_events(idx+1));
        pulse_indices = block_starts_events(idx):block_starts_events(idx+1)-1;
    else
        end_time = event_pulses(end);
        pulse_indices = block_starts_events(idx):length(event_pulses);
    end

    event_indices = event_times>start_time & event_times<end_time;
    difference = all_pulse_starts(block_starts_eeg(idx)) - event_pulses(pulse_indices(1));
    event_pulses(pulse_indices) = event_pulses(pulse_indices) + difference;
    event_times(event_indices) = event_times(event_indices) + difference;

end

end


function event_pulses = remove_pulses_between_split_eeg(event_pulses, all_pulse_starts, pulse_info, eeg_starts, eeg_ends)

block_starts_events = sort([pulse_info.test_starts_events;pulse_info.block_starts_events]);
block_starts_eeg = sort([pulse_info.test_starts_eeg;pulse_info.block_starts_eeg]);

n_eegs = length(eeg_starts);
n_blocks = length(block_starts_events);
bad_event_pulses = false(length(event_pulses), 1);

for idx = 1:n_eegs-1

    break_start = eeg_ends(idx);
    block_split = find(all_pulse_starts(block_starts_eeg) < break_start, 1, 'last');

    events_block_start = block_starts_events(block_split);
    eeg_block_start = block_starts_eeg(block_split);

    if block_split<n_blocks
        events_block_end = block_starts_events(block_split+1)-1;
        eeg_block_end = block_starts_eeg(block_split+1)-1;
    else
        events_block_end = length(event_pulses);
        eeg_block_end = length(all_pulse_starts);
    end

    n_block_pulses_events = events_block_end - events_block_start + 1;
    n_block_pulses_eeg = eeg_block_end - eeg_block_start + 1;

    block_pulses_eeg = all_pulse_starts(eeg_block_start:eeg_block_end);
    n_before_split = sum(block_pulses_eeg < break_start);
    n_missing = n_block_pulses_events - n_block_pulses_eeg;
    
    if n_missing > 0
        pulse_exclusion = false(n_block_pulses_events, 1);
        pulse_exclusion(n_before_split + 1:n_before_split + n_missing) = true(n_missing, 1);
        bad_event_pulses(events_block_start:events_block_end) = pulse_exclusion;
    end

end

event_pulses(bad_event_pulses) = [];

end


function [event_pulses, all_pulse_starts] = block_crosscorrelation(plot_file, event_pulses, all_pulse_starts, pulse_info)

block_starts_events = [1; pulse_info.block_starts_events];
block_starts_eeg = [1; pulse_info.block_starts_eeg];

block_ends_events = [block_starts_events(1) - 1; pulse_info.block_ends_events];
block_ends_eeg = [block_starts_eeg(1) - 1; pulse_info.block_ends_eeg];

bad_pulses_events = false(length(event_pulses), 1);
bad_pulses_eeg = false(length(all_pulse_starts), 1);

n_blocks = length(block_starts_events);
event_blocks = cell(n_blocks, 1);
eeg_blocks = cell(n_blocks, 1);
unmatched_blocks = false(n_blocks, 1);
n_pulses_events = zeros(n_blocks, 1);
n_pulses_eeg = zeros(n_blocks, 1);

for idx = 1:n_blocks

    event_blocks{idx} = block_starts_events(idx):block_ends_events(idx);
    n_pulses_events(idx) = length(event_blocks{idx});
    eeg_blocks{idx} = block_starts_eeg(idx):block_ends_eeg(idx);
    n_pulses_eeg(idx) = length(eeg_blocks{idx});
    unmatched_blocks(idx) = n_pulses_events(idx) ~= n_pulses_eeg(idx);

end

n_unmatched = sum(unmatched_blocks);
unmatched_indices = find(unmatched_blocks);
crosscorrelations = cell(n_unmatched, 1);

for idx = 1:n_unmatched

    this_block = unmatched_indices(idx);
    event_indices = event_blocks{this_block};
    eeg_indices = eeg_blocks{this_block};

    if n_pulses_events(this_block) > n_pulses_eeg(this_block)
        [bad_pulses_events(event_indices), crosscorrelations{idx}] = crosscorrelate_pulses(event_pulses(event_indices), all_pulse_starts(eeg_indices));
    else
        [bad_pulses_eeg(eeg_indices), crosscorrelations{idx}] = crosscorrelate_pulses(all_pulse_starts(eeg_indices), event_pulses(event_indices));
    end

end

plot_crosscorrelation(plot_file, crosscorrelations)

if any(bad_pulses_events)
    event_pulses(bad_pulses_events) = [];
end

if any(bad_pulses_eeg)
    all_pulse_starts(bad_pulses_eeg) = [];
end

end

function plot_crosscorrelation(plot_file, crosscorrelations)

n_unmatched = length(crosscorrelations);

figure('Units', 'pixels', 'Position', [0 0 1920 1080], 'Visible', 'off')

for idx = 1:n_unmatched
    
    crosscorrelation = crosscorrelations{idx};
    
    difference    = length(crosscorrelation.R_squareds) - 1;
    best_index    = find(crosscorrelation.R_squareds == max(crosscorrelation.R_squareds));
    line_x        = best_index - 1;
    min_R         = min(crosscorrelation.R_squareds);
    max_R         = max(crosscorrelation.R_squareds);
    min_slope     = min(crosscorrelation.slopes);
    max_slope     = max(crosscorrelation.slopes);
    min_intercept = min(crosscorrelation.intercepts);
    max_intercept = max(crosscorrelation.intercepts);
    
    subplot(n_unmatched, 3, ((idx - 1) * 3) + 1)
    hold on
    scatter(0:difference, crosscorrelation.R_squareds);
    plot([line_x, line_x], [min_R, max_R]);
    hold off
    xlim([-1, difference + 1]);
    ylim([min_R, max_R]);
    
    subplot(n_unmatched, 3, ((idx - 1) * 3) + 2)
    hold on
    scatter(0:difference, crosscorrelation.slopes);
    plot([line_x, line_x], [min_slope, max_slope]);
    hold off
    xlim([-1, difference + 1]);
    ylim([min_slope, max_slope]);
    
    subplot(n_unmatched, 3, ((idx - 1) * 3) + 3)
    hold on
    scatter(0:difference, crosscorrelation.intercepts);
    plot([line_x, line_x], [min_intercept, max_intercept]);
    hold off
    xlim([-1, difference + 1]);
    ylim([min_intercept, max_intercept]);
    
end

print(plot_file, '-dpng')

close all

end


function [bad_pulses, crosscorrelation] = crosscorrelate_pulses(bigger, smaller)

n_bigger = length(bigger);
n_smaller = length(smaller);

crosscorrelation = struct;
bad_pulses = false(n_bigger, 1);

difference = n_bigger - n_smaller;

slopes = NaN(difference + 1, 1);
intercepts = NaN(difference + 1, 1);
R_squareds = NaN(difference + 1, 1);

for jdx = 1:n_smaller + 1

    temp_bigger = bigger;
    temp_bigger(jdx:jdx + difference - 1) = [];

    coefficients = polyfit(temp_bigger, smaller + temp_bigger(1), 1);
    slopes(jdx) = coefficients(1);
    intercepts(jdx) = coefficients(2);

    fitted_pulses = round(polyval(coefficients, temp_bigger));

    R = corrcoef(smaller + temp_bigger(1), fitted_pulses);
    R_squareds(jdx) = R(1, 2) ^ 2;

end

crosscorrelation.slopes     = slopes;
crosscorrelation.intercepts = intercepts;
crosscorrelation.R_squareds = R_squareds;

best_index = find(R_squareds == max(R_squareds), 1, 'first');

bad_pulses(best_index:best_index + difference - 1) = true(difference, 1);

end


function bad_pulses = find_bad_pulses(bigger, smaller)

n_bigger = length(bigger);
n_smaller = length(smaller);

difference = n_bigger - n_smaller;

bad_pulses = false(n_bigger, 1);
bad_count = 0;
bad_ratio_found = true;

diff_smaller = diff([0; smaller]);

while bad_count < difference && bad_ratio_found
    
    temp_bigger = bigger(1:n_smaller + bad_count);
    temp_bigger(bad_pulses(1:n_smaller + bad_count)) = [];
    diff_bigger = diff([0; temp_bigger]);
    
    if length(diff_bigger) ~= n_smaller
        a=1;
    end
    
    ratio = diff_bigger ./ diff_smaller;
    idx = 1;
    this_time_found = false;
    
    while idx <= n_smaller - 1 && ~this_time_found
    
        if ratio(idx) > 1.0025 || ratio(idx) < 0.9975
        
            if ratio(idx + 1) > 1.0025 || ratio(idx + 1) < 0.9975
                this_time_found = true;
                bad_pulses(idx+bad_count) = true;
                bad_count = bad_count + 1;
            end
            
        end
        
        idx = idx + 1;
    
    end
    
    if ~this_time_found
        bad_ratio_found = false;
    end
end

if bad_count < difference
    bad_pulses(n_smaller + bad_count + 1:end) = true(difference - bad_count, 1);
end

end


function plot_differentials(plot_file, event_pulses, eeg_pulses)

max_length = min(length(event_pulses), length(eeg_pulses));

event_pulses = event_pulses(1:max_length);
min_event = min(event_pulses);
max_event = max(event_pulses);

eeg_pulses = eeg_pulses(1:max_length);
min_eeg = min(eeg_pulses);
max_eeg = max(eeg_pulses);

diff_events = diff([0; event_pulses]);
min_diff_events = min(diff_events);
max_diff_events = max(diff_events);

diff_eeg = diff([0; eeg_pulses]);
min_diff_eeg = min(diff_eeg);
max_diff_eeg = max(diff_eeg);

diff_ratios = diff_events ./ diff_eeg;

pair_difference = eeg_pulses - event_pulses;
min_difference = min(pair_difference);
max_difference = max(pair_difference);

figure
plot(diff_ratios)

figure
hold on
plot(diff_events)
plot(diff_eeg)
hold off

figure('Units', 'pixels', 'Position', [0, 0, 1920, 1080], 'Visible', 'off')

subplot(5, 1, 1)
plot(event_pulses, diff_events)
xlim([min_event, max_event]);
ylim([min_diff_events, max_diff_events]);

subplot(5, 1, 2)
plot(eeg_pulses, diff_eeg)
xlim([min_eeg, max_eeg]);
ylim([min_diff_eeg, max_diff_eeg]);

subplot(5, 1, 3)
plot(eeg_pulses, diff_ratios)
xlim([min_eeg, max_eeg]);
ylim([0.98, 1.02]);

subplot(5, 1, 4)
plot(eeg_pulses, diff_eeg - diff_events);
xlim([min_event, max_event]);
ylim([-10, 10]);

subplot(5, 1, 5)
plot(eeg_pulses, pair_difference)
xlim([min_event, max_event]);
ylim([min_difference, max_difference]);

print(plot_file, '-dpng')

close all

end

function plot_corresponding(plot_file, event_pulses, eeg_pulses)

max_length = min(length(event_pulses), length(eeg_pulses));

event_pulses = event_pulses(1:max_length);
min_event = min(event_pulses);
max_event = max(event_pulses);

eeg_pulses = eeg_pulses(1:max_length);
min_eeg = min(eeg_pulses);
max_eeg = max(eeg_pulses);

figure('Units', 'pixels', 'Position', [0, 0, 1920, 1080], 'Visible', 'off')
plot(event_pulses, eeg_pulses)
xlim([min_event, max_event]);
ylim([min_eeg, max_eeg]);

print(plot_file, '-dpng')

close all

end


function plot_colored_gradients(plot_file, event_pulses, eeg_pulses)

min_event = min(event_pulses);
max_event = max(event_pulses);

min_eeg = min(eeg_pulses);
max_eeg = max(eeg_pulses);

diff_events = diff([0;event_pulses]);
pauses_events =  event_pulses(diff_events > prctile(diff_events, 99));
event_colors = get_diff_colors(diff_events);

diff_eeg = diff([0;eeg_pulses]);
pauses_eeg = eeg_pulses(diff_eeg > prctile(diff_eeg, 99));
eeg_colors = get_diff_colors(diff_eeg);

figure('Units', 'pixels', 'Position', [0, 0, 1920, 1080], 'Visible', 'off')

subplot(2, 1, 1)
hold on
scatter(event_pulses, event_pulses, [], event_colors);

for idx = 1:length(pauses_events)
    plot(repmat(pauses_events(idx), 1, 2), [min_event, max_event], '-k')
end

hold off
xlim([min_event, max_event]);
ylim([min_event, max_event]);

subplot(2, 1, 2)
hold on
scatter(eeg_pulses, eeg_pulses, [], eeg_colors);

for idx = 1:length(pauses_eeg)
    plot(repmat(pauses_eeg(idx), 1, 2), [min_eeg, max_eeg], '-k')
end

hold off
xlim([min_eeg, max_eeg]);
ylim([min_eeg, max_eeg]);

print(plot_file, '-dpng')

close all

end


function diff_colors = get_diff_colors(differential)
% mapx = makecolormap_EF('sigmoid3');
mapx = [hsv(675); zeros(325, 3); ones(2000, 3)];

mean_diff = mean(differential);
std_diff = std(differential);

differential = (differential-mean_diff) / std_diff;
differential = round(abs(differential) * 1000);

differential(differential <= 0) = ones(sum(differential <= 0), 1);
differential(differential > 3000) = ones(sum(differential > 3000), 1) * 3000;

diff_colors = mapx(differential, :);

end


function plot_pulse_widths(plot_file, pulse_widths)

figure('Units', 'pixels', 'Position', [0 0 1920 1080], 'Visible', 'off')

histogram(pulse_widths, 'BinMethod', 'integers');

print(plot_file, '-dpng');

close all

end