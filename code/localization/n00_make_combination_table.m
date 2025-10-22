function combination_table = n00_make_combination_table(electrode_list, location_table, all_masked, match_mode)

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
combo_coordinates = cell(n_unique, 1);

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
    
    combo_coordinates{idx} = mean(vertcat(subset.coordinates{:}), 1);
    
    if ~isempty(combo_coordinates{idx})
        distances = sum(minus(all_coordinates, combo_coordinates{idx}).^2, 2);
        [~, closest] = min(distances);
        closest_label{idx} = all_locations{closest};
    end
    
end

combination = unique_combinations;

combination_table = table(combination, n_electrodes, most_used_label, closest_label, combo_coordinates);

take_out = ismember(combination, bad_combos)|cellfun(@isempty, most_used_label)|cellfun(@isempty, closest_label);
combination_table(take_out, :) = [];

end