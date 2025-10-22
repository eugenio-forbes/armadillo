function perform_all_classifications(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    referencing_method = 'bipolar';
    cleaning_method = 'none';
    event_offset = 0;
    sample_size = 1200;
    buffer_duration = 750;
    frequencies = [4];
    morlet_width = 5;
    n_normalization_events = 25;
    n_workers = 24;
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    referencing_method = varargin{4};
    cleaning_method = varargin{5};
    event_offset = varargin{6};
    sample_size = varargin{7};
    buffer_duration = varargin{8};
    frequencies = varargin{9};
    morlet_width = 5;
    n_normalization_events = 25;
    n_workers = 24;
end

%%% Initialize parpool
pool_object = gcp('nocreate');
if isempty(pool_object)
    parpool(n_workers)
end

%%% Declare directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');
plot_directory = fullfile(analysis_directory, 'plots/logistic_regression', referencing_method, cleaning_method);
if ~isfolder(plot_directory)
    mkdir(plot_directory);
end

%%% Load lists
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
load(fullfile(list_directory, 'session_list.mat'), 'session_list');

no_bipolar_reference = ~electrode_list.has_bipolar_reference;

electrode_list.bipolar_reference(no_bipolar_reference) = repelem({int32(0)}, sum(no_bipolar_reference), 1);
electrode_list.bipolar_reference = cell2mat(electrode_list.bipolar_reference);
electrode_list.bipolar_label = n00_get_bipolar_labels(electrode_list);

electrode_list(no_bipolar_reference, :) = [];
electrode_list.reference = electrode_list.bipolar_reference;

n_sessions = height(session_list);

all_features = cell(n_sessions, 1);
all_classes = cell(n_sessions, 1);
all_events = cell(n_sessions, 1);
all_groups = cell(n_sessions, 1);
all_electrode_lists = cell(n_sessions, 1);

for idx = 1:n_sessions

    this_session = session_list(idx, :);
    subject = this_session.subject{:};
    task = this_session.task{:};
    session = this_session.session{:};
    session_ID = this_session.session_ID;
    
    events_file = fullfile(data_directory, subject, task, session, 'events.mat');
    load(events_file, 'events');
    
    events(~contains(events.event, {'ENC', 'RET'}), :) = [];
    events.eegfile = regexprep(events.eegfile, 'eeg.reref', 'eeg.noreref');
    
    blocks = events.block;
    
    practice_block = isnan(blocks);
    blocks(practice_block) = zeros(sum(practice_block), 1);
    
    all_groups{idx} = blocks;
    all_events{idx} = events;
    all_classes{idx} = double(contains(events.event, 'ENC'));
    
    this_electrode_list = electrode_list(electrode_list.session_ID == session_ID, :);
    channels = this_electrode_list.channel_number;
    [~, sorting_idx] = sortrows(channels, 'ascend');
    this_electrode_list = this_electrode_list(sorting_idx, :);
    
    all_electrode_lists{idx} = this_electrode_list;
    all_features{idx} = n00_get_features(this_electrode_list, events, sample_size, event_offset, buffer_duration, frequencies, morlet_width, n_normalization_events);

end
 
session_IDs = session_list.session_ID;
regularizations = [2; 1; 0];

[Ax, Bx]= ndgrid(1:numel(regularizations), 1:numel(session_IDs));

combinations = table;
combinations.session_ID     = session_IDs(Bx(:));
combinations.regularization = regularizations(Ax(:));

n_combinations = height(combinations);

classifier_results = cell(n_combinations, 1);

for idx = 1:n_combinations

    session_ID = combinations.session_ID(idx);
    regularization = combinations.regularization(idx);
    
    session_idx = session_IDs == session_ID;
    this_session = session_list(session_idx, :);
    
    electrode_list = all_electrode_lists{session_idx};
    events = all_events{session_idx};
    classes = all_classes{session_idx};
    features = all_features{session_idx};
    groups = all_groups{session_idx};
    
    subject = this_session.subject{:};
    task = this_session.task{:};
    session = this_session.session{:};
    channel_labels = electrode_list.bipolar_label;
    bipolar_jacksheet_file = sprintf('%s_20240703_bi_L0M0.csv', subject);
    excluded_channels = '<{}>';
    
    switch num2str(regularization)
        case '0'
            classifier_results{idx} = n00_single_subject_logistic_regression(classes, features, groups);
        
        case '1'
            classifier_results{idx} = n00_single_subject_lasso_regression(classes, features, groups);
        
        case '2'
            classifier_results{idx} = n00_single_subject_ridge_regression(classes, features, groups);
    end

    file_name = sprintf('classifier_%s_%s_%s_L%d.json', subject, task, session, regularization);
    
    n00_write_classifier_json(file_name, regularization, classes, features, classifier_results{idx}, channel_labels, frequencies, excluded_channels, bipolar_jacksheet_file)

end

save('classifier_results.mat', 'classifier_results');

end