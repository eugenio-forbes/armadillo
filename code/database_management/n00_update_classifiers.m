%%% For a given subject, this function will make a list of all possible
%%% combinations of recording systems, classification types, and logistic regression regularizations.
%%% Electrophysiologic features are extracted for every event based on configurations in the same manner
%%% as Elemem software.
%%% An individual classifier is trained using all available data for each combination.
%%% Classifier weights are saved in the format expected by Elemem software for closed-loop parameter search.

function n00_update_classifiers(varargin)
if isempty(varargin)
    analysis_directory = '/path/to/armadillo';
    subject = 'SC000';
else
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Set variables

%%% Analysis parameters. Bipolar reference and no filtering current method in Elemem
event_offset = 0;
buffer_duration = 500;
frequencies = [3, 7, 17, 37, 79, 161]; %%% Prime numbers to avoid any sort of crap
morlet_width = 5;
n_normalization_events = 25;

%%% Combination parameters
recording_systems = {'nihon_kohden'; 'blackrock'};
classification_types = {'even-odd-injection'; 'pre-post-injection'; 'low-high-clinician'};
regularizations = [2; 1; 0];

n_workers = 24;
%%% Initialize parpool
pool_object = gcp('nocreate');
if isempty(pool_object)
    parpool(n_workers)
end

%%% Declare directories
list_directory       = fullfile(analysis_directory, 'lists');
subject_directory    = fullfile(analysis_directory, 'subject_files', subject);
data_directory       = fullfile(subject_directory, 'concatenated_data');
classifier_directory = fullfile(subject_directory, 'classifiers');
if ~isfolder(classifier_directory)
    mkdir(classifier_directory);
end

%%% Search for stimulation parameter search configurations to get duration of events
configurations_search = dir(fullfile(subject_directory, 'behavioral/**/configurations.json'));
if ~isempty(cofigurations_search)
    cofigurations_search = configurations_search(1);
    configurations_file = fullfile({configurations_search.folder}, {configurations.name});
    configurations = read_configurations(configurations_file);
    sample_size = configurations.pre_stim_classification_duration;
else
    sample_size = 1200;
end


%%% Load session and electrode lists and filter for those from subject that are aligned.
load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

session_list(~strcmp(session_list.subject, subject), :) = [];
session_list(~session_list.is_aligned, :) = [];

if isempty(session_list)
    fprintf('%s did not have any aligned sessions to classify', subject);
end

nihon_kohden_aligned = any(session_list.blackrock_aligned);
blackrock_aligned = any(session_list.blackrock_aligned);

%%% Based on alignment indicate which systems are available for inclusion in combinations
if nihon_kohden_aligned && blackrock_aligned    
    system_indices = [1; 2];
elseif nihon_kohden_aligned
    system_indices = 1;
elseif blackrock_aligned
    system_indices = 2;
end

%%% Filter out electrode that do not have bipolar reference and set bipolar reference
session_IDs = session_list.session_ID;
electrode_list(~ismember(electrode_list.session_ID, session_IDs), :) = [];
[~, unique_indices, ~] = unique(electrode_list.channel_number);
electrode_list = electrode_list(unique_indices, :);

no_bipolar_reference = ~electrode_list.has_bipolar_reference;
electrode_list.bipolar_reference = electrode_list.bipolar_reference;
electrode_list.bipolar_label = n00_get_bipolar_labels(electrode_list);
electrode_list(no_bipolar_reference, :) = [];
electrode_list.reference = electrode_list.bipolar_reference;

%%% Initialize variables to hold all event features, one for each recording system
all_features = cell(2, 1);
all_events = cell(2, 1);

channels = electrode_list.channel_number;
[~, sorting_idx] = sortrows(channels, 'ascend');
electrode_list = electrode_list(sorting_idx, :);

if nihon_kohden_aligned
    events_file = fullfile(data_directory, 'nihon_kohden/events.mat');
    load(events_file, 'events');
    all_features{1} = n00_get_features(electrode_list, events, sample_size, event_offset, buffer_duration, frequencies, morlet_width, n_normalization_events);
    all_events{1} = events;
end

if blackrock_aligned
    events_file = fullfile(data_directory, 'blackrock/events.mat');
    load(events_file, 'events');
    all_features{2} = n00_get_features(electrode_list, events, sample_size, event_offset, buffer_duration, frequencies, morlet_width, n_normalization_events);
    all_events{2} = events;
end

%%% Make table listing all combinations for classifier training
[Ax, Bx, Cx]= ndgrid(1:numel(regularizations), 1:numel(classification_types), 1:numel(system_indices));

combinations = table;

combinations.system_index        = system_indices(Cx(:));
combinations.recording_system    = recording_systems(Cx(:));
combinations.classification_type = classification_types(Bx(:));
combinations.regularization      = regularizations(Ax(:));

n_combinations = height(combinations);

combinations.channels            = repelem({channels}, n_combinations, 1);
combinations.frequencies         = repelem({frequencies}, n_combinations, 1);

%%% Variables that go into classifier file input to Elemem
todays_date = char(datestr(datetime('now', 'Format', 'yyyyMMdd')));
channel_labels = electrode_list.bipolar_label;
bipolar_jacksheet_file = sprintf('%s_%s_bi_L0M0.csv', subject, todays_date);
excluded_channels = '<{}>';

%%% Initialize variable that will hold classifier results for each combination
classifier_results = cell(n_combinations, 1);

%%% Loop through combinations, filter for appropriate events based on classification type, train classifiers and write Elemem configurations files
for idx = 1:n_combinations

    system_index        = combinations.system_index(idx);
    recording_system    = combinations.recording_system{idx};
    classification_type = combinations.classification_type{idx};
    regularization      = combinations.regularization(idx);
    
    features = all_features{system_index};
    events = all_events{system_index};

    switch classification_type
        case 'even-odd-injection'
            excluded_events = events.injectionless | ~events.injection_administered;
        
        case {'pre-post-injection', 'low-high-clinician'}
            excluded_events = events.injectionless;
    end

    events(excluded_events, :) = [];
    features(excluded_events, :) = [];
    n_events = height(events);

    switch classification_type
        case 'even-odd-injection'
            classes = events.is_even;
        
        case 'pre-post-injection'
            classes = ~events.injection_administered;
        
        case 'low-high-clinician'
            mean_score = mean(events.clinician_scale);
            classes = events.clinician_scale <= mean_score;
    end

    groups = randi([1, 10], n_events, 1);
    
    switch num2str(regularization)
        case '0'
            classifier_results{idx} = n00_single_subject_logistic_regression(classes, features, groups);
        
        case '1'
            classifier_results{idx} = n00_single_subject_lasso_regression(classes, features, groups);
        
        case '2'
            classifier_results{idx} = n00_single_subject_ridge_regression(classes, features, groups);
    end

    file_name = sprintf('classifier_%s_%s_%s_L%d.json', recording_system, subject, classification_type, regularization);
    file_name = fullfile(classifier_directory, file_name);
    
    n00_write_classifier_json(file_name, regularization, classes, features, classifier_results{idx}, channel_labels, frequencies, excluded_channels, bipolar_jacksheet_file)
    
end

%%% Save classifier results for all combinations
combinations.classifier_results = classifier_results;
save(fullfile(classifier_directory, 'combinations.mat'), 'combinations');

end