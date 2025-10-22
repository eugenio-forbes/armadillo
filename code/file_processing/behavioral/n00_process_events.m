%%% This function takes as input a session information table row.
%%% Based on session information it will create a unified events files
%%% processing all individual components. For events with no stimulation
%%% it generates events with timing appropriate for classifier training,
%%% and labels them as having or not having injection. Psychiatric ratings,
%%% scores or scales made during the timespan of these events are added.
%%% Stimulation events have computer times adjusted based on 
%%% client-server communications. Saves events in folder specific to 
%%% recording system to which events are aligned.

function n00_process_events(analysis_directory, session_info, recording_system, injection_IDs)

%%% Get session info
subject              = session_info.subject{:};
task                 = session_info.task{:};
session              = session_info.session{:};
has_configurations   = session_info.has_configurations;
has_psych_ratings    = session_info.has_psych_ratings;
has_psych_scores     = session_info.has_psych_scores;
has_clinician_scale  = session_info.has_clinician_scale;
has_injection        = session_info.has_injection;
injection_start_time = session_info.injection_start_time;
injection_end_time   = session_info.injection_end_time;
has_stimulation      = session_info.has_stimulation;

%%% Declare directories
list_directory      = fullfile(analysis_directory, 'lists');
subject_directory   = fullfile(analysis_directory, 'subject_files', subject);
split_directory     = fullfile(subject_directory, 'split', recording_system);
raw_directory       = fullfile(subject_directory, 'raw');
session_directory   = fullfile(subject_directory, 'behavioral', task, session);
alignment_directory = fullfile(subject_directory, 'alignment', recording_system, task, session);
data_directory      = strrep(alignment_directory, 'alignment', 'data');
if ~isfolder(data_directory)
    mkdir(data_directory);
end

%%% Declare files
communications_file           = fullfile(session_directory, 'communications.csv');
configurations_file           = fullfile(session_directory, 'configurations.json');
events_file                   = fullfile(session_directory, 'events.csv');
psych_ratings_file            = fullfile(session_directory, 'psych_ratings.csv');
psych_scores_file             = fullfile(session_directory, 'psych_scores.csv');
clinician_positive_scale_file = fullfile(session_directory, 'clinician_positive_scale.csv');
stimulation_events_file       = fullfile(data_directory, 'stimulation_events.mat');
processed_events_file         = fullfile(data_directory, 'events.mat');
session_list_file             = fullfile(list_directory, 'session_list.mat');
nihon_kohden_list_file        = fullfile(list_directory, 'nihon_kohden_list.mat');
blackrock_list_file           = fullfile(list_directory, 'blackrock_list.mat');
alignment_info_file           = fullfile(alignment_directory, 'alignment_info.mat');

%%% Choose and filter appropriate recording list for obtaining recording file stems
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
recording_folders = recording_list.session;
file_names = recording_list.file_name;
if strcmp(recording_system, 'nihon_kohden')
    recording_folders = append('PS_', recording_folders);
end
file_stems = fullfile(repelem({split_directory}, n_recordings, 1), recording_folders, file_names);
recording_list.file_stem = file_stems;

%%% Regardless of recording system data is aligned to, would need to
%%% fetch parameters_used.mat from blackrock folder to estimate the time
%%% it takes for a message to be sent. Otherwise can assume that
%%% stimulation is delivered the time that client receives a response from
%%% the server, because this response is sent right before stimulation is
%%% commanded.

load(blackrock_list_file, 'blackrock_list');
blackrock_list(~ismember(blackrock_list.recording_ID, session_info.blackrock_IDs{:}), :) = [];
blackrock_folder = blackrock_list.session{1};
delimiter = strfind(blackrock_folder, '/');
parent_folder = blackrock_folder(1:delimiter(1) - 1);
parameters_used_file = fullfile(raw_directory, 'blackrock', parent_folder, 'parameters_used.mat');

%%% Load alignment info
load(alignment_info_file, 'alignment_info')

%%% Process events
events = [];

%%% Get stimulation parameter search configurations to generate events with appropriate timing for classifier training
if has_configurations && isfile(configurations_file)

    configurations = read_configurations(configurations_file);
    
else

    load(session_list_file, 'session_list');
    session_list(~strcmp(session_list.subject, subject), :) = [];
    
    if any(session_list.has_configurations)
        session_index = find(session_list.has_configurations, 1, 'first');
        configurations_file = strrep(configurations_file, task, session_list.task{session_index});
        configurations_file = strrep(configurations_file, session, session_list.session{session_index});
        configurations = read_configurations(configurations_file);
    else
        return; 
    end
    
end

%%% If session had an injection, generate events that take into account injection time
%%% to classify events as injectionless or with injection.

if has_injection

    [~, injection_start_time] = adjust_computer_time(injection_start_time, alignment_info);
    [~, injection_end_time] = adjust_computer_time(injection_end_time, alignment_info);
    
    events = n00_make_injection_events(session_info, injection_start_time, injection_end_time, recording_list, recording_system, configurations);
    n_events = height(events);
    
    session_index = find(injection_IDs == session_info.session_ID);
    even_check = mod(session_index, 2) == 0;
    events.is_even = repmat(even_check, n_events, 1);
     
end

%%% If there was no injection generate events classfied as injectionless and add psychiatric measures
%%% to each individual event based on the time the measure was made.

if has_psych_scores || has_psych_ratings || has_clinician_scale

    if isempty(events) || ~has_injection
        events = n00_make_injectionless_events(session_info, recording_list, recording_system, configurations);
    end
    
    if has_psych_ratings && isfile(psych_ratings_file)
        psych_ratings = read_psych_ratings(psych_ratings_file);
        psych_ratings.mstime = psych_ratings.time * 1000;
        [~, psych_ratings.mstime] = adjust_computer_time(psych_ratings.mstime, alignment_info);
        events = add_psych_ratings(events, psych_ratings);
    end
    
    if has_psych_scores && isfile(psych_scores_file)
        psych_scores = read_psych_scores(psych_scores_file);
        psych_scores.mstime = psych_scores.time * 1000;
        [~, psych_scores.mstime] = adjust_computer_time(psych_scores.mstime, alignment_info);
        events = add_psych_scores(events, psych_scores);
    end
    
    if has_clinician_scale && isfile(clinician_positive_scale_file)
        clinician_scale = read_clinician_positive_scale(clinician_positive_scale_file);
        events = add_clinician_scale(events, clinician_scale);
    end
    
end

if ~isempty(events)
    save(processed_events_file, 'events');
end

%%% Adjust computer event time of stimulation events based on communications file
if has_stimulation

    stimulation_events = process_stimulation_events(session_info, events_file, ...
        communications_file, parameters_used_file, recording_list, recording_system, alignment_info);

    if ~isempty(stimulation_events)
        save(stimulation_events_file, 'stimulation_events');
    end

end

end