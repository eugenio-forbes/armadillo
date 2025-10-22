function n01_search_subjects(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    
    %%% Regular expression to search for tasks included in analysis
    task_name = 'AR*';
    unwanted_keywords = {'place_holders', 'for_any', 'unwanted_keywords'};
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    task_name = varargin{4};
    unwanted_keywords = varargin{5};
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
search_directory = fullfile(root_directory, 'shared/lega_ansir/subjFiles');
list_directory = fullfile(analysis_directory, 'lists');
exclusion_directory = fullfile(analysis_directory, 'exclusion_lists');

%%% Create directories if needed
if ~isfolder(list_directory)
    mkdir(list_directory);
end
if ~isfolder(exclusion_directory)
    mkdir(exclusion_directory);
end

%%% Search for all existing events.mat files for the task searched
search_results = dir(fullfile(search_directory, sprintf('*/behavioral/%s/session*/events.mat', task_name))); %%% There could be more than one session for a given task

%%% Keep only the folder name to extract information from
search_results = {search_results.folder};

%%% Remove search_directory and '/behavioral' from character arrays in search results
search_results = strrep(search_results, search_directory, '');
search_results = strrep(search_results, '/behavioral', '');

%%% Left with /subject/task/session_n for each result

%%% Initialize arrays to hold information of each session remaining
subject = cell(length(search_results), 1);
task = cell(length(search_results), 1);
session = cell(length(search_results), 1);

%%% Loop through search results to extract information
for idx = 1:length(search_results)

    this_result = search_results{idx};
    dash_location = strfind(this_result, '/');
    subject{idx} = this_result(dash_location(1) + 1:dash_location(2) - 1);
    task{idx} = this_result(dash_location(2) + 1:dash_location(3) - 1);
    session{idx} = this_result(dash_location(3) + 1:end);
    
end

%%% Create table with list of all individual sessions found
session_list = table(subject, task, session);

%%% Identify unique subjects
subject = unique(subject);

%%% Determine how many sessions were completed by each subject
n_sessions = cellfun(@(x) sum(strcmp(session_list.subject, x)), subject);

%%% Create table with list of unique subjects to gather subject information
subject_list = table(subject, n_sessions);

%%% Give each subject and session a unique low memory ID for making tables,
%%% for use as categorical variable in random effects of LME, an for easier
%%% identification and filtering of exclusions
subject_list.subject_ID = uint8((1:height(subject_list))');
session_list.session_ID = uint8((1:height(session_list))');
session_list.subject_ID = cellfun(@(x) subject_list(strcmp(subject_list.subject, x), :).subject_ID, session_list.subject);


%%% Exclude sessions with unwanted keywords
has_unwanted_keywords = cellfun(@(x) contains(x, unwanted_keywords, 'IgnoreCase', true), session_list.task);
if sum(has_unwanted_keywords) > 0
    
    excluded_sessions = session_list(has_unwanted_keywords, {'subject', 'task', 'session', 'session_ID', 'subject_ID'});
    excluded_sessions.reason_for_exclusion = repelem({'<unwanted_keywords>'}, height(excluded_sessions), 1);
    
    potentially_excluded_subjects = unique(excluded_sessions.subject_ID);
    not_excluded_subjects = unique(session_list(~has_unwanted_keywords, :).subject_ID);
    
    actually_excluded = ~ismember(potentially_excluded_subjects, not_excluded_subjects);
    
    excluded_subjects_IDs = potentially_excluded_subjects(actually_excluded);
    
    excluded_subjects = subject_list(ismember(subject_list.subject_ID, excluded_subjects_IDs), {'subject', 'subject_ID'});
    excluded_subjects.reason_for_exclusion = repelem({'<unwanted_keywords>'}, height(excluded_subjects), 1);
    
    save(fullfile(exclusion_directory, 'excluded_subjects.mat'), 'excluded_subjects');
    save(fullfile(exclusion_directory, 'excluded_sessions.mat'), 'excluded_sessions');

end

%%% Save lists
save(fullfile(list_directory, 'subject_list.mat'), 'subject_list');
save(fullfile(list_directory, 'session_list.mat'), 'session_list');

end