function replacement_table = n00_process_options(electrode_list, location_table, combination_table, unspecified_location, unspecified_segment, match_mode)

special_cases = {'Corpus', 'Cuneus', 'Fissure', 'Insula Middle', 'Middle Hippocampus', 'PRESMA', 'SMA', 'Sulcus', 'Ventricle', 'IFS', 'SFS', 'ITS', 'STS'};

n_electrodes = height(electrode_list);

original_label        = electrode_list.neurologist_location;
hemispheres           = electrode_list.hemisphere;
electrode_coordinates = electrode_list.coordinates;
all_automatic_labels  = electrode_list.automatic_location;
all_glasser_labels    = electrode_list.glasser_location;

switch match_mode
    case 'automatic'
        all_combinations = all_automatic_labels;
    
    case 'glasser'
        all_combinations = regexprep(all_glasser_labels, '^([LR][^_]?)_(.+)$', '$2_$1');
    
    case 'both'
        all_combinations = strcat(all_automatic_labels, '_', all_glasser_labels);
end

all_locations        = location_table.location;
location_coordinates = vertcat(location_table.mean_coordinates{:});
location_electrodes  = location_table.n_electrodes;
location_subjects    = location_table.n_subjects;

location_frequency   = (location_electrodes .* location_subjects) ./ (location_electrodes + location_subjects);

unique_combinations    = combination_table.combination;
combo_most_used_labels = combination_table.most_used_label;
combo_closest_labels   = combination_table.closest_label;

replacement_chosen = cell(n_electrodes, 1);
replaced = false(n_electrodes, 1);
removed = false(n_electrodes, 1);
method_used = cell(n_electrodes, 1);

for idx = 1:n_electrodes
    
    this_label = original_label{idx};
    coordinates = electrode_coordinates{idx};
    combination = all_combinations{idx};
    hemisphere = hemispheres{idx};
    
    switch hemisphere
        case 'left'
            possible = contains(all_locations, 'Left');
        
        case 'right'
            possible = contains(all_locations, 'Right');
    end
    
    possible = possible | strcmp(all_locations, 'Interhemispheric Fissure');
    possible_locations = all_locations(possible);
    possible_locations = regexprep(possible_locations, '(Left|Right)?\s?(.+)$', '$2');
    possible_coordinates = location_coordinates(possible, :);
    possible_frequency = location_frequency(possible);
    
    has_coordinates = ~isempty(coordinates);
    good_combination = ismember(combination, unique_combinations);
    
    options = strsplit(this_label, ' VS ');
    options = options(~ismember(options, {'', 'WM'}));
    
    if ~isempty(options)
        
        electrode = table;
        electrode.coordinates = {coordinates};
        electrode.combination = {combination};
        electrode.hemisphere  = {hemisphere};
        
        has_unspecified_location = ismember(options, unspecified_location);
        has_unspecified_segment = ismember(options, unspecified_segment);
        
        if any(has_unspecified_location)
        
            if has_coordinates
                options = specify_this('location_coordinates', options, unspecified_location, electrode, location_table, combination_table);
            elseif good_combination
                options = specify_this('location_combination', options, unspecified_location, electrode, location_table, combination_table);
            else
                removed(idx) = true;
                continue
            end
            
        end
        
        if any(has_unspecified_segment)
        
            if has_coordinates
                options = specify_this('segment_coordinates', options, unspecified_segment, electrode, location_table, combination_table);
            elseif good_combination
                options = specify_this('segment_combination', options, unspecified_segment, electrode, location_table, combination_table);
            else
            
                if sum(contains(options, {'Motor', 'Sensory'})) > 1
                
                    options(has_unspecified_segment) = [];
                    options = options(contains(options, {'Motor', 'Sensory'}));
                    
                    if isempty(options)
                        removed(idx) = true;
                        continue
                    end
                    
                else
                    removed(idx) = true;
                    continue
                end
                
            end
            
        end
        
        options = unique(options);
        is_special_case = contains(options, special_cases);
        
        if any(is_special_case)
            options = options(is_special_case);
        end
        
    end
    
    if has_coordinates
        distances = sum(minus(possible_coordinates, coordinates).^2, 2);
        [~, closest] = min(distances);
        closest_match = possible_locations{closest};
        closest_match_frequency = possible_frequency(closest);
    end
    
    if good_combination
    
        combination_idx = strcmp(unique_combinations, combination);
        
        combo_most_used_label = combo_most_used_labels{combination_idx};
        combo_closest_label = combo_closest_labels{combination_idx};
        
        most_used_idx = strcmp(all_locations, combo_most_used_label);
        closest_idx = strcmp(all_locations, combo_closest_label);
        
        combo_most_used_frequency = location_frequency(most_used_idx);
        combo_closest_frequency = location_frequency(closest_idx);
        
        combo_most_used_label = regexprep(combo_most_used_label, '(Left|Right)?\s?(.+)$', '$2');
        combo_closest_label = regexprep(combo_closest_label, '(Left|Right)?\s?(.+)$', '$2');
        
        if strcmp(combo_closest_label, combo_most_used_label)
            combo_label = combo_closest_label;
            combo_frequency = combo_closest_frequency;
        else
        
            if combo_closest_frequency >= combo_most_used_frequency
                combo_label = combo_closest_label;
                combo_frequency = combo_closest_frequency;
            else
                combo_label = combo_most_used_label;
                combo_frequency = combo_most_used_frequency;
            end
            
        end
        
    end
    
    replaced(idx) = true;
    no_options = isempty(options);
    single_option = length(options) == 1;
    
    if no_options
    
        if has_coordinates && good_combination
        
            if strcmp(closest_match, combo_label) || closest_match_frequency >= combo_frequency
                replacement_chosen{idx} = closest_match;
                method_used{idx} = 'no_option_closest';
            else
                replacement_chosen{idx} = combo_label;
                method_used{idx} = 'no_option_combo';
            end
            
        elseif has_coordinates
            replacement_chosen{idx} = closest_match;
            method_used{idx} = 'no_option_closest';
        elseif good_combination
            replacement_chosen{idx} = combo_label;
            method_used{idx} = 'no_option_combo';
        else
            replaced(idx) = false;
            removed(idx) = true;
        end
        
    elseif single_option
    
        replacement_chosen{idx} = options{1};
        
        if any(is_special_case)
            method_used{idx} = 'single_option_special';
        elseif any(has_unspecified_segment) || any(has_unspecified_location)
            method_used{idx} = 'single_option_fixed';
        else
            method_used{idx} = 'single_option_kept';
        end
        
    else
    
        option_indices = cellfun(@(x) find(strcmp(possible_locations, x)), options);
        option_coordinates = possible_coordinates(option_indices, :);
        option_frequency = possible_frequency(option_indices);
        
        if has_coordinates
            option_distances = sum(minus(option_coordinates, coordinates).^2, 2);
        end
        
        if has_coordinates && good_combination
            matched = ismember(options, [{closest_match}, {combo_label}]);
        elseif has_coordinates
            matched = ismember(options, {closest_match});
        elseif good_combination
            matched = ismember(options, {combo_label});
        else
            matched = false(length(options), 1);
        end
        
        if any(matched)
            options = options(matched);
            option_frequency = option_frequency(matched);
            if has_coordinates
                option_distances = option_distances(matched);
            end
        end
        
        if length(options) == 1
            replacement_chosen{idx} = options{1};
            method_used{idx} = 'one_matched';
        else
        
            if has_coordinates
                
                [~, closest] = min(option_distances);
                replacement_chosen{idx} = options{closest};
                
                if any(matched)
                    method_used{idx} = 'closest_matched';
                else
                    method_used{idx} = 'closest_option';
                end
                
            else
            
                [~, most_frequent] = max(option_frequency);
                replacement_chosen{idx} = options{most_frequent};
                
                if any(matched)
                    method_used{idx} = 'frequent_matched';
                else
                    method_used{idx} = 'frequent_option';
                end
                
            end
            
        end
        
    end
    
end

replacement_table = table;
replacement_table.replaced       = replaced;
replacement_table.removed        = removed;
replacement_table.replacement    = replacement_chosen;
replacement_table.method         = method_used;
replacement_table.original_label = original_label;
replacement_table.auto           = all_combinations;
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
combo_coordinates = combination_table.combo_coordinates;

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
possible_coordinates = location_coordinates(possible, :);

switch mode
    case {'segment_coordinates', 'location_coordinates'}
        
        for idx = 1:n_unspecified
        
            option = unspecified_options{idx};
            [possible_segments, segment_coordinates] = get_possible_segments(option, possible_locations, possible_coordinates);
            
            distances = sum(minus(segment_coordinates, coordinates).^2, 2);
            [~, closest] = min(distances);
            
            replacements{idx} = possible_segments{closest}; 
        end
    
    case {'segment_combination', 'location_combination'}
        
        has_combination = strcmp(combinations, combination);
        this_most_used = most_used(has_combination);
        this_closest_auto = closest_auto(has_combination);
        this_combo_coordinates = combo_coordinates{has_combination};
        
        most_used_frequency = location_frequency(strcmp(locations, this_most_used));
        closest_auto_frequency = location_frequency(strcmp(locations, this_closest_auto));
        
        for idx = 1:n_unspecified
            
            option = unspecified_options{idx};
            [possible_segments, segment_coordinates] = get_possible_segments(option, possible_locations, possible_coordinates);
            
            if ~isempty(this_combo_coordinates)
            
                combo_distances = sum(minus(segment_coordinates, this_combo_coordinates).^2, 2);
                [~, closest_segment] = min(combo_distances);
                replacements{idx} = possible_segments{closest_segment};
                
            else
            
                if ismember(this_closest_auto, possible_segments)
                    replacements{idx} = this_closest_auto;
                elseif ismember(this_most_used, possible_segments)
                    replacements{idx} = this_most_used;
                else
                
                    if closest_auto_frequency >= most_used_frequency
                        replacements{idx} = this_closest_auto;
                    else
                        replacements{idx} = this_most_used;
                    end
                    
                end
                
            end
        
        end
end

replacements = regexprep(replacements, '(Left|Right)?\s?(.+)', '$2');
options(n_options + 1:n_options + n_unspecified) = replacements;

end


function [possible_segments, possible_coordinates] = get_possible_segments(unspecified_label, possible_locations, possible_coordinates)

switch unspecified_label
    case {'Anterior Prefrontal', 'Prefrontal'}
        mask = contains(possible_locations, {'MFG', 'IFG', 'SFG'}) & contains(possible_locations, 'Prefrontal');
    
    case 'Cingulate Gyrus'
        mask = contains(possible_locations, 'Cingulate') & ~contains(possible_locations, 'Sulcus');
    
    case {'Central Sulcus'}
        mask = contains(possible_locations, {'Motor', 'Sensory'});
    
    case 'Lateral Prefrontal'
        mask = contains(possible_locations, {'MFG', 'IFG'}) & contains(possible_locations, 'Prefrontal');
    
    case 'MEG DIPOLE'
        mask = true(length(possible_locations), 1);
    
    case 'Orbital Sulcus'
        mask = contains(possible_locations, unspecified_label) & contains(possible_locations, {'Lateral', 'Medial'});
    
    case 'SFG'
        mask = contains(possible_locations, unspecified_label) & ~contains(possible_locations, {'Medial'});
    
    case 'Sulcus'
        mask = contains(possible_locations, unspecified_label) | contains(possible_locations, {'FS', 'TS'});
    
    otherwise
        mask = contains(possible_locations, unspecified_label);

end

possible_segments = possible_locations(mask);
possible_coordinates = possible_coordinates(mask, :);

end


function change_table = make_change_table(new_location_table, location_table, replaced)

not_anymore = ~ismember(location_table.location, new_location_table.location);
location_table(not_anymore, :) = [];

location     = new_location_table.location;
n_locations  = length(location);
n_subjects   = new_location_table.n_subjects - location_table.n_subjects;
n_electrodes = new_location_table.n_electrodes - location_table.n_electrodes;

changes = cell(n_locations, 1);

for idx = 1:n_locations
    
    this_location = location{idx};
    
    is_left = contains(this_location, 'Left');
    
    if is_left
        possibly_replaced = replaced(strcmp(replaced.hemisphere, 'left'), :);
    else
        possibly_replaced = replaced(strcmp(replaced.hemisphere, 'right'), :);
    end
    
    this_location = regexprep(this_location, '^(Left|Right)?\s?(.+)$', '$2');
    this_subset = contains(possibly_replaced.original_label, this_location) | contains(possibly_replaced.replacement, this_location);
    this_subset = possibly_replaced(this_subset, :);
    n_subset = height(this_subset);
    delimeter = repelem({'->'}, n_subset, 1);
    
    if n_subset > 0
        this_strings = strcat(this_subset.original_label, delimeter, this_subset.replacement, delimeter, this_subset.method);
        [unique_strings, unique_idx, ~] = unique(this_strings);
        unique_changes = this_subset(unique_idx, :);
        unique_changes.count = cellfun(@(x) sum(strcmp(this_strings, x)), unique_strings);
        changes{idx} = unique_changes;
    end
    
end

change_table = table(location, n_subjects, n_electrodes, changes);

end