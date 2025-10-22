function n07_check_electrodes_signal(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    referencing_method = 'bipolar';
    cleaning_method = 'none'; 
    sample_size = 1000;
    n_workers = 24;
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    referencing_method = varargin{4};
    cleaning_method = varargin{5};
    sample_size = varargin{6};
    n_workers = 24;
end

%%% Declare directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');
plot_directory = fullfile(analysis_directory, 'plots/signal_check', referencing_method, cleaning_method);
if ~isfolder(plot_directory)
    mkdir(plot_directory);
end

%%% Load lists
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
load(fullfile(list_directory, 'events_info_recheck.mat'), 'events_info_recheck');

%%% Initialize parpool
pool_object = gcp('nocreate');
if isempty(pool_object)
    parpool(n_workers)
end
 
[electrode_list, events_info] = n00_remove_missing_signal(electrode_list, events_info_recheck);
electrode_list = n00_set_reference(electrode_list, referencing_method);
electrode_list.sample_idx = n00_set_sample_idx(electrode_list, events_info);

n_electrodes = height(electrode_list);
channel_signals = cell(n_electrodes, 1);
reference_signals = cell(n_electrodes, 1);
subjects = electrode_list.subject;
tasks = electrode_list.task;
sessions = electrode_list.session;
session_IDs = electrode_list.session_ID;
electrode_IDs = electrode_list.electrode_ID;
channel_numbers = electrode_list.channel_number;
labels = electrode_list.label;
locations = electrode_list.neurologist_location;
references = electrode_list.reference;
sample_indices = electrode_list.sample_idx;

bad_words = {'Brain Stem', 'Dura Mater', 'Encephalocele', 'Encephalomalacia', ...
    'FCD', 'Heterotopia', 'Isthmus', 'Lesion', 'MCD', 'OUT', 'Putamen', 'Resection', ...
    'Thalamus', 'Tuber'};

locations = regexprep(locations, ['.*(', strjoin(bad_words, '|'), ').*'], '$1');

for idx = 1:n_electrodes

    subject = subjects{idx};
    task = tasks{idx};
    session = sessions{idx};
    channel_number = channel_numbers(idx);
    reference = references{idx};
    sample_idx = sample_indices(idx);
    events_file = fullfile(data_directory, subject, task, session, 'events.mat');
    
    [channel_signals{idx}, reference_signals{idx}] = n00_get_sample_signal(events_file, channel_number, reference, referencing_method, sample_idx, sample_size);

end

empty_channels = cellfun(@isempty, channel_signals);
empty_references = cellfun(@isempty, reference_signals);

n_sessions = height(events_info);
plot_info = struct;
plot_info.directory          = plot_directory;
plot_info.sample_size        = sample_size;
plot_info.referencing_method = referencing_method;
plot_info.cleaning_method    = cleaning_method;
plot_info.n_signals          = 1 + (2 * ~strcmp(referencing_method, 'none')) + ~strcmp(cleaning_method, 'none');

for idx = 1:n_sessions

    plot_info.subject         = events_info.subject{idx};
    plot_info.task            = events_info.task{idx};
    
    session_ID = events_info.session_ID(idx);
    plot_info.session         = session_ID;
    
    indices = session_IDs == session_ID;
    indices = indices & ~empty_channels & ~empty_references;
    
    plot_info.channel_numbers = channel_numbers(indices);
    plot_info.labels          = labels(indices);
    plot_info.locations       = locations(indices);
    plot_info.electrode_IDs   = electrode_IDs(indices);
    
    these_channel_signals = vertcat(channel_signals{indices});
    these_reference_signals = vertcat(reference_signals{indices});
    
    n00_plot_all_channels(plot_info, these_channel_signals, these_reference_signals);

end
    
end