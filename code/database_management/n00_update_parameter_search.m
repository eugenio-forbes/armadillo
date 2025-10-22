%%% This function will gather a subject's saved classifier weights
%%% for each combination of recording system, classifier type,
%%% and regularization. Classifier is used to get classification
%%% probabilities before and after stimulation delivery to assess
%%% which combination of stimulation parameters leads to more positive
%%% changes in classifier results. ROC curve of classifier, and parameter
%%% search results are plotted.

function n00_update_parameter_search(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories
list_directory           = fullfile(root_directory, 'lists');
subject_directory        = fullfile(root_directory, 'subject_files', subject);
data_directory           = fullfile(subject_directory, 'concatenated_data');
classifier_directory     = fullfile(subject_directory, 'classifiers');
nihon_kohden_events_file = fullfile(data_directory, 'nihon_kohden/stimulation_events.mat');
blackrock_events_file    = fullfile(data_directory, 'blackrock/stimulation_events.mat');
combinations_file        = fullfile(classifier_directory, 'combinations.mat');

%%% Search for stimulation parameter search configurations to get duration of events
configurations_search = dir(fullfile(subject_directory, 'behavioral/**/configurations.json'));
if ~isempty(cofigurations_search)
    cofigurations_search = configurations_search(1);
    configurations_file = fullfile({configurations_search.folder}, {configurations.name});
    configurations = read_configurations(configurations_file);
else
    configurations = struct;
    configurations.pre_stim_classification_duration = 1200;
    configurations.post_stim_classification_duration = 1200;
    configurations.stim_duration = 500;
    configurations.post_stim_lockout = 400;
end

%%% Load session and electrode lists and filter for those corresponding to subject that are aligned
load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

session_list(~strcmp(session_list.subject, subject), :) = [];
session_list(~session_list.is_aligned, :) = [];

%%% Reduce electrode list to unique electrodes using channel number and filter out electrodes without bipolar reference
session_IDs = session_list.session_ID;
electrode_list(~ismember(electrode_list.session_ID, session_IDs), :) = [];
[~, unique_indices, ~] = unique(electrode_list.channel_number);
electrode_list = electrode_list(unique_indices, :);

no_bipolar_reference = ~electrode_list.has_bipolar_reference;
electrode_list.bipolar_reference = electrode_list.bipolar_reference;
electrode_list.bipolar_label = n00_get_bipolar_labels(electrode_list);
electrode_list(no_bipolar_reference, :) = [];
electrode_list.reference = electrode_list.bipolar_reference;

%%% Load stimulation events aligned to each recording system
if isfile(nihon_kohden_events_file)
    load(nihon_kohden_events_file, 'stimulation_events');
    nihon_kohden_events = stimulation_events;
end

if isfile(blackrock_events_file)
    load(blackrock_events_file, 'stimulation_events');
    blackrock_events = stimulation_events;
end

%%% Load file with combinations of recording systems, classifier types, and regularizations
load(combinations_file, 'combinations');

%%% Loop through combinations to plot classifier ROC, perform peristimulus classifications,
%%% get and plot parameter search results, 

n_combinations = height(combinations);

for idx = 1:n_combinations
    
    combination = combinations(idx, :);
    
    recording_system    = combination.recording_system{:};
    classification_type = combination.classification_type{:};
    regularization      = combination.regularization;

    switch recording_system
        case 'blackrock'
            stimulation_events = blackrock_events;
        
        case 'nihon_kohden'
            stimulation_events = nihon_kohden_events;
    end
    
    plot_file_name = sprintf('ROC_%s_%s_%s_L%d', subject, recording_system, classification_type, regularization);
    
    n00_plot_classifier_ROC(plot_file_name, combination);
    
    solved_events = n01_perform_peristimulus_classifications(electrode_list, stimulation_events, combination, configurations);
    
    PS_results = n02_get_PS_results(solved_events);
    
    plot_file_name = strrep(plot_file_name, 'ROC', 'PS_results');
    
    n03_plot_PS_results(plot_file_name, PS_results);
    
end

end