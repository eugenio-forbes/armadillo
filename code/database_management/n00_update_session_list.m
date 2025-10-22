%%% This function will search for behavioral data in a given subject's directory.
%%% It will gather all available information for a given experimental session,
%%% match the behavioral session to Nihon Kohden and Blackrock Neurotech recordings,
%%% and update saved session list with this information.
%%% Function returns logical variable indicating whether behavioral sessions were found
%%% for master function to continue with processing steps if true.

function has_behavioral_sessions = n00_update_session_list(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end


%%% Declare directories and files
list_directory       = fullfile(analysis_directory, 'lists');
subject_directory    = fullfile(analysis_directory, 'subject_files', subject);
behavioral_directory = fullfile(subject_directory, 'behavioral');
session_list_file    = fullfile(list_directory, 'session_list.mat');

%%% List task folders within behavioral directory
task_folders = dir(behavioral_directory);
bad_folders = contains({task_folders.name}, {'.', '..', '._', '~'});
task_folders(bad_folders) = [];
tasks = {task_folders.name};

%%% For now will exclude anything that is not PS 
tasks = tasks(strcmp(tasks, 'PS'));

%%% Loop through task folders to gather information about sessions completed
behavioral_sessions = [];

if ~isempty(tasks)
    
    n_tasks = length(tasks);
    task_sessions = cell(n_tasks, 1);
    
    for idx = 1:n_tasks
    
        task_directory = fullfile(behavioral_directory, tasks{idx});
        
        session_folders = dir(task_directory);
        not_directory = ~[session_folders.isdir];
        session_folders(not_directory) = [];
        bad_folders = contains({session_folders.name}, {'.', '..'});
        session_folders(bad_folders) = [];
        
        if ~isempty(session_folders)
        
            n_sessions = length(session_folders);
            session_date_strings = {session_folders.name};
            
            if ~iscolumn(session_date_strings)
                session_date_strings = session_date_strings';
            end
            
            sessions = table;
            sessions.subject = repelem({subject}, n_sessions, 1);
            sessions.task    = repelem(tasks(idx), n_sessions, 1);
            sessions.session = session_date_strings;
            
            task_sessions{idx} = sessions;
            
        end
        
    end
    
    behavioral_sessions = vertcat(task_sessions{:});
    [~, sorting_index] = sortrows(behavioral_sessions.session, 'ascend');
    behavioral_sessions = behavioral_sessions(sorting_index, :);

end

has_behavioral_sessions = ~isempty(behavioral_sessions);

%%% Loop through sessions, process and align events, and update saved session list
if has_behavioral_sessions

    session_date_strings = behavioral_sessions.session;
    session_dates = datetime(session_date_strings, 'InputFormat', 'yyyy-MM-dd_HH-mm-SS');
    [~, sorting_indices] = sort(session_dates, 'ascend');
    behavioral_sessions = behavioral_sessions(sorting_indices, :);

    n_behavioral_sessions = height(behavioral_sessions);
    
    if isfile(session_list_file)
    
        load(session_list_file, 'session_list');

        subjects = session_list.subject;
        tasks    = session_list.task;
        sessions = session_list.session;

        max_session_ID = max(session_list.session_ID);
        is_unprocessed = ~ismember(behavioral_sessions.subject, subjects) & ~ismember(behavioral_sessions.task, tasks) & ~ismember(behavioral_sessions.session, sessions);
    
    else
    
        session_list = [];
        max_session_ID = 0;
        is_unprocessed = true(n_behavioral_sessions, 1);
        
    end

    session_rows = cell(n_behavioral_sessions, 1);
    
    %%% Loop through every session. Information may change in time with the addition of recordings or clinician files.
    for idx = 1:n_behavioral_sessions
    
        this_session = behavioral_sessions(idx, :);
        session_rows{idx} = get_PS_events_info(analysis_directory, this_session); %%% Function that processes and aligns events
        
        if is_unprocessed(idx)
            
            if ~isempty(session_rows{idx})
                max_session_ID = max_session_ID + 1;
                session_rows{idx}.session_ID = max_session_ID;
            end
            
        else
        
            has_subject = strcmp(subjects, this_session.subject{:});
            has_task    = strcmp(tasks, this_session.task{:});
            has_session = strcmp(sessions, this_session.session{:});
            
            list_index = find(has_subject & has_task & has_session);
            
            session_list.has_clinician_scale(list_index) = session_rows{idx}.has_clinician_scale;
            session_list.has_blackrock(list_index)       = session_rows{idx}.has_blackrock;
            session_list.has_nihon_kohden(list_index)    = session_rows{idx}.has_nihon_kohden;
            
        end
        
    end
    
    %%% Save updated session list
    session_rows = vertcat(session_rows{is_unprocessed});
    session_list = [session_list; session_rows];
    save(session_list_file, 'session_list');
    
end

end