%%% This function will summarize information for a subject
%%% gathered from saved session and electrode lists.
%%% Saves updated subject list.

function n00_update_subject_list(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories and files
list_directory      = fullfile(analysis_directory, 'lists');
subject_list_file   = fullfile(list_directory, 'subject_list.mat');
session_list_file   = fullfile(list_directory, 'session_list.mat');
electrode_list_file = fullfile(list_directory, 'electrode_list.mat');

%%% Load subject list and extract subject's row, or make a new row.
if isfile(subject_list_file)

    load(subject_list_file, 'subject_list');
    subjects = subject_list.subject;
    n_subjects = length(subjects);
    has_subject = ismember(subject, subjects);
    
    if has_subject
        
        subject_index = find(strcmp(subjects, subject));
        subject_ID = subject_list.subject_ID(idx);
        subject_list(subject_index, :) = [];
   
    else  
        subject_ID = n_subjects + 1; 
    end
    
else
    subject_list = [];
    subject_ID = 1;
end

%%% Load session and electrode lists and filter for those from subject
load(session_list_file, 'session_list');
load(electrode_list_file, 'electrode_list');

match_session = strcmp(session_list.subject, subject);
match_electrodes = strcmp(electrode_list.subject, subject);

n_match_session = sum(match_session);
n_match_electrodes = sum(match_electrodes);

if n_match_session > 0

    subject_sessions = session_list(match_session, :);
    subject_electrodes = electrode_list(match_electrodes, :);
    
    session_list(match_session, :) = [];
    electrode_list(match_electrodes, :) = [];
     
    %%% Summarize session and electrode information
    n_sessions                         = height(subject_sessions);
    n_electrodes                       = length(unique(subject_electrodes.label));
    n_communications_files             = sum(session_list.has_communications);
    n_configurations_files             = sum(session_list.has_configurations);
    has_events                         = any(session_list.has_events);
    n_events_sessions                  = sum(session_list.has_events);
    n_events                           = sum(session_list.n_events);
    has_psych_ratings                  = any(session_list.has_psych_ratings);
    n_psych_ratings_sessions           = sum(session_list.has_psych_ratings);
    n_psych_ratings                    = sum(session_list.n_psych_ratings);
    has_psych_scores                   = any(session_list.has_psych_scores);
    n_psych_scores_sessions            = sum(session_list.has_psych_sores);
    n_psych_scores                     = sum(session_list.n_psych_scores);
    has_clinician_scale                = any(session_list.has_clinician_scale);
    n_clinician_scale_sessions         = sum(session_list.has_clinician_scale);
    mean_post_0m                       = mean(session_list.post_0m(session_list.has_clinician_scale));
    mean_post_10m                      = mean(session_list.post_10m(session_list.has_clinician_scale));
    mean_post_20m                      = mean(session_list.post_20m(session_list.has_clinician_scale));
    mean_post_30m                      = mean(session_list.post_30m(session_list.has_clinician_scale));
    mean_post_45m                      = mean(session_list.post_45m(session_list.has_clinician_scale));
    mean_post_60m                      = mean(session_list.post_60m(session_list.has_clinician_scale));
    n_events_pulses_files              = sum(session_list.has_events_pulses);
    has_injection                      = any(session_list.has_injection);
    n_injection_sessions               = sum(session_list.has_injection);
    has_stimulation_events             = any(session_list.has_stimulation);
    n_stimulation_sessions             = sum(session_list.has_stimulation);
    n_stimulation_events               = sum(session_list.n_stimulation_events);
    n_sham_events                      = sum(session_list.n_sham_events);
    has_nihon_kohden                   = any(session_list.has_nihon_kohden);
    n_nihon_kohden_sessions            = sum(session_list.has_nihon_kohden);
    n_nihon_kohden_recordings          = sum(session_list.n_nihon_kohden_recordings);
    nihon_kohden_IDs                   = vertcat(session_list.nihon_kohden_IDs{:});
    n_nihon_kohden_aligned             = sum(session_list.nihon_kohden_aligned);
    n_nihon_kohden_aligned_to_artifact = sum(session_list.nihon_kohden_aligned_to_artifact);
    has_blackrock                      = any(session_list.has_blackrock);
    n_blackrock_sessions               = sum(session_list.has_blackrock);
    n_blackrock_recordings             = sum(session_list.n_blackrock_recordings);
    blackrock_IDs                      = vertcat(session_list.blackrock_IDs{:});
    n_blackrock_aligned                = sum(session_list.blackrock_aligned);
    n_blackrock_aligned_to_artifact    = sum(session_list.blackrock_aligned_to_artifact);
    n_aligned                          = sum(session_list.is_aligned);
    n_events_processed                 = sum(session_list.events_processed);
    
    %%% Save updated subject list    
    subject_row = table(subject, n_sessions, n_electrodes, ... 
        n_communications_files, n_configurations_files, ...
        has_events, n_events_sessions, n_events, ...
        has_psych_ratings, n_psych_ratings_sessions, n_psych_ratings, ...
        has_psych_scores, n_psych_scores_sessions, n_psych_scores, ...
        has_clinician_scale, n_clinician_scale_sessions, ...
        mean_post_0m, mean_post_10m, mean_post_20m, ...
        mean_post_30m, mean_post_45m, mean_post_60m, ...
        n_events_pulses_files, has_injection, n_injection_sessions, ...
        has_stimulation_events, n_stimulation_sessions, n_stimulation_events, n_sham_events, ...
        has_nihon_kohden, n_nihon_kohden_sessions, n_nihon_kohden_recordings, nihon_kohden_IDs, ...
        n_nihon_kohden_aligned, n_nihon_kohden_aligned_to_artifact, ...
        has_blackrock, n_blackrock_sessions, n_blackrock_recordings, blackrock_IDs, ...
        has_blackrock_sync, n_pulses_blackrock, blackrock_sync_channels, ...
        n_blackrock_aligned, n_blackrock_aligned_to_artifact, ...
        n_aligned, n_events_processed, subject_ID);
    
    subject_list = [subject_list; subject_row];
    save(subject_list_file, 'subject_list');
    
    %%% Add subject ID to session and electrode lists and save
    subject_sessions.subject_ID = repmat(subject_ID, n_match_session, 1);
    subject_electrodes.subject_ID = repmat(subject_ID, n_match_electrodes, 1);
    
    session_list = [session_list; subject_sessions];
    save(session_list_file, 'session_list');
    
    electrode_list = [electrode_list; subject_electrodes];
    save(electrode_list_file, 'electrode_list');
    
end

end