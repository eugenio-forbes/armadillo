function n00_plot_classifier_weights(varargin)
if isempty(varargin)
    analysis_directory = '/path/to/armadillo';
    subject = 'SC000'
    view_list = {'superior', 'lateral-right', ...
                'medial-right', 'deep-right', ...
                'inferior', 'lateral-left', ...
                'medial-left', 'deep-left'};
else
    analysis_directory = varagin{1};
    subject = varagin{2};
    view_list = varargin{3};
end

%%% Declare directories
list_directory       = fullfile(analysis_directory, 'lists');
subject_directory    = fullfile(analysis_directory, 'subject_files', subject);
classifier_directory = fullfile(subject_directory, 'classifiers');
plot_directory       = fullfile(analysis_directory, 'plots/brain_plots/classifier_weights');
if ~isfolder(plot_directory)
    mkdir(plot_directory);
end

%%% Load electrode list, filter for those from subject, remove those without bipolar reference
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
electrode_list(~ismember(electrode_list.subject, subject), :) = [];
[~, unique_indices, ~] = unique(electrode_list.channel_number);
electrode_list = electrode_list(unique_indices, :);
no_bipolar_reference = ~electrode_list.has_bipolar_reference;
electrode_list(no_bipolar_reference, :) = [];

%%% Load subject's combination table with classifier results
combinations_file = fullfile(classifier_directory, 'combinations.mat');
load(combinations_file, 'combinations');

n_combinations = height(combinations);

%%% Set plot parameters
plot_title_template = [sprintf('%s Classifier Weigths', subject), ' (%s)'];
data_type = 'classifier_weight';
[~, colorbar_struct] = n00_get_color_map(data_type);

plot_parameters = n00_get_plot_parameters(view_list, plot_title_template, colorbar_struct);
plot_parameters.data_type      = data_type;
plot_parameters.root_directory = analysis_directory;
plot_parameters.timeline_mode = 'skip';
plot_parameters.colorbar_mode = 'include';

%%% Loop through combinations, add coefficients from classifier results to electrode list, and plot a single frame of brain plots.
for idx = 1:n_combinations

    recording_system    = combinations.recording_system{idx};
    classification_type = combinations.classification_type{idx};
    regularization      = combinations.regularization(idx);
    classifier_results  = combinations.classifier_results{idx};
    
    electrode_list.value = classifier_results.coefficients;
    
    plot_parameters.plot_title = sprintf(plot_title_template, classification_type);

    plot_filename = fullfile(plot_directory, sprintf('%s_classifier_weights_%s_%s_%s', subject, classification_type, regularization, recording_system));
    plot_parameters.plot_filename  = plot_filename;
    
    figure_handle = figure('Units', 'pixels', 'Visible', 'off');    
    figure_handle.Position(3) = plot_parameters.figure_width;
    figure_handle.Position(4) = plot_parameters.figure_height;
    plot_parameters.figure_handle = figure_handle;
    
    n00_plot_frame(electrode_list, plot_parameters);
    
    print(plot_filename, '-dpng')
    print(plot_filename, '-dsvg')
    
    close all

end

end