function n02_make_electrode_list(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');

%%% Load subject list file
load(fullfile(list_directory, 'subject_list.mat'), 'subject_list');

%%% Load session list
load(fullfile(list_directory, 'session_list.mat'), 'session_list');

%%% Loop through sessions and gather hippocampal channels (only those where
%%% neurologist and automatic localization match).
session_electrodes = cell(height(session_list), 1);
bad_coordinate_subjects = [];

for idx = 1:height(session_list)    
    this_session = session_list(idx, :);
    session_electrodes{idx} = n00_get_subject_electrodes(this_session);
end

%%% Concatenate all session electrode tables
electrode_list = vertcat(session_electrodes{:});

%%% Give each electrode a unique low memory ID for making tables,
%%% for use as categorical variable in random effects of LME, an for easier
%%% identification and filtering of exclusions.
[~, ~, electrode_ID] = unique(strcat(electrode_list.subject, electrode_list.label));
electrode_list.electrode_ID = uint16(electrode_ID);

%%% Save lists
save(fullfile(list_directory, 'subject_list.mat'), 'subject_list');
save(fullfile(list_directory, 'session_list.mat'), 'session_list');
save(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
save(fullfile(list_directory, 'bad_coordinate_subjects.mat'), 'bad_coordinate_subjects');

end