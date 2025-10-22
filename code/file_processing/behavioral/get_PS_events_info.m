%%% This function will gather information from the files contained
%%% in a session folder from stimulation parameter search experiments,
%%% prior to processing in process_events function, and return this 
%%% information in a table row to be added to session list table.
%%% Matches events files to Nihon Kohden and Blackrock recording files
%%% for alignment in n00_check_alignment function.

function session_row = get_PS_events_info(varargin)
if isempty(varargin)                              %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo';    %%% (character vector) Armadillo folder
    subject = 'SC000';                            %%% (character vector) Subject code
    task = 'PS';                                  %%% (character vector) Task name
    session = '2020-01-01_12-00-00';              %%% (character vector) Session date in 'yyyy-mm-dd_hh-mm-ss' format
    session_info = table(subject, task, session); %%% Do not edit
else                                              %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    session_info = varargin{2};
end

%%% Extract session info
subject = session_info.subject;
task    = session_info.task;
session = session_info.session;

%%% Declare directories
list_directory    = fullfile(analysis_directory, 'lists');
subject_directory = fullfile(analysis_directory, 'subject_files', subject{:});
session_directory = fullfile(subject_directory, 'behavioral', task{:}, session{:});

%%% Declare files
nihon_kohden_list_file        = fullfile(list_directory, 'nihon_kohden_list.mat');
blackrock_list_file           = fullfile(list_directory, 'blackrock_list.mat');
communications_file           = fullfile(session_directory, 'communications.csv');
configurations_file           = fullfile(session_directory, 'configurations.json');
events_file                   = fullfile(session_directory, 'events.csv');
psych_ratings_file            = fullfile(session_directory, 'psych_ratings.csv');
psych_scores_file             = fullfile(session_directory, 'psych_scores.csv');
clinician_positive_scale_file = fullfile(session_directory, 'clinician_positive_scale.csv');
events_pulses_file            = fullfile(session_directory, 'pulses.csv');

%%% Initializing variables for session list table row information and to determine relevant processing:

%%% For communications (between experiment task client and Blackrock server)
has_communications = false;
n_communications = 0;

%%% For configurations (time intervals for processing and analysis)
has_configurations = false;
pre_stim_classification_duration = 0;
post_stim_classification_duration = 0;
stim_duration = 0;
post_stim_lockout = 0;
inter_burst_time = 0;
inter_trial_interval = 0;
inter_trial_jitter = 0;

%%% For events
has_events = false;
n_events = 0;

%%% For psych ratings
has_psych_ratings = false;
n_psych_ratings = 0;

%%% For psych scores
has_psych_scores = false;
n_psych_scores = 0;

%%% For clinician scales post injection
has_clinician_scale = false;
post_0m = NaN;
post_10m = NaN;
post_20m = NaN;
post_30m = NaN;
post_45m = NaN;
post_60m = NaN;

%%% For event pulses
has_events_pulses = false;
n_pulses_events = 0;

%%% For injection events
has_injection = false;
injection_start_time = NaN;
injection_end_time = NaN;

%%% For stimulation events
has_stimulation = false;
n_stimulation_events = 0;
n_sham_events = 0;

%%% For recordings
has_nihon_kohden = false;
has_nihon_kohden_sync = {[]};
n_nihon_kohden_recordings = 0;
nihon_kohden_IDs = {[]};
n_pulses_nihon_kohden = {[]};
nihon_kohden_sync_channels = {[]}; 
nihon_kohden_aligned = false;
nihon_kohden_aligned_to_artifact = false;

has_blackrock = false;
has_blackrock_sync = {[]};
n_blackrock_recordings = 0;
blackrock_IDs = {[]};
n_pulses_blackrock = {[]};
blackrock_sync_channels = {[]};
blackrock_aligned = false;
blackrock_aligned_to_artifact = false;

is_aligned = false;
events_processed = false;

%%% Loading of all different event tables and checking events within to gather information

if isfile(communications_file)

    communications = read_communications(communications_file);

    if height(communications) > 0

        has_communications = true;
        n_communications = height(communications);

        message_types = communications.message_type;

        stimulus_type = strcmp(message_types, 'DELIVERING_STIMULUS');
        sham_type = strcmp(message_types, 'SHAMMING');
        
        has_stimulation = any(stimulus_type);

        if has_stimulation
            n_stimulation_events = sum(stimulus_type);
            n_sham_events = sum(sham_type);
        end

    end

end

if isfile(configurations_file)

    configurations = read_configurations(configurations_file);
    has_configurations = true;

    pre_stim_classification_duration  = configurations.pre_stim_classification_duration;
    post_stim_classification_duration = configurations.post_stim_classification_duration;
    stim_duration                     = configurations.stim_duration;
    post_stim_lockout                 = configurations.post_stim_lockout;
    inter_trial_interval              = configurations.inter_trial_interval;
    inter_trial_jitter                = configurations.inter_trial_jitter;
    inter_burst_time                  = configurations.inter_burst_time;

end

if isfile(events_file)

    events = read_events(events_file);

    if height(events) > 0

        has_events = true;
        event_types = events.event_type;
        has_injection = any(contains(event_types, 'INJECTION'));

        if has_injection

            injection_start_index = find(strcmp(event_types, 'INJECTION_START'), 1, 'first');

            if ~isempty(injection_start_index)
                injection_start_time = events.time(injection_start_index) * 1000;
            end

            injection_end_index = find(strcmp(event_types, 'INJECTION_END'), 1, 'last');

            if ~isempty(injection_end_index)
                injection_end_time = events.time(injection_end_index) * 1000;
            end

        end

    end

end

if isfile(psych_ratings_file)

    psych_ratings = read_psych_ratings(psych_ratings_file);

    if height(psych_ratings) > 0
        has_psych_ratings = true;
        n_psych_ratings = height(psych_ratings);
    end

end

if isfile(psych_scores_file)

    psych_scores = read_psych_scores(psych_scores_file);

    if height(psych_scores) > 0    
        has_psych_scores = true;
        n_psych_scores = height(psych_scores);
    end

end

if isfile(clinician_positive_scale_file)
    
    clinician_positive_scale = read_clinician_positive_scale(clinician_positive_scale_file);
    has_clinician_scale = true;
    
    post_0m  = clinician_positive_scale.post_0m;
    post_10m = clinician_positive_scale.post_10m;
    post_20m = clinician_positive_scale.post_20m;
    post_30m = clinician_positive_scale.post_30m;
    post_45m = clinician_positive_scale.post_45m;
    post_60m = clinician_positive_scale.post_60m;

end

if isfile(events_pulses_file)

    events_pulses = read_events_pulses(events_pulses_file);

    if height(events_pulses) > 0
        has_events_pulses = true;
        n_pulses_events = height(events_pulses);
    end

end

%%% Load recording lists and find matching recordings
if isfile(nihon_kohden_list_file)
    
    load(nihon_kohden_list_file, 'nihon_kohden_list');
    nihon_kohden_list(~strcmp(nihon_kohden_list.subject, subject), :) = [];
    
    if height(nihon_kohden_list) > 0

        matching_indices = find_matching_EEGs(nihon_kohden_list, session_info, events_pulses);

        if ~isempty(matching_indices)

            has_nihon_kohden = true;
            n_nihon_kohden_recordings = length(matching_indices);
            nihon_kohden_IDs = {nihon_kohden_list.recording_ID(matching_indices)};
            has_nihon_kohden_sync = {nihon_kohden_list.has_sync(matching_indices)};

        end

    end

end

if isfile(blackrock_list_file)

    load(blackrock_list_file, 'blackrock_list');
    blackrock_list(~strcmp(blackrock_list.subject, subject), :) = [];

    if height(blackrock_list) > 0

        matching_indices = find_matching_EEGs(blackrock_list, session_info, events_pulses);

        if ~isempty(matching_indices)

            has_blackrock = true;
            n_blackrock_recordings = length(matching_indices);
            blackrock_IDs = {blackrock_list.recording_ID(matching_indices)};
            has_blackrock_sync = {blackrock_list.has_sync(matching_indices)};

        end

    end

end

%%% Initialize columns for subject_ID and session_ID
subject_ID = NaN;
session_ID = NaN;

%%% Make table row with session information gathered
session_row = table(subject, task, session, ...
    has_communications, n_communications, ...
    has_configurations, pre_stim_classification_duration, ...
    post_stim_classification_duration, stim_duration, post_stim_lockout, ...
    inter_trial_interval, inter_trial_jitter, inter_burst_time, ...
    has_events, n_events, ...
    has_psych_ratings, n_psych_ratings, has_psych_scores, n_psych_scores, ...
    has_clinician_scale, post_0m, post_10m, post_20m, post_30m, post_45m, post_60m, ...
    has_events_pulses, n_pulses_events, ...
    has_injection, injection_start_time, injection_end_time, ...
    has_stimulation, n_stimulation_events, n_sham_events, ...
    has_nihon_kohden, n_nihon_kohden_recordings, nihon_kohden_IDs, ...
    has_nihon_kohden_sync, n_pulses_nihon_kohden, nihon_kohden_sync_channels, ...
    nihon_kohden_aligned, nihon_kohden_aligned_to_artifact, ...
    has_blackrock, n_blackrock_recordings, blackrock_IDs, ...
    has_blackrock_sync, n_pulses_blackrock, blackrock_sync_channels, ...
    blackrock_aligned, blackrock_aligned_to_artifact, ...
    is_aligned, events_processed, subject_ID, session_ID);

end