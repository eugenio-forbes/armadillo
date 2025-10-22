function n03_filter_electrode_list(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    match_mode = 'both'; %%% 'glasser', 'both'. Just automatic is bad resolution
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    match_mode = varargin{4};
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');

%%% Load electrode list
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

unspecified_location = {'Anterior Prefrontal', 'Lateral Prefrontal', ...
    'MEG DIPOLE', 'Prefrontal'};

unspecified_segment = {'Central Sulcus', 'Cingulate Gyrus', 'Cingulate Sulcus', ...
    'Collateral Sulcus', 'Frontal Operculum', 'Fusiform Gyrus', 'Hippocampus', 'IFG', ...
    'IFS', 'ITG', 'ITS', 'Insula', 'MFG', 'Motor', 'MTG', 'Occipital Gyrus', 'Operculum', ...
    'Orbital Gyrus', 'Orbital Sulcus', 'PHG', 'Parietal Operculum', 'Pars Opercularis', 'Postcentral Sulcus', ...
    'Precentral Sulcus', 'Precuneus', 'Sensory', 'SFG', 'SFG Mesial', 'SFS', 'STG', 'STS', 'Sulcus'};

bad_words = {'OUT', 'Lesion', 'FCD', 'Encephalocele', 'Encephalomalacia', ...
    'Resection', 'Heterotopia', 'MCD', 'Tuber'};

all_masked = [unspecified_location, unspecified_segment, bad_words, {'', 'WM'}];

neurologist_labels = electrode_list.neurologist_location;
automatic_labels = electrode_list.automatic_location;
glasser_labels = electrode_list.glasser_location;

bad_electrodes = contains(neurologist_labels, bad_words);
potentially_bad = strcmp(neurologist_labels, '');

auto_bad = ismember(automatic_labels, {'WM', 'empty', ''});
glasser_bad = ismember(glasser_labels, {'WM', 'empty', ''});
empty_coordinates = cellfun(@isempty, electrode_list.coordinates);

really_bad = (auto_bad|glasser_bad) & empty_coordinates;
confirmed_bad = potentially_bad & really_bad;

white_matter = contains(neurologist_labels, 'WM');
confirmed_WM = white_matter & (auto_bad|glasser_bad);

all_bad = bad_electrodes | confirmed_bad | confirmed_WM;

electrode_list(all_bad, :) = [];

location_table = make_location_table(electrode_list, all_masked);

combination_table =  make_combination_table(electrode_list, location_table, all_masked, match_mode);

replacement_table = process_options(electrode_list, location_table, ...
    combination_table, unspecified_location, unspecified_segment, match_mode);

removed = replacement_table.removed;
replaced = replacement_table.replaced;

electrode_list.neurologist_location = replacement_table.replacement;
electrode_list(removed, :) = [];

removed = replacement_table(removed, :);
removed = removed(~strcmp(removed.original_label, 'WM'), :);

replaced = replacement_table(replaced, :);

%%%
new_location_table = make_location_table(electrode_list, all_masked);

end


function location_table = make_location_table(electrode_list, all_masked)

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


function combination_table = make_combination_table(electrode_list, location_table, all_masked, match_mode)

all_locations = location_table.location;
all_coordinates = vertcat(location_table.mean_coordinates{:});
n_locations = length(all_locations);

all_automatic_labels = electrode_list.automatic_location;
all_glasser_labels = electrode_list.glasser_location;

switch match_mode
    case 'automatic'
        all_combinations = all_automatic_labels;
        bad_combos = {'', 'empty', 'WM'};
    
    case 'glasser'
        all_combinations = regexprep(all_glasser_labels, '^([LR][^_]?)_(.+)', '$2_$1');
        bad_combos = {'', 'empty', 'WM'};
    
    case 'both'
        all_combinations = strcat(all_automatic_labels, '_', all_glasser_labels);
        bad_combos = {'_', 'empty_empty', 'WM_WM', '_empty', '_WM', 'empty_', 'empty_WM', 'WM_empty', 'WM_'};

end

unique_combinations = unique(all_combinations);
n_unique = length(unique_combinations);

n_electrodes = zeros(n_unique, 1);
most_used_label = cell(n_unique, 1);
closest_label = cell(n_unique, 1);

for idx = 1:n_unique

    this_combo = unique_combinations(idx);
    
    is_subset = strcmp(all_combinations, this_combo);
    subset = electrode_list(is_subset, :);
    n_subset = height(subset);
    n_electrodes(idx) = n_subset;
    option_counts = zeros(n_locations, 1);
    
    for jdx = 1:n_subset
        
        this_electrode = subset(jdx, :);
        
        hemisphere = this_electrode.hemisphere{:};
        label = this_electrode.neurologist_location{:};
        options = strsplit(label, ' VS ');
        options = options(~ismember(options, all_masked));
        options = options(~strcmp(options, ''));
        
        if ~isempty(options) && ~strcmp(hemisphere, 'check')
            
            switch hemisphere
                case 'left'
                    options = append('Left ', options);
                
                case 'right'
                    options = append('Right ', options);
            end
            
            options = regexprep(options, '(Left|Right)\s(Int\w+\sFi\w+)', '$2');
            option_indices = cellfun(@(x) find(strcmp(all_locations, x)), options);
            option_counts(option_indices) = option_counts(option_indices) + 1;
        
        end
    
    end
    
    [~, most_used] = max(option_counts);
    most_used_label{idx} = all_locations{most_used};
    
    combo_coordinates = mean(vertcat(subset.coordinates{:}), 1);
    
    if ~isempty(combo_coordinates)
        distances = sum(minus(all_coordinates, combo_coordinates).^2, 2);
        [~, closest] = min(distances);
        closest_label{idx} = all_locations{closest};
    end

end

combination = unique_combinations;

combination_table = table(combination, n_electrodes, most_used_label, closest_label);

take_out = ismember(combination, bad_combos);
combination_table(take_out, :) = [];

end


function replacement_table = process_options(electrode_list, location_table, ...
    combination_table, unspecified_location, unspecified_segment, match_mode)

special_cases = {'Fissure', 'Sulcus', 'IFS', 'SFS', 'ITS', 'STS'};

n_electrodes = height(electrode_list);
original_label = electrode_list.neurologist_location;
hemispheres = electrode_list.hemisphere;
electrode_coordinates = electrode_list.coordinates;
all_automatic_labels = electrode_list.automatic_location;
all_glasser_labels = electrode_list.glasser_location;

switch match_mode
    case 'automatic'
        all_combinations = all_automatic_labels;
    
    case 'glasser'
        all_combinations = regexprep(all_glasser_labels, '^([LR][^_]?)_(.+)$', '$2_$1');
    
    case 'both'
        all_combinations = strcat(all_automatic_labels, '_', all_glasser_labels);
end

all_locations = location_table.location;
location_coordinates = vertcat(location_table.mean_coordinates{:});
location_electrodes = location_table.n_electrodes;
location_subjects = location_table.n_subjects;
location_frequency = (location_electrodes.*location_subjects)./(location_electrodes + location_subjects);

unique_combinations = combination_table.combination;
most_used_labels = combination_table.most_used_label;
closest_labels = combination_table.closest_label;

replacement_chosen = cell(n_electrodes, 1);
replaced = false(n_electrodes, 1);
removed = false(n_electrodes, 1);
electrode_distance = cell(n_electrodes, 1);
automatic_distance = cell(n_electrodes, 1);
automatic_hits = cell(n_electrodes, 1);

for idx = 6003:n_electrodes
    
    this_label = original_label{idx};
    coordinates = electrode_coordinates{idx};
    combination = all_combinations{idx};
    hemisphere = hemispheres{idx};
    
    no_options = strcmp(this_label, '');
    has_coordinates = ~isempty(coordinates);
    good_combination = ismember(combination, unique_combinations);
    bad_hemisphere = ~ismember(hemisphere, {'left', 'right'});
    
    if no_options
        
        if has_coordinates
            
            distances = sum(minus(location_coordinates, coordinates).^2, 2);
            [~, closest] = min(distances);
            replacement = all_locations{closest};
            replacement = regexprep(replacement, '(Left|Right)?\s?(.+)$', '$2');
            replaced(idx) = true;
            electrode_distance{idx} = replacement;
            replacement_chosen{idx} = replacement;
        
        elseif good_combination
            
            combination_idx = strcmp(unique_combinations, combination); 
            most_used = most_used_labels{combination_idx};
            closest = closest_labels{combination_idx};
            
            if strcmp(most_used, closest)
            
                most_used = regexprep(most_used, '(Left|Right)?\s?(.+)$', '$2');
                closest = regexprep(closest, '(Left|Right)?\s?(.+)$', '$2');
                replaced(idx) = true;
                automatic_hits{idx} = most_used;
                automatic_distance{idx} = closest;
                replacement_chosen{idx} = closest;
                
            else
            
                most_used_idx = strcmp(all_locations, most_used);
                closest_idx = strcmp(all_locations, closest);
                most_used_frequency = location_frequency(most_used_idx);
                closest_frequency = location_frequency(closest_idx);
                most_used = regexprep(most_used, '(Left|Right)?\s?(.+)$', '$2');
                closest = regexprep(closest, '(Left|Right)?\s?(.+)$', '$2');
                
                if most_used_frequency > closest_frequency
                
                    replaced(idx) = true;
                    automatic_hits{idx} = most_used;
                    replacement_chosen{idx} = most_used;
                    
                else
                
                    replaced(idx) = true;
                    automatic_distance{idx} = closest;
                    replacement_chosen{idx} = closest;
                    
                end 
                
            end
            
        else
            removed(idx) = true;
        end
        
    else
    
        options = strsplit(this_label, ' VS ');
        options = options(~ismember(options, {'', 'WM'}));
        only_bad_options = isempty(options);
        
        if ~only_bad_options
            
            single_option = length(options) == 1;
            has_unspecified_location = ismember(options, unspecified_location);
            has_unspecified_segment = ismember(options, unspecified_segment);
            perfect_case = single_option && ~has_unspecified_location && ~has_unspecified_segment;
            
            if perfect_case
            
                replacement_chosen{idx} = options{1};
                
            else
            
                electrode = table;
                electrode.coordinates = {coordinates};
                electrode.combination = {combination};
                electrode.hemisphere = {hemisphere};
                
                if any(has_unspecified_location)
                
                    if has_coordinates && ~bad_hemisphere
                        options = specify_this('location_coordinates', options, ...
                            unspecified_location, electrode, location_table, combination_table);
                    elseif good_combination
                        options = specify_this('location_combination', options, ...
                            unspecified_location, electrode, location_table, combination_table);
                    else
                        removed(idx) = 1;
                        continue
                    end
                    
                end
                
                if any(has_unspecified_segment) 
                
                    if has_coordinates && ~bad_hemisphere
                        options = specify_this('segment_coordinates', options, ...
                            unspecified_segment, electrode, location_table, combination_table);
                    elseif good_combination 
                        options = specify_this('segment_combination', options, ...
                            unspecified_segment, electrode, location_table, combination_table);
                    else
                    
                        if ~bad_hemisphere && sum(contains(options, {'Motor', 'Sensory'})) > 1
                            just_one = strcmp(options, 'Motor') | strcmp(options, 'Sensory');
                            options(just_one) = [];
                        else
                            removed(idx) = 1;
                            continue
                        end
                        
                    end
                    
                end
                
                options = unique(options);
                switch hemisphere
                    case 'left'
                        appended_options = append('Left ', options);
                    
                    case 'right'
                        appended_options = append('Right ', options);
                end
                
                appended_options = regexprep(appended_options, '(Left|Right)\s(Int\w+\sFi\w+)', '$2');
                
                if single_option && has_unspecified_segment
                
                    replaced(idx) = true;
                    replacement_chosen{idx} = options{1};
                    
                else
                
                    if has_coordinates
                        distances = sum(minus(location_coordinates, coordinates).^2, 2);
                        [~, closest] = min(distances);
                        closest_match = all_locations{closest};
                        closest_match_frequency = location_frequency(strcmp(all_locations, closest_match));
                    end
                    
                    if good_combination
                        combination_idx = strcmp(unique_combinations, combination);
                        most_used = most_used_labels{combination_idx};
                        closest_auto = closest_labels{combination_idx};
                        most_used_idx = strcmp(all_locations, most_used);
                        closest_idx = strcmp(all_locations, closest_auto);
                        most_used_frequency = location_frequency(most_used_idx);
                        closest_auto_frequency = location_frequency(closest_idx);
                    end
                    
                    if single_option
                    
                        if good_combination && has_coordinates
                        
                            if ismember(closest_match, [closest_auto, most_used])
                            
                                closest_match = regexprep(closest_match, '(Left|Right)?\s?(.+)$', '$2');
                                replaced(idx) = true;
                                replacement_chosen{idx} = closest_match;
                                electrode_distance{idx} = closest_match;
                                
                            else
                            
                                if closest_match_frequency > most_used_frequency && closest_match_frequency > closest_auto_frequency
                                
                                    closest_match = regexprep(closest_match, '(Left|Right)?\s?(.+)$', '$2');
                                    replaced(idx) = true;
                                    replacement_chosen{idx} = closest_match;
                                    electrode_distance{idx} = closest_match;
                                    
                                else
                                
                                    if most_used_frequency > closest_auto_frequency
                                        most_used = regexprep(most_used, '(Left|Right)?\s?(.+)$', '$2');
                                        replaced(idx) = true;
                                        automatic_hits{idx} = most_used;
                                        replacement_chosen{idx} = most_used;
                                    else
                                        closest_auto = regexprep(closest_auto, '(Left|Right)?\s?(.+)$', '$2');
                                        replaced(idx) = true;
                                        automatic_distance{idx} = closest_auto;
                                        replacement_chosen{idx} = closest_auto;
                                    end
                                    
                                end
                                
                            end
                            
                        elseif good_combination
                        
                            if most_used_frequency > closest_frequency
                                most_used = regexprep(most_used, '(Left|Right)?\s?(.+)', '$2');
                                replaced(idx) = true;
                                automatic_hits{idx} = most_used;
                                replacement_chosen{idx} = most_used;
                            else
                                closest = regexprep(closest, '(Left|Right)?\s?(.+)', '$2');
                                replaced(idx) = true;
                                automatic_distance{idx} = closest;
                                replacement_chosen{idx} = closest;
                            end
                            
                        else
                            removed(idx) = true;
                        end
                        
                    else
                    
                        is_special_case = contains(options, special_cases);
                        
                        if any(is_special_case)
                            appended_options = appended_options(is_special_case);
                            options = options(is_special_case);
                        end
                        
                        option_indices = cellfun(@(x) find(strcmp(all_locations, x)), appended_options);
                        option_frequency = location_frequency(option_indices);
                        [~, most_frequent] = max(option_frequency);
                        most_frequent_option = options{most_frequent};
                        
                        if has_coordinates
                            option_coordinates = location_coordinates(option_indices, :);
                            option_distances = sum(minus(option_coordinates, coordinates).^2, 2);
                            [~, closest_option_index] = min(option_distances);
                            closest_option = options{closest_option_index};
                            replaced(idx) = true;
                            replacement_chosen{idx} = closest_option;
                            electrode_distance{idx} = closest_option;
                        else
                            replaced(idx) = true;
                            replacement_chosen{idx} = most_frequent_option;
                        end
                        
                    end
                    
                end
                
            end
            
        else
            removed(idx) = true;
        end
        
    end
    
end

replacement_table = table;
replacement_table.replaced       = replaced;
replacement_table.removed        = removed;
replacement_table.distance       = electrode_distance;
replacement_table.auto_distance  = automatic_distance;
replacement_table.auto_hits      = automatic_hits;
replacement_table.replacement    = replacement_chosen;
replacement_table.original_label = original_label;
replacement_table.auto           = all_automatic_labels;
replacement_table.hemisphere     = hemispheres;
replacement_table.coordinates    = electrode_coordinates;

end


function options = specify_this(mode, options, unspecified_labels, electrode, location_table, combination_table)

coordinates = electrode.coordinates{:};
combination = electrode.combination{:};
hemisphere = electrode.hemisphere{:};

locations = location_table.location;
location_coordinates = vertcat(location_table.mean_coordinates{:});
n_electrodes = location_table.n_electrodes;
n_subjects = location_table.n_subjects;
location_frequency = (n_electrodes.*n_subjects)./(n_electrodes + n_subjects);

combinations = combination_table.combination;
most_used = combination_table.most_used_label;
closest_auto = combination_table.closest_label;

unspecified = find(ismember(options, unspecified_labels));
unspecified_options = options(unspecified);

options(unspecified) = [];

n_options = length(options);
n_unspecified = length(unspecified);
replacements = cell(n_unspecified, 1);

switch hemisphere
    case 'left'
        possible = contains(locations, 'Left');
    
    case 'right'
        possible = contains(locations, 'Right');
end

possible_locations = locations(possible);
possible_coordinates = location_coordinates(possible);

switch mode
    case 'location_coordinates'
        n_unspecified = 1;
        distances = sum(minus(possible_coordinates, coordinates).^2, 2);
        [~, closest] = min(distances);
        replacements = possible_locations(closest);
    
    case 'location_combination'
        n_unspecified = 1;
        has_combination = strcmp(combinations, combination);
        this_most_used = most_used(has_combination);
        this_closest_auto = closest_auto(has_combination);
        most_used_frequency = location_frequency(strcmp(locations, this_most_used));
        closest_auto_frequency = location_frequency(strcmp(locations, this_closest_auto));
        
        if closest_auto_frequency >= most_used_frequency
            replacements = this_closest_auto;
        else
            replacements = this_most_used;
        end
    
    case 'segment_coordinates'
        
        for idx = 1:n_unspecified
            
            option = unspecified_options{idx};
            possible_segments = get_possible_segments(option, possible_locations);
            segment_indices = ismember(possible_locations, possible_segments);
            segment_coordinates = possible_coordinates(segment_indices, :);
            distances = sum(minus(segment_coordinates, coordinates).^2, 2);
            [~, closest] = min(distances);
            replacements{idx} = possible_segments{closest}; 
        
        end
    
    case 'segment_combination'
        has_combination = strcmp(combinations, combination);
        this_most_used = most_used(has_combination);
        this_closest_auto = closest_auto(has_combination);
        most_used_frequency = location_frequency(strcmp(locations, this_most_used));
        closest_auto_frequency = location_frequency(strcmp(locations, this_closest_auto));
        
        for idx = 1:n_unspecified
            
            option = unspecified_options{idx};
            possible_segments = get_possible_segments(option, possible_locations);
            
            if ismember(this_closest_auto, possible_segments)
                replacements = this_closest_auto;
            elseif ismember(this_most_used, possible_segments)
                replacements = this_most_used;
            else
                
                if closest_auto_frequency >= most_used_frequency
                    replacements = this_closest_auto;
                else
                    replacements = this_most_used;
                end
            
            end
        
        end
end

replacements = regexprep(replacements, '(Left|Right)?\s?(.+)', '$2');
options(n_options + 1:n_options + n_unspecified) = replacements;

end


function possible_segments = get_possible_segments(unspecified_label, possible_locations)

switch unspecified_label
    case 'Cingulate Gyrus'
        mask = contains(possible_locations, 'Cingulate') & ~contains(possible_locations, 'Sulcus');
    
    case 'Lateral Prefrontal'
        mask = contains(possible_locations, {'MF', 'IF'});
    
    otherwise
        mask = contains(possible_locations, unspecified_label);
end

{'Central Sulcus', 'Cingulate Gyrus', 'Cingulate Sulcus', ...
    'Collateral Sulcus', 'Frontal Operculum', 'Fusiform Gyrus', 'Hippocampus', 'IFG', ...
    'IFS', 'ITG', 'ITS', 'Insula', 'MFG', 'Motor', 'MTG', 'Occipital Gyrus', 'Operculum', ...
    'Orbital Gyrus', 'Orbital Sulcus', 'PHG', 'Parietal Operculum', 'Pars Opercularis', 'Postcentral Sulcus', ...
    'Precentral Sulcus', 'Precuneus', 'Sensory', 'SFG', 'SFG Mesial', 'SFS', 'STG', 'STS', 'Sulcus'};

possible_segments = possible_locations(mask);

end