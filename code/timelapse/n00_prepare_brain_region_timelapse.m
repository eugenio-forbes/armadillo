function n00_prepare_brain_region_timelapse(varargin)
if isempty(varargin)
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder = 'armadillo';
    tasks = {'AR', 'AR_stim', 'AR_Scopolamine'};
    data_type = 'brain_region';
    view_list = [];
else
    root_directory = varagin{1};
    username = varagin{2};
    analysis_folder = varargin{3};
    tasks = varagin{4};
    data_type = varargin{5};
    view_list = varargin{6};
end

plot_title = 'Color Coded Brain Regions';

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder);
list_directory = fullfile(analysis_directory, 'lists');
plot_directory = fullfile(analysis_directory, 'plots/timelapses/brain_region_timelapse');
if ~isfolder(plot_directory)
    mkdir(plot_directory);
end
plot_filename = fullfile(plot_directory, 'brain_region_all_tasks.gif');

load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

location_table = n00_make_location_table(electrode_list, {'OUT'});

unique_locations = unique(regexprep(location_table.location, '(Left|Right)\s', ''));
n_locations = length(unique_locations);
n_time_points = n_locations;

electrode_list(~ismember(electrode_list.task, tasks), :) = [];
electrode_list(~ismember(electrode_list.neurologist_location, unique_locations), :) = [];
electrode_list(cellfun(@isempty, electrode_list.coordinates), :) = [];

[~, unique_electrodes, ~] = unique(electrode_list.electrode_ID);

electrode_list = electrode_list(unique_electrodes, {'neurologist_location', 'coordinates', 'hemisphere'});

electrode_list = get_brain_region_values(electrode_list, analysis_directory);

[~, colorbar_struct] = n00_get_color_map(data_type);

%%% Timelapse parameters
timelapse_parameters = struct;
timelapse_parameters.timelapse_duration = 4;
timelapse_parameters.start_mode         = 'region_colors';
timelapse_parameters.start_duration     = 4;
timelapse_parameters.n_time_points      = n_time_points;

timeline_info = struct;
timeline_info.title                = data_type;
timeline_info.limits               = [1, n_locations];
timelapse_parameters.timeline_info = timeline_info;

plot_parameters = n00_get_plot_parameters(view_list, plot_title, colorbar_struct, timelapse_parameters);
plot_parameters.data_type      = data_type;
plot_parameters.root_directory = analysis_directory;
plot_parameters.plot_filename  = plot_filename;

n00_make_brain_region_timelapse(electrode_list, plot_parameters);

end


function electrode_table = get_brain_region_values(electrode_table, root_directory)

resources_directory = fullfile(root_directory, 'resources');
location_color_file = fullfile(resources_directory, 'brain_plots/location_colors', 'brain_plot_location_colors.txt');

brain_plot_location_colors = readtable(location_color_file);

locations = brain_plot_location_colors.Var1;

electrode_table = electrode_table(ismember(electrode_table.neurologist_location, locations), :);
shifted = cellfun(@(x) x(:, 3) < -50, electrode_table.coordinates);
electrode_table(shifted, :) = [];

electrode_table.value = cellfun(@(x) find(strcmp(locations, x)), electrode_table.neurologist_location);
    
end