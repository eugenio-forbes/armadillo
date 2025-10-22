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
            location_coordinate_means{idx + 1} = right_mean;
        end
    
    else
        
        location_coordinate_means{idx} = nan(1, 3);
        
        if idx < n_locations
            location_coordinate_means{idx + 1} = nan(1, 3);
        end
    
    end
    
end

location_table = table;
location_table.location         = locations;
location_table.n_subjects       = location_n_subjects;
location_table.n_electrodes     = location_counts;
location_table.mean_coordinates = location_coordinate_means;

end