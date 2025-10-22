function add_PS_sham_events(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    subject = 'SC000';
    EEG_system = 'clinical';
    regularization = 'L2';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    subject = varargin{4};
    EEG_system = varargin{5};
    regularization = varargin{6};
end

%%% Important variables
min_offset = 800;
EEG_file_bad_words = {'jacksheet', 'params'};

%%% Declare directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
subject_directory = fullfile(analysis_directory, 'configurations', subject);
task_directory = fullfile(subject_directory, 'behavioral', sprintf('PS_%s', EEG_system));

%%% Check how many sessions there are so far
session_folders = dir(task_directory);
session_folders(~[session_folders.isdir]) = [];
check_dates = regexp({session_folders.name}, '\d{4}-\d{2}-\d{2}_\d{4}-\d{4}', 'match');
has_date = ~cellfun(@isempty, check_dates);
good_folders = contains({session_folders.name}, 'session') | has_date;
session_folders(~good_folders) = [];

if isempty(session_folders)
    error('Task directory %s was not found.\n', task_directory);
end

sessions = {session_folders.name};
session_folders = fullfile({session_folders.folder}, {session_folders.name});
n_sessions = length(session_folders);

for idx = 1:n_sessions

    session = sessions{idx};
    session_folder = session_folders{idx};
    
    events_file = fullfile(session_folder, 'events.mat');
    if ~isfile(events_file)
        fprintf(['No events file was found within session folder %s.\n', 'Sham events were not added.'], session);
        continue
    end
    
    configurations_file = fullfile(session_folder, 'configurations.json');
    if ~isfile(configurations_file)
        fprintf(['No configurations file was found within session folder %s.\n', 'Sham events were not added.'], session);
        continue
    end
    
    load(events_file, 'events');
    old_events = events; clear events
    if isstruct(old_events)
        old_events = struct2table(old_events);
    end
    
    field_names = old_events.Properties.VariableNames;
    
    if ~ismember('eegfile', field_names)
        fprintf(['Events for session %s have not been aligned.\n', 'Sham events were not added.\n'], session);
        continue
    end

    no_EEG_file = cellfun(@isempty, old_events.eegfile);
    old_events(no_EEG_file, :) = [];

    n_events = height(old_events);
    if n_events == 0
        fprintf(['No events remained for session %s after exluding unaligned events.\n', 'Sham events were not added.\n'], session);
        continue
    end
    
    if ~ismember('type', field_names)
        old_events.type = repelem({'STIMULATION_CONFIGURATION'}, n_events, 1);
    else
    
        if any(strcmp(old_events.type, 'SHAM'))
            fprintf(['Events for session %s already had sham events.\n', 'Additional sham events were not added.\n'], session);
            continue
        end
    
    end

    single_row = old_events(1, :);
    cleared_row = clear_row(single_row);

    configuration = jsondecode(fileread(configurations_file));
    
    pre_stim_classification_duration  = configuration.pre_stim_classification_duration;
    stim_duration                     = configuration.stim_duration;
    post_stim_lockout                 = configuration.post_stim_lockout;
    post_stim_classification_duration = configuration.post_stim_classification_duration;
    inter_trial_duration              = configuration.inter_trial_duration;
    inter_trial_jitter                = configuration.inter_trial_jitter;
    
    trial_duration = pre_stim_classification_duration + stim_duration + post_stim_lockout + post_stim_classification_duration;
    total_trial_duration = trial_duration + inter_trial_duration;

    sham_events = cell(20, 1);
    sham_count = 0;

    first_event = old_events(1, :);
    starting_offset = first_event.eegoffset;
    EEG_file_stem = first_event.eegfile{:};
    EEG_files = dir([EEG_file_stem, '.*']);
    bad_files = contains({EEG_files.name}, EEG_file_bad_words);
    EEG_files(bad_files) = [];
    n_files = length(EEG_files);
    
    if n_files == 0
        error('EEG files aligned to events of session %s were not found. Sham events not added.\n', session);
    end
    
    current_time = min_offset;
    time_remaining = starting_offset - current_time;

    while sham_count < 20 && time_remaining > total_trial_duration
    
        sham_time = current_time + pre_stim_classification_duration;
        
        this_inter_trial_duration = inter_trial_duration + (inter_trial_jitter * randn);
        this_trial_duration = trial_duration + this_inter_trial_duration;
        
        potential_end_time = current_time + this_trial_duration;
        
        if potential_end_time < starting_offset
            
            sham_count = sham_count + 1;
            
            sham_event = cleared_row;
            
            sham_event.subject   = {subject};
            sham_event.session   = {session};
            sham_event.type      = {'SHAM'};
            sham_event.eegfile   = {EEG_file_stem};
            sham_event.eegoffset = sham_time;
            
            sham_events{sham_count} = sham_event;
        
        end
        
        current_time = current_time + this_trial_duration;
        time_remaining = starting_offset - current_time;
        
    end

    last_event = old_events(n_events, :);
    ending_offset = last_event.eegoffset;
    EEG_file_stem = last_event.eegfile{:};
    EEG_files = dir([EEG_file_stem, '.*']);
    bad_files = contains({EEG_files.name}, EEG_file_bad_words);
    EEG_files(bad_files) = [];
    n_files = length(EEG_files);
    
    if n_files == 0
        error('EEG files aligned to events of session %s were not found. Sham events not added.\n', session);
    end
    
    EEG_file_size = max([EEG_files.bytes]);
    EEG_file_time_ms = EEG_file_size / 2;
    current_time = ending_offset + post_stim_lockout + post_stim_classification_duration + inter_trial_duration;
    time_remaining = EEG_file_time_ms - current_time;

    while sham_count < 20 && time_remaining > total_trial_duration
    
        sham_time = current_time + pre_stim_classification_duration;
        
        this_inter_trial_duration = inter_trial_duration + (inter_trial_jitter * randn);
        this_trial_duration = trial_duration + this_inter_trial_duration;
        
        potential_end_time = current_time + this_trial_duration;
        
        if potential_end_time < starting_offset
        
            sham_count = sham_count + 1;
            
            sham_event = cleared_row;
            
            sham_event.subject   = {subject};
            sham_event.session   = {session};
            sham_event.type      = {'SHAM'};
            sham_event.eegfile   = {EEG_file_stem};
            sham_event.eegoffset = sham_time;
            
            sham_events{sham_count} = sham_event;
            
        end
        
        current_time = current_time + this_trial_duration;
        time_remaining = EEG_file_time_ms - current_time;
        
    end

    if sham_count > 0
        sham_events = vertcat(sham_events{1:sham_count});
        events = [old_events; sham_events];
        save(events_file, 'events');
        fprintf('%d sham events were added to session %s.\n', sham_count, session);
    else
        fprintf('There was no room to add sham events for session %s.\n', session);
    end
    
end

end


function cleared_row = clear_row(single_row)

cleared_row = single_row;

variables = single_row.Properties.VariableNames;
n_variables = length(variables);

for idx = 1:n_variables

    variable = variables{idx};
    value = single_row.(variable);
    variable_class = class(value);

    switch variable_class
        case 'double'
            cleared_row.(variable) = NaN;

        case 'char'
            newRow.(variable) = '';

        case 'string'
            newRow.(variable) = "";

        case 'cell'
            newRow.(variable) = {[]};

        case 'datetime'
            newRow.(variable) = NaT;

        case 'logical'
            newRow.(variable) = false;

        otherwise
            newRow.(variable) = [];
    end

end

end