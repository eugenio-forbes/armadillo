function n10_check_behavior(varargin)
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
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');

%%% Load lists
load(fullfile(list_directory, 'ar_subject_list.mat'), 'ar_subject_list');
load(fullfile(list_directory, 'ar_session_list.mat'), 'ar_session_list');
load(fullfile(list_directory, 'ar_electrode_list.mat'), 'ar_electrode_list');
load(fullfile(list_directory, 'ar_events_info.mat'), 'ar_events_info');

%%% Loop through sessions to save events copies for each
%%% electrode to be able to process data with parfor without risking
%%% conflicts from access to files

n_sessions = height(ar_session_list);
binomial_p = NaN(n_sessions, 1);

for idx = 1:n_sessions

    %%% Get information to load events fo
    subject    = ar_session_list.subject{idx};
    task       = ar_session_list.task{idx};
    session    = ar_session_list.session{idx};
    session_ID = ar_session_list.session_ID(idx);

    %%% Load events. These save events copies have already been converted to table
    session_directory = fullfile(data_directory, subject, task, session);
    events_file = fullfile(session_directory, 'events.mat');
    load(events_file, 'events')
    
    encoding_events = events(contains(events.event, 'ENCODING'), :);
    retrieval_events = events(contains(events.event, 'RETRIEVAL'), :);
    responded_retrieval = retrieval_events(retrieval_events.response > 0, :);
    
    binomial_p(idx) = do_event_binomial_test(responded_retrieval);
    
end

meaningful = binomial_p < 0.05;

meaningful_session_list = ar_session_list(meaningful, :);
meaningful_events_info = ar_events_info(meaningful, :);

session_IDs = meaningful_session_list.session_ID;
subject_IDs = meaningful_session_list.subject_ID;

meaningful_electrode_list = ar_electrode_list(ismember(ar_electrode_list.session_ID, session_IDs), :);
meaningful_subject_list = ar_subject_list(ismember(ar_subject_list.subject_ID, subject_IDs), :);
meaningful_location_table = make_location_table(meaningful_electrode_list);

%%% Save cleaned up AR lists
save(fullfile(list_directory, 'meaningful_subject_list.mat'), 'meaningful_subject_list');
save(fullfile(list_directory, 'meaningful_session_list.mat'), 'meaningful_session_list');
save(fullfile(list_directory, 'meaningful_electrode_list.mat'), 'meaningful_electrode_list');
save(fullfile(list_directory, 'meaningful_events_info.mat'), 'meaningful_events_info');
save(fullfile(list_directory, 'meaningful_location_table.mat'), 'meaningful_location_table');

end


function binomial_p = do_event_binomial_test(events)

n_trials = height(events);
n_successes = sum(events.correct);
probability = 1/3;

binomial_p = myBinomTest(n_successes, n_trials, probability, 'two');

end


function location_table = make_location_table(electrode_list)

unspecified_location = {'Anterior Prefrontal', 'Lateral Prefrontal', ...
    'MEG DIPOLE', 'Prefrontal', 'Premotor'};

unspecified_segment = {'Central Sulcus', 'Cingulate Gyrus', 'Cingulate Sulcus', ...
    'Collateral Sulcus', 'Face', 'Frontal Operculum', 'Fusiform Gyrus', ...
    'Gut', 'Hand', 'Hippocampus', 'IFG', 'IFS', 'ITG', 'ITS', 'Insula', 'Lower Body', ...
    'MFG', 'Motor', 'MTG', 'Occipital Gyrus', 'Operculum', 'Orbital Gyrus', ...
    'Orbital Sulcus', 'PHG', 'Pars Opercularis', 'Precuneus', 'Sensory', 'SFG', ...
    'SFG Mesial', 'SFS', 'STG', 'STS', 'Sulcus', 'Temporal Operculum', 'Upper Body'};

bad_words = {'Brain Stem', 'Dura Mater', 'Encephalocele', 'Encephalomalacia', ...
    'FCD', 'Heterotopia', 'Isthmus', 'Lesion', 'MCD', 'OUT', 'Putamen', 'Resection', ...
    'Thalamus', 'Tuber'};
    
all_masked = [unspecified_location, unspecified_segment, bad_words, {'', 'WM'}];

electrode_IDs = electrode_list.electrode_ID;
[~, unique_index, ~] = unique(electrode_IDs);
unique_electrodes = electrode_list(unique_index, :);

all_neurologist_labels = unique(electrode_list.neurologist_location);

raw_locations = cellfun(@(x) strsplit(x, ' VS ')', all_neurologist_labels, 'UniformOutput', false);
raw_locations = unique(vertcat(raw_locations{:}));
mask = ~ismember(raw_locations, all_masked);
raw_locations = raw_locations(mask);
one_exception = contains(raw_locations, 'Interhemispheric Fissure');
raw_locations(one_exception) = [];
locations = [append('Left ', raw_locations');append('Right ', raw_locations')];
locations = locations(:);
raw_locations = [raw_locations;'Interhemispheric Fissure'];
locations = [locations;'Interhemispheric Fissure'];
n_locations = length(locations);
n_raw_locations = length(raw_locations);

location_counts = zeros(n_locations, 1);
location_subjects = cell(n_locations, 1);
raw_location_coordinates = cell(n_raw_locations, 1);

for idx = 1:height(unique_electrodes)

    neurologist_location = unique_electrodes.neurologist_location{idx};
    coordinates          = unique_electrodes.coordinates{idx};
    hemisphere           = unique_electrodes.hemisphere{idx};
    subject              = unique_electrodes.subject_ID(idx);
    
    options = strsplit(neurologist_location, ' VS ');
    options = options(~ismember(options, all_masked));
    
    if ~isempty(options) && ~strcmp(hemisphere, 'check')
        
        raw_location_indices = cellfun(@(x) find(strcmp(raw_locations, x)), options);
        n_indices = length(raw_location_indices);
        
        for jdx = 1:n_indices
            
            raw_location_index = raw_location_indices(jdx);
            
            if ~isempty(coordinates) && ~any(isnan(coordinates))
                raw_location_coordinates{raw_location_index} = cat(1, raw_location_coordinates{raw_location_index}, coordinates);
            end
        
        end
        
        switch hemisphere
            case 'left'
                options = append('Left ', options);
            
            case 'right'
                options = append('Right ', options);
        end
        
        options = regexprep(options, '(Left|Right)\s(Int\w+\sFi\w+)', '$2');
        location_indices = cellfun(@(x) find(strcmp(locations, x)), options);
        
        n_indices = length(location_indices);
        location_counts(location_indices) = location_counts(location_indices) + 1;
        
        for jdx = 1:n_indices
            location_index = location_indices(jdx);
            location_subjects{location_index} = cat(1, location_subjects{location_index}, subject);
        end
        
    end
    
    clear neurologist_location options coordinates hemisphere subject location_indices

end

location_n_subjects = cellfun(@(x) length(unique(x)), location_subjects);
location_coordinate_means = cell(n_locations, 1);

for idx = 1:2:n_locations
    
    raw_idx = (idx + 1) / 2;
    all_coordinates = raw_location_coordinates{raw_idx};
    
    if ~isempty(all_coordinates)
        
        right_mean = [mean(abs(all_coordinates(:, 1))), mean(all_coordinates(:, 2:3), 1)];
        left_mean = [(-1 * right_mean(1)), right_mean(2:3)];
        
        location_coordinate_means{idx} = left_mean;
        
        if idx < n_locations
            location_coordinate_means{idx+1} = right_mean;
        end
    
    else
    
        location_coordinate_means{idx} = nan(1, 3);
        
        if idx < n_locations
            location_coordinate_means{idx+1} = nan(1, 3);
        end
    
    end

end

location_table = table;
location_table.location         = locations;
location_table.n_subjects       = location_n_subjects;
location_table.n_electrodes     = location_counts;
location_table.mean_coordinates = location_coordinate_means;

end