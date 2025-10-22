function n00_plot_all_electrodes_by_region(electrode_table, plot_parameters)

if ~ismember('figure_handle', fieldnames(plot_parameters))
    figure_handle = figure('Units', 'pixels', 'Position', [0, 0, plot_parameters.figure_width, plot_parameters.figure_height]);
    plot_parameters.figure_handle = figure_handle;
end

if ~ismember('root_directory', fieldnames(plot_parameters))
    plot_parameters.root_directory = '/path/to/armadillo' ;
end

[electrode_table, plot_parameters] = get_brain_region_values_color_map(electrode_table, plot_parameters);

n00_plot_frame(electrode_table, plot_parameters);

end


function [electrode_table, plot_parameters] = get_brain_region_values_color_map(electrode_table, plot_parameters)

root_directory = plot_parameters.root_directory;
resources_directory = fullfile(root_directory, 'resources');

location_color_file = fullfile(resources_directory, 'brain_plots/location_colors/brainplot_location_colors.txt');

brain_plot_location_colors = readtable(location_color_file);
locations = brain_plot_location_colors.Var1;

electrode_table = electrode_table(ismember(electrode_table.neurologist_location, locations), :);
no_coordinates = cellfun(@isempty, electrode_table.coordinates);
electrode_table(no_coordinates, :) = [];

shifted = cellfun(@(x) x(:, 3) < -50, electrode_table.coordinates);
electrode_table(shifted, :) = [];

plot_parameters.color_map = [brain_plot_location_colors{:, 2:4}];

electrode_table.value = cellfun(@(x) find(strcmp(locations, x)), electrode_table.neurologist_location);    

end