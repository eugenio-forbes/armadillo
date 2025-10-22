function n10_AR_behavioral_analysis_any(varargin)
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

%%% Declare directories
analysis_directory   = fullfile(root_directory, username, analysis_folder_name);
list_directory       = fullfile(analysis_directory, 'lists');
data_directory       = fullfile(analysis_directory, 'data');
statistics_directory = fullfile(analysis_directory, 'statistics/behavioral/any');
plots_directory      = strrep(statistics_directory, 'statistics', 'plots');

if ~isfolder(statistics_directory)
    mkdir(statistics_directory);
end

if ~isfolder(plots_directory)
    mkdir(plots_directory);
end

%%% Load table with events info
load(fullfile(list_directory, 'events_info.mat'), 'events_info');

%%% List included linear mixed effects variables, event categories, and make table with parameters for analyses
analysis_info = struct;
analysis_info.data_directory                       = data_directory;
analysis_info.analysis_type                        = 'behavioral';
analysis_info.analysis_level_selections            = {'task_phase', 'characteristics', 'other_characteristics'};
analysis_info.condition_selections                 = {'any', 'control', 'none', 'scopolamine', 'stimulation'};
analysis_info.outcome_selections                   = {'responded_yes', 'correct_yes', 'press'};
analysis_info.outcome_groupings                    = {{'responded_yes'}, {'correct_yes'}, {'responded_yes', 'correct_yes'}, {'press'}};
analysis_info.outcome_label                        = {'f_responded', 'f_correct', 'f_responded_correct', 'response_time'};
analysis_info.task_phase_selections                = {'encoding', 'retrieval'};
analysis_info.task_phase_characteristic_selections = {'answer', 'response'};
analysis_info.task_phase_characteristic_groupings  = {{'answer'}, {'response'}, {'answer', 'response'}};
analysis_info.other_selections                     = {'any', 'top', 'bottom', 'first', 'second'};
analysis_info.other_characteristic_selections      = {'answer', 'response'};
analysis_info.other_characteristic_groupings       = {{'answer'}, {'response'}, {'answer', 'response'}};
analysis_info.random_effect_hierarchy              = {'subject_ID', 'session_ID', 'block_ID', 'event_ID'};
analysis_info.random_effect_level_selections       = {'subject_ID', 'session_ID', 'block_ID'};
analysis_info.random_effect_groupings              = {{'subject_ID', 'block_ID'}};
analysis_info.lme_levels                           = {'block_ID', 'block_ID', 'block_ID', 'event_ID'};
analysis_info.correlation_levels                   = {'subject_ID', 'subject_ID', 'subject_ID', 'subject_ID'};
analysis_info.boxplot_levels                       = {'subject_ID', 'subject_ID', 'subject_ID', 'subject_ID'};

[all_events, analysis_parameters] = n00_get_analysis_parameters(events_info, analysis_info);

n_analyses = height(analysis_parameters);

for idx = 1:n_analyses
    
    n00_AR_behavioral_analysis_single(plots_directory, all_events, analysis_info, analysis_parameters(idx, :), idx)    
        
end

end