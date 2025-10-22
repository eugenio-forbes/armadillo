function change_table = n00_make_change_table(new_location_table, location_table, replaced)

change_table = new_location_table(:, {'location', 'n_subjects', 'n_electrodes'});

kept_locations = new_location_table.location;
removed = ~ismember(location_table.location, kept_locations);

location_table(removed, :) = [];

change_table.n_subjects = change_table.n_subjects - location_table.n_subjects;
change_table.n_electrodes = change_table.n_electrodes - location_table.n_electrodes;

n_locations = height(change_table);

hemisphere = cell(n_locations, 1);
is_left = contains(change_table.location, 'Left');
hemisphere(is_left) = repelem({'left'}, sum(is_left), 1);
hemisphere(~is_left) = repelem({'right'}, sum(~is_left), 1);

location = regexprep(change_table.location, '^(Right|Left)\s?', '');

row_numbers = (1:n_locations)';

change_table.changes = arrayfun(@(x) replaced(strcmp(replaced.replacement, location{x}) & strcmp(replaced.hemisphere, hemisphere{x}), :), row_numbers, 'UniformOutput', false);

end