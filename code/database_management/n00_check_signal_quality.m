%%% This function will loop through a subject's sessions and plot
%%% sample signals and power spectral density for all electrodes
%%% in the session in order to assess quality of raw, referenced
%%% and filtered signals.

function n00_check_signal_quality(root_directory, subject)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end


%%% In case of using parallel
n_workers = 24;

%%% Initialize parpool
pool_object = gcp('nocreate');
if isempty(pool_object)
    parpool(n_workers)
end

%%% Current Elemem methods
referencing_method = 'bipolar';
cleaning_method = 'none'; 
sample_size = 1000;

%%% Declare directories
list_directory    = fullfile(root_directory, 'lists');
subject_directory = fullfile(root_directory, 'subject_files', subject);
data_directory    = fullfile(subject_directory, 'data');
plot_directory    = fullfile(subject_directory, 'signal_quality');
if ~isfolder(plot_directory)
    mkdir(plot_directory);
end

%%% Load session, electrode, and recording lists and filter for those corresponding to subject's sessions
load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
load(fullfile(list_directory, 'nihon_kohden_list.mat'), 'nihon_kohden_list');
load(fullfile(list_directory, 'blackrock_list.mat'), 'blackrock_list');

session_list(~strcmp(session_list.subject, subject), :) = [];
session_list(~session_list.is_aligned, :) = [];

n_sessions = height(session_list);
session_IDs = session_list.session_ID;
nihon_kohden_IDs = vertcat(session_list.nihon_kohden_IDs{:});
blackrock_IDs = vertcat(session_list.blackrock_IDs{:});

electrode_list(~ismember(electrode_list.session_ID, session_IDs), :) = [];
nihon_kohden_list(~ismember(nihon_kohden_list.recording_ID, nihon_kohden_IDs), :) = [];
blackrock_list(~ismember(blackrock_list.recording_ID, blackrock_IDs), :) = [];

%%% Set the reference of each electrode based on method and get random sample index based on recording lengths
electrode_list = n00_set_reference(electrode_list, referencing_method);
electrode_list.sample_idx = n00_set_sample_idx(electrode_list, nihon_kohden_list, blackrock_list);

%%% Initialize variables to hold each electrodes own and reference signals.
n_electrodes = height(electrode_list);
channel_signals = cell(n_electrodes, 2);
reference_signals = cell(n_electrodes, 2);

%%% Electrode information
tasks           = electrode_list.task;
sessions        = electrode_list.session;
session_IDs     = electrode_list.session_ID;
electrode_IDs   = electrode_list.electrode_ID;
channel_numbers = electrode_list.channel_number;
labels          = electrode_list.label;
locations       = electrode_list.neurologist_location;
references      = electrode_list.reference;
sample_indices  = electrode_list.sample_idx;

%%% Filter these words out of electrode location labels
bad_words = {'Brain Stem', 'Dura Mater', 'Encephalocele', 'Encephalomalacia', ...
    'FCD', 'Heterotopia', 'Isthmus', 'Lesion', 'MCD', 'OUT', 'Putamen', 'Resection', ...
    'Thalamus', 'Tuber'};

locations = regexprep(locations, ['.*(', strjoin(bad_words, '|'), ').*'], '$1');

%%% Loop through electrodes and get Nihon Kohden and Blackrock recording raw and reference signals
for idx = 1:n_electrodes

    task = tasks{idx};
    session = sessions{idx};
    channel_number = channel_numbers(idx);
    reference = references(idx);
    sample_idx = sample_indices(idx);
    nihon_kohden_events_file = fullfile(data_directory, 'nihon_kohden', task, session, 'events.mat');
    blackrock_events_file = fullfile(data_directory, 'blackrock', task, session, 'events.mat');
    
    if isfile(nihon_kohden_events_file)
        [channel_signals{idx, 1}, reference_signals{idx, 1}] = n00_get_sample_signal(nihon_kohden_events_file, channel_number, reference, referencing_method, sample_idx, sample_size);
    end
    
    if isfile(blackrock_events_file)
        [channel_signals{idx, 2}, reference_signals{idx, 2}] = n00_get_sample_signal(blackrock_events_file, channel_number, reference, referencing_method, sample_idx, sample_size);
    end

end

%%% Check which channels and references couldn't have signal collected to filter out
empty_nihon_kohden_channels = cellfun(@isempty, channel_signals(:, 1));
empty_nihon_kohden_references = cellfun(@isempty, reference_signals(:, 1));
empty_blackrock_channels = cellfun(@isempty, channel_signals(:, 2));
empty_blackrock_references = cellfun(@isempty, reference_signals(:, 2));

%%% Session alignment info
nihon_kohden_aligned = session_list.nihon_kohden_aligned;
blackrock_aligned    = session_list.blackrock_aligned;

n_sessions = height(events_info);

%%% Set plot information in a struct
plot_info = struct;
plot_info.sample_size        = sample_size;
plot_info.referencing_method = referencing_method;
plot_info.cleaning_method    = cleaning_method;
plot_info.n_signals          = 1 + (2 * ~strcmp(referencing_method, 'none')) + ~strcmp(cleaning_method, 'none');

%%% Loop through sessions and plot valid electrodes
for idx = 1:n_sessions
    
    plot_info.subject = session_list.subject{idx};
    plot_info.task    = session_list.task{idx};
    session_ID        = session_list.session_ID(idx);
    
    plot_info.session = session_ID;
    
    session_indices = session_IDs == session_ID;

    if nihon_kohden_aligned(idx)
    
        good_indices = session_indices & ~empty_nihon_kohden_channels & ~empty_nihon_kohden_references;
        
        plot_info.channel_numbers = channel_numbers(good_indices);
        plot_info.labels = labels(good_indices);
        plot_info.locations = locations(good_indices);
        plot_info.electrode_IDs = electrode_IDs(good_indices);
        plot_info.directory = fullfile(plot_directory, 'nihon_kohden');
        
        these_channel_signals = vertcat(channel_signals{good_indices, 1});
        these_reference_signals = vertcat(reference_signals{good_indices, 1});
        
        n00_plot_all_channels(plot_info, these_channel_signals, these_reference_signals);
    
    end

    if blackrock_aligned(idx)
    
        good_indices = session_indices & ~empty_blackrock_channels & ~empty_blackrock_references;
        
        plot_info.channel_numbers = channel_numbers(good_indices);
        plot_info.labels = labels(good_indices);
        plot_info.locations = locations(good_indices);
        plot_info.electrode_IDs = electrode_IDs(good_indices);
        plot_info.directory = fullfile(plot_directory, 'blackrock');
        
        these_channel_signals = vertcat(channel_signals{good_indices, 2});
        these_reference_signals = vertcat(reference_signals{good_indices, 2});
        
        n00_plot_all_channels(plot_info, these_channel_signals, these_reference_signals);
    
    end

end
    
end