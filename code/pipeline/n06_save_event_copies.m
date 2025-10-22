function n06_save_event_copies(varargin)
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
load(fullfile(list_directory, 'subject_list.mat'), 'subject_list');
load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
load(fullfile(list_directory, 'events_info_recheck.mat'), 'events_info_recheck');

[subject_list, session_list, electrode_list, events_info] = check_exclusions(analysis_directory, subject_list, session_list, electrode_list, events_info_recheck);
n_sessions = height(session_list);

location_table = make_location_table(electrode_list);

%%% Save cleaned up AR lists
save(fullfile(list_directory, 'subject_list.mat'), 'subject_list');
save(fullfile(list_directory, 'session_list.mat'), 'session_list');
save(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
save(fullfile(list_directory, 'events_info.mat'), 'events_info');
save(fullfile(list_directory, 'location_table.mat'), 'location_table');

%%% Loop through sessions to save events copies for each
%%% electrode to be able to process data with parfor without risking
%%% conflicts from access to files

for idx = 1:n_sessions

    %%% Get information to load events fo
    subject = session_list.subject{idx};
    task = session_list.task{idx};
    session = session_list.session{idx};
    session_ID = session_list.session_ID(idx);
    
    %%% Get hipppocampal channel numbers for this session
    session_electrodes = electrode_list.session_ID == session_ID;
    channel_numbers = electrode_list.channel_number(session_electrodes);

    %%% Load events. These save events copies have already been converted to table
    session_directory = fullfile(data_directory, subject, task, session);
    events_file = fullfile(session_directory, 'events.mat');
    events_table_file = fullfile(session_directory, 'events_table.mat');
    load(events_file, 'events')
    load(events_table_file, 'events_table');
    
    %%% Remove events with empty eegoffset or offset less than 0. Not done
    %%% previously to conserve all behavioral data
    no_file_or_offset = strcmp(events.eegfile, '') | isempty(events.eegoffset) | events.eegoffset <0;
    events(no_file_or_offset, :) = [];
    
    %%% Loop through channels to save events
    par_save(session_directory, channel_numbers, events, 'events');
    par_save(session_directory, channel_numbers, events_table, 'events_table');
    
end

end


function par_save(session_directory, channel_numbers, events, variable_name)

n_channels = length(channel_numbers);
is_events_table = contains(variable_name, 'table');

if is_events_table
    events_table = events;
end

for idx = 1:n_channels

    this_channel = channel_numbers(idx);
    save_path = fullfile(session_directory, num2str(this_channel));
    
    if ~isfolder(save_path)
        mkdir(save_path);
    end
    
    file_name = fullfile(save_path, sprintf('%s.mat', variable_name));
    
    if is_events_table
        save(file_name, 'events_table');
    else
        save(file_name, 'events');
    end

end

end


function [subject_list, session_list, electrode_list, events_info] = check_exclusions(analysis_directory, subject_list, session_list, electrode_list, events_info)

exclusion_directory = fullfile(analysis_directory, 'exclusion_lists');

load(fullfile(exclusion_directory, 'excluded_electrodes.mat'), 'excluded_electrodes');
load(fullfile(exclusion_directory, 'excluded_sessions.mat'), 'excluded_sessions');
load(fullfile(exclusion_directory, 'excluded_subjects.mat'), 'excluded_subjects');

excluded_subjects = excluded_subjects(~contains(excluded_subjects.reason_for_exclusion, 'scopolamine'), :);
excluded_sessions = excluded_sessions(~contains(excluded_sessions.reason_for_exclusion, 'Scopolamine'), :);
unaligned_sessions = events_info.session_ID(contains(events_info.reason_bad, 'unaligned_session'));
aligned_subjects = unique(events_info.subject_ID(~ismember(events_info.session_ID, unaligned_sessions)));

excluded = ismember(subject_list.subject_ID, excluded_subjects.subject_ID);
excluded = excluded | ~ismember(subject_list.subject_ID, aligned_subjects);
subject_list = subject_list(~excluded, :);

excluded = ismember(session_list.session_ID, excluded_sessions.session_ID);
excluded = excluded | ismember(session_list.session_ID, unaligned_sessions);
session_list = session_list(~excluded, :);
events_info = events_info(~excluded, :);

excluded = ismember(electrode_list.electrode_ID, excluded_electrodes.electrode_ID);
excluded = excluded & ismember(electrode_list.session_ID, excluded_electrodes.session_ID);
excluded = excluded | ismember(electrode_list.session_ID, unaligned_sessions);
electrode_list = electrode_list(~excluded, :);

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
    coordinates = unique_electrodes.coordinates{idx};
    hemisphere = unique_electrodes.hemisphere{idx};
    subject = unique_electrodes.subject_ID(idx);
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
    
    raw_idx = (idx + 1)/2;
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