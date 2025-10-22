%%% This function gathers all events of a given subject that have been
%%% successfully aligned to recordings, concatenates all events for classifier
%%% training and concatenates all stimulation events for parameter search.
%%% Generates a copy of individual and concatenated events for each electrode
%%% to avoid access to same file during parallel processing of electrode data.

function n00_make_events_copies(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end


%%% Declare directories
list_directory         = fullfile(analysis_directory, 'lists');
subject_directory      = fullfile(analysis_directory, 'subject_files', subject);
data_directory         = fullfile(subject_directory, 'data');
concatenated_directory = fullfile(subject_directory, 'concatenated_data');

%%% Load session and electrode list and filter for subject's sessions that are aligned
load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

session_list(~strcmp(session_list.subject, subject), :) = [];
session_list(~session_list.is_aligned, :) = [];

session_IDs = session_list.session_ID;

electrode_list(~ismember(electrode_list.session_ID, session_IDs), :) = [];

n_sessions = height(session_list);

nihon_kohden_aligned = session_list.nihon_kohden_aligned;
blackrock_aligned    = session_list.blackrock_aligned;

%%% Loop through sessions to save events copies for each electrode to be able to process data with parfor without risking
%%% conflicts from access to files.
events_holder = cell(n_sessions, 2);
stimulation_events_holder = cell(n_sessions, 2);

for idx = 1:n_sessions

    task = session_list.task{idx};
    session = session_list.session{idx};
    session_ID = session_list.session_ID(idx);

    %%% Filter electrode list
    session_electrodes = electrode_list.session_ID == session_ID;
    channel_numbers = electrode_list.channel_number(session_electrodes);

    if nihon_kohden_aligned(idx)
    
        %%% Load events. These save events copies have already been converted to table
        session_directory = fullfile(data_directory, 'nihon_kohden', task, session);
        events_file = fullfile(session_directory, 'events.mat');
        stimulation_events_file = fullfile(session_directory, 'stimulation_events.mat');
        
        if isfile(events_file)
            load(events_file, 'events');
            events_holder{idx, 1} = events;
            par_save(session_directory, channel_numbers, events, 'events');
        end
        
        if isfile(stimulation_events_file)
            load(stimulation_events_file, 'stimulation_events');
            stimulation_events_holder{idx, 1} = stimulation_events;
            par_save(session_directory, channel_numbers, stimulation_events, 'stimulation_events');
        end
        
    end

    if blackrock_aligned(idx)
        
        %%% Load events. These save events copies have already been converted to table
        session_directory = fullfile(data_directory, 'blackrock', task, session);
        events_file = fullfile(session_directory, 'events.mat');
        stimulation_events_file = fullfile(session_directory, 'stimulation_events.mat');
        
        if isfile(events_file)
            load(events_file, 'events');
            events_holder{idx, 2} = events;
            par_save(session_directory, channel_numbers, events, 'events');
        end
        
        if isfile(stimulation_events_file)
            load(stimulation_events_file, 'stimulation_events');
            stimulation_events_holder{idx, 2} = stimulation_events;
            par_save(session_directory, channel_numbers, stimulation_events, 'stimulation_events');
        end
    
    end

end

if any(nihon_kohden_aligned)

    save_directory = fullfile(concatenated_directory, 'nihon_kohden');
    if ~isfolder(save_directory)
        mkdir(save_directory);
    end
    
    events_file = fullfile(save_directory, 'events.mat');
    events = vertcat(events_holder{:, 1});
    if ~isempty(events)
        save(events_file, 'events');
        par_save(save_directory, channel_numbers, events, 'events');
    end
    
    stimulation_events_file = fullfile(save_directory, 'stimulation_events.mat');
    stimulation_events = vertcat(stimulation_events_holder{:, 1});
    if ~isempty(stimulation_events)
        save(stimulation_events_file, 'stimulation_events');
        par_save(save_directory, channel_numbers, stimulation_events, 'stimulation_events');
    end
    
end

if any(blackrock_aligned)

    save_directory = fullfile(concatenated_directory, 'blackrock');
    if ~isfolder(save_directory)
        mkdir(save_directory);
    end
    
    events_file = fullfile(save_directory, 'events.mat');
    events = vertcat(events_holder{:, 2});
    if ~isempty(events)
        save(events_file, 'events');
        par_save(save_directory, channel_numbers, events, 'events');
    end
    
    stimulation_events_file = fullfile(save_directory, 'stimulation_events.mat');
    stimulation_events = vertcat(stimulation_events_holder{:, 2});
    if ~isempty(stimulation_events)
        save(stimulation_events_file, 'stimulation_events');
        par_save(save_directory, channel_numbers, stimulation_events, 'stimulation_events');
    end
    
end

end


function par_save(session_directory, channel_numbers, events, variable_name)

n_channels = length(channel_numbers);

has_stimulation = contains(variable_name, 'stimulation');

if has_stimulation
    stimulation_events = events;
end

for idx = 1:n_channels

    this_channel = channel_numbers(idx);
    
    save_path = fullfile(session_directory, num2str(this_channel));
    if ~isfolder(save_path)
        mkdir(save_path);
    end
    
    file_name = fullfile(save_path, sprintf('%s.mat', variable_name));
    if has_stimulation
        save(file_name, 'stimulation_events');
    else
        save(file_name, 'events');
    end

end

end