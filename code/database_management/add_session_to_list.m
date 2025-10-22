function add_session_to_list(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    subject = 'SC000';
    task = 'task-name';
    session = 'session_0';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    
end

%%%% Before you add a session to the list, it is necessary that in the
%%%% subject_files directory of the analysis folder, you have
%%%% depth_el_info.txt and behavioral files (events.mat, pulses.txt) 
%%%% for the respective session.

%%%%%% Declare directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
subject_directory = fullfile(analysis_directory, 'configurations', subject);
list_directory = fullfile(analysis_directory, 'lists');
if ~isfolder(list_directory)
    mkdir(list_directory)
end
data_directory = fullfile(analysis_directory, 'data');
if ~isfolder(data_directory)
    mkdir(data_directory)
end

docs_directory = fullfile(subject_directory, 'docs');

depth_el_info_file = dir(fullfile(docs_directory, '*depth_el_info*.txt'));
depth_el_info_found = ~isempty(depth_el_info_file);

if depth_el_info_found
    depth_el_info_file(contains({depth_el_info_file.name}, {'._', '~'})) = [];
    depth_el_info_file = fullfile({depth_el_info_file.folder}, {depth_el_info_file.name});
    depth_el_info_found = ~isempty(depth_el_info_file);
end

if ~depth_el_info_found
    error('Depth electrode file for %s not found. Did not add session or electrodes to list.\n', subject);
end

session_directory = fullfile(subject_directory, 'behavioral', task, session);
session_folder_exists = isfolder(session_directory);
if ~session_folder_exists
    error('Session folder %s was not found. Please verify the name and that files are present.\n', session_directory);
end

events_mat = fullfile(session_directory, 'events.mat');
events_csv = strrep(events_mat, '.mat', '.csv');
events_mat_exists = isfile(events_mat);
events_csv_exists = isfile(events_csv);
if ~events_mat_exists && ~events_csv_exists
    error('No events files were found within folder for %s %s %s. Session not added to list.\n', subject, task, session);
end

pulses_txt = fullfile(session_directory, 'pulses.txt');
pulses_csv = strrep(pulses_txt, '.txt', '.csv');
pulses_txt_exists = isfile(pulses_txt);
pulses_csv_exists = isfile(pulses_csv);
if ~pulses_txt_exists && ~pulses_csv_exists
    error('No pulses files were found within folder for %s %s %s. Session not added to list.\n', subject, task, session);
end

new_directory = fullfile(data_directory, subject, task, session);
events_save = fullfile(new_directory, 'events.mat');
pulses_save = fullfile(new_directory, 'pulses.txt');
if isfile(events_save) || isfile(pulses_save)
    error(['It appears that the session has already been added.\n', ...
        'If this is not the case, then delete the files in %s manually and try again.\n']);
end

if ~events_mat_exists
    process_events_csv(events_csv);
end

load(events_mat, 'events');
events = struct2table(events);

if ~pulses_txt_exists
    process_pulses_csv(pulses_csv);
end

pulses = readmatrix(pulses_txt);

session_list_file = fullfile(list_directory, 'session_list.mat');
electrode_list_file = fullfile(list_directory, 'electrode_list.mat');
subject_list_file = fullfile(list_directory, 'subject_list.mat');

if isfile(subject_list_file)

    load(subject_list_file, 'subject_list');
    
    subject_match = strcmp(subject_list.subject, subject);
    already_added = any(subject_match);
    
    if already_added
    
        subject_idx = find(subject_match);
        n_sessions = subject_list.n_sessions(subject_idx);
        subject_list.n_sessions(subject_idx) = n_sessions + 1;
        
        new_subject_row = subject_list(subject_idx, :);
        
    else
    
        max_ID = max(subject_list.subject_ID);
        new_ID = max_ID + 1;
        
        new_subject_row = make_new_row(subject_list);
        
        new_subject_row.subject    = {subject};
        new_subject_row.n_sessions = 1;
        new_subject_row.subject_ID = new_ID;
        
        subject_list = [subject_list; new_subject_row];
        
    end 
    
else
    
    new_subject_row = table;
    
    new_subject_row.subject    = {subject};
    new_subject_row.n_sessions = 1;
    new_subject_row.subject_ID = 1;
    
    subject_list = new_subject_row;
    
end

if isfile(session_list_file)

    load(session_list_file, 'session_list');
    
    has_subject = strcmp(session_list.subject, subject);
    has_task = strcmp(session_list.task, task);
    has_session = strcmp(session_list.session, session);
    
    session_match = has_subject & has_task & has_session;
    
    already_added = any(session_match);
    
    if ~already_added
    
        max_ID = max(session_list.session_ID);
        new_ID = max_ID + 1;
        
        new_session_row = make_new_row(session_list);
        
        new_session_row.subject    = {subject};
        new_session_row.task       = {task};
        new_session_row.session    = {session};
        new_session_row.subject_ID = new_subject_row.subject_ID;
        new_session_row.session_ID = new_ID;
        
        session_list = [session_list; new_session_row];
        
    else
        new_session_row = session_list(session_match, :);
    end
     
else

    new_session_row = table;
    
    new_session_row.subject    = {subject};
    new_session_row.task       = {task};
    new_session_row.session    = {session};
    new_session_row.subject_ID = 1;
    new_session_row.session_ID = 1;
    
    session_list = new_session_row;
    
end

new_electrodes = n00_get_subject_electrodes(new_session_row);
n_electrodes = height(new_electrodes);

if isfile(electrode_list_file)

    load(electrode_list_file, 'electrode_list');
    
    has_subject = strcmp(electrode_list.subject, subject);
    has_task = strcmp(electrode_list.task, task);
    has_session = strcmp(electrode_list.session, session);
    
    session_match = has_subject & has_task & has_session;
    
    already_added = any(session_match);
    
    if ~already_added
    
        max_ID = max(electrode_list.session_ID);
        new_IDs = max_ID + 1:max_ID + n_electrodes;
        new_electrodes.electrode_ID = new_IDs';
        
        electrode_list = [electrode_list; new_electrodes];
    
    else
        
        if sum(session_match) ~= n_electrodes
            error(['Electrodes for this session had previously been added, \n', ...
                'but do not match in number with previous configuration.\n', ...
                'Please verify and delete records manually if needed before trying again.\n']);
        end
    
    end 

else
    electrode_list = new_electrodes;
end

fprintf('%s %s %s and electrodes were succesfully added to respective lists.\n', subject, task, session);

save(subject_list_file, 'subject_list');
save(session_list_file, 'session_list');
save(electrode_list_file, 'electrode_list');

if ~isfolder(new_directory)
    mkdir(new_directory);
end

save(events_save, 'events');

writematrix(pulses, pulses_save);

check_alignment(root_directory, subject, task, session);

end


function new_row = make_new_row(list_table)

variable_names = list_table.Properties.VariableNames;
n_variables = length(variable_names);
new_elements = repelem(missing(), 1, n_variables);

new_row = cell2table(new_elements);
new_row.Properties.VariableNames = variable_names;

end