%%% This function goes through corrected electrode labels of an electrode list.
%%% From labels that are empty, have several locations listed, or have unspecified segments
%%% a single location is chosen using coordinates based on data collected from all subjects.

function [electrode_list, bad_list, removed] = n03_filter_electrode_list(varargin)
if isempty(varargin)
    analysis_directory = '/path/to/armadillo'; %%% Armadillo folder
    electrode_list = [];                       %%% Must pause and load an electrode list table to workspace
    match_mode = 'both';                       %%% 'glasser', 'both'. Just automatic is bad resolution
    recursive = true;                          %%% Whether to run code twice once for more refine results
    filter_mode = 'single';                    %%% 'all' uses all subject data or 'single' uses saved combination and location tables for a single subject
else
    analysis_directory = varargin{1};
    electrode_list = varargin{2};
    match_mode = varargin{3};
    recursive = varargin{4};
    filter_mode = varargin{5};
end

%%% List directories;
list_directory = fullfile(analysis_directory, 'lists');
resources_directory = fullfile(analysis_directory, 'resources');

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

if strcmp(filter_mode, 'all')
    %%% Load electrode list
    load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
    
    location_table = n00_make_location_table(electrode_list, all_masked);
    
    combination_table =  n00_make_combination_table(electrode_list, location_table, all_masked, match_mode);
else
    load(fullfile(resources_directory, 'location_table.mat'), 'location_table');
    load(fullfile(resources_directory, 'combination_table.mat'), 'combination_table');
end

neurologist_labels = electrode_list.neurologist_location;
automatic_labels = electrode_list.automatic_location;
glasser_labels = electrode_list.glasser_location;
hemispheres = electrode_list.hemisphere;

bad_hemisphere = ~ismember(hemispheres, {'left', 'right'});
bad_electrodes = contains(neurologist_labels, bad_words);
potentially_bad = strcmp(neurologist_labels, '');
auto_bad = ismember(automatic_labels, {'WM', 'empty', ''});
glasser_bad = ismember(glasser_labels, {'WM', 'empty', ''});
empty_coordinates = cellfun(@isempty, electrode_list.coordinates);
really_bad = (auto_bad|glasser_bad) & empty_coordinates;
confirmed_bad = potentially_bad & really_bad;
white_matter = contains(neurologist_labels, 'WM');
confirmed_WM = white_matter & (auto_bad|glasser_bad);
confirmed_WM = confirmed_WM | strcmp(neurologist_labels, 'WM');
all_bad = bad_electrodes | confirmed_bad | confirmed_WM | bad_hemisphere;
electrode_list.neurologist_location(confirmed_WM, :) = repelem({'WM'}, sum(confirmed_WM), 1);
bad_list = electrode_list(all_bad, :);
electrode_list(all_bad, :) = [];

replacement_table = n00_process_options(electrode_list, location_table, ...
    combination_table, unspecified_location, unspecified_segment, match_mode);
removed = replacement_table.removed;
replaced = replacement_table.replaced;

if recursive && strcmp(filter_mode, 'all')
    temp_electrode_list = electrode_list;
    temp_electrode_list.neurologist_location = replacement_table.replacement;
    temp_electrode_list(removed, :) = [];
    
    temp_location_table = n00_make_location_table(temp_electrode_list, all_masked);
    
    temp_combination_table = n00_make_combination_table(temp_electrode_list, ...
        temp_location_table, all_masked, match_mode);
    
    replacement_table = n00_process_options(electrode_list, temp_location_table, ...
        temp_combination_table, unspecified_location, unspecified_segment, match_mode);
    
    removed = replacement_table.removed;
    replaced = replacement_table.replaced;
end
    
electrode_list.neurologist_location = replacement_table.replacement;
temp_electrode_list = electrode_list;
temp_electrode_list(removed, :) = [];
electrode_list.neurologist_location(removed) = repelem({'removed'}, sum(removed), 1);
replaced = replacement_table(replaced, :);
removed = electrode_list(removed, :);
electrode_list = [electrode_list;bad_list];

if strcmp(filter_mode, 'all')

    make_exclusions(analysis_directory, temp_electrode_list, removed, bad_list);
    new_location_table = n00_make_location_table(temp_electrode_list, all_masked);
    change_table = n00_make_change_table(new_location_table, location_table, replaced);
    location_table = new_location_table;
    combination_table =  n00_make_combination_table(temp_electrode_list, location_table, all_masked, match_mode);
    
    save(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');
    save(fullfile(list_directory, 'location_table.mat'), 'location_table');
    save(fullfile(list_directory, 'change_table.mat'), 'change_table');
    save(fullfile(list_directory, 'combination_table.mat'), 'combination_table');
end

end


function location_table = n00_make_location_table(electrode_list, all_masked)

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
        left_mean = [(-1*right_mean(1)), right_mean(2:3)];
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


function make_exclusions(analysis_directory, electrode_list, removed, bad_list)

electrode_fields = {'subject', 'task', 'session', 'channel_number', 'subject_ID', 'session_ID', 'electrode_ID'};
session_fields = {'subject', 'task', 'session', 'subject_ID', 'session_ID'};
subject_fields = {'subject', 'subject_ID'};

list_directory = fullfile(analysis_directory, 'lists');
load(fullfile(list_directory, 'subject_list'), 'subject_list');
load(fullfile(list_directory, 'session_list'), 'session_list');
exclusion_directory = fullfile(analysis_directory, 'exclusion_lists');
electrode_file = fullfile(exclusion_directory, 'excluded_electrodes.mat');
session_file = fullfile(exclusion_directory, 'excluded_sessions.mat');
subject_file = fullfile(exclusion_directory, 'excluded_subjects.mat');

if ~isempty(removed) || ~isempty(bad_list)

    removed = removed(:, electrode_fields);
    bad_list = bad_list(:, electrode_fields);
    removed.reason_for_exclusion = repelem({'Removed by filtering electrodes.'}, height(removed), 1);
    bad_list.reason_for_exclusion = repelem({'Bad labels.'}, height(bad_list), 1);
    newly_excluded_electrodes = [removed;bad_list];
    
    if isfile(electrode_file)
        load(electrode_file, 'excluded_electrodes')
        excluded_electrodes = [excluded_electrodes;newly_excluded_electrodes];
    else
        excluded_electrodes = newly_excluded_electrodes;
    end

    save(electrode_file, 'excluded_electrodes');
    
    potentially_excluded_sessions = unique(newly_excluded_electrodes.session_ID);
    unexcluded_sessions = unique(electrode_list.session_ID);
    actually_excluded = ~ismember(potentially_excluded_sessions, unexcluded_sessions);
    excluded_sessions_IDs = potentially_excluded_sessions(actually_excluded);
    
    if ~isempty(excluded_sessions_IDs)

        newly_excluded_sessions = session_list(ismember(session_list.session_ID, excluded_sessions_IDs), session_fields);
        newly_excluded_sessions.reason_for_exclusion = repelem({'Bad electrodes.'}, height(newly_excluded_sessions), 1);

        if isfile(session_file)
            load(session_file, 'excluded_sessions')
            excluded_sessions = [excluded_sessions;newly_excluded_sessions];
        else
            excluded_sessions = newly_excluded_sessions;
        end

        save(session_file, 'excluded_sessions');

    end
    
    potentially_excluded_subjects = unique(newly_excluded_electrodes.subject_ID);
    unexcluded_subjects = unique(electrode_list.subject_ID);
    actually_excluded = ~ismember(potentially_excluded_subjects, unexcluded_subjects);
    excluded_subjects_IDs = potentially_excluded_subjects(actually_excluded);
    
    if ~isempty(excluded_subjects_IDs)

        newly_excluded_subjects = subject_list(ismember(subject_list.subject_ID, excluded_subjects_IDs), subject_fields);
        newly_excluded_subjects.reason_for_exclusion = repelem({'Bad electrodes.'}, height(newly_excluded_subjects), 1);

        if isfile(subject_file)
            load(subject_file, 'excluded_subjects')
            excluded_subjects = [excluded_subjects;newly_excluded_subjects];
        else
            excluded_subjects = newly_excluded_subjects;
        end

        save(subject_file, 'excluded_subjects');

    end

end

end