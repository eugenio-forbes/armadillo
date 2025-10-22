%%% Based on input data types, this function
%%% generates color maps. Returns concatenated color map
%%% and structure with separate maps and axis limits.

function [color_map, colorbar_struct] = n00_get_color_map(data_types)

colorbar_struct = struct;
data_types = strsplit(data_types, '-');
n_data_types = length(data_types);
color_maps = cell(n_data_types, 1);
caxis_limits = cell(n_data_types, 1);

for idx = 1:n_data_types
    
    data_type = data_types{idx};
    
    switch data_type
        case {'ripple', 'HFA', 'theta_burst', 'beta_burst', 'spike', 'classifier_weight'}
            color_maps{idx} = makecolormap_EF(sprintf('single_gradient%d', idx+3));
            caxis_limits{idx} = [0, 1];
            
        case {'tstat_sigmoid', 'zscore_sigmoid'}
            color_maps{idx} = makecolormap_EF('sigmoid3');
            caxis_limits{idx} = [-3, 3];
            
        case {'EEG', 'ERP', 'tstat_uniform', 'zscore_uniform'}
            color_maps{idx} = makecolormap_EF('uniform1');
            caxis_limits{idx} = [-3, 3];
            
        case 'brain_region'
            color_maps{idx} = get_brain_region_color_map();
            caxis_limits{idx} = [1, size(color_maps{idx}, 1)];
    end
    
end

colorbar_struct.n_colorbars     = n_data_types;
colorbar_struct.colorbar_titles = data_types;
colorbar_struct.color_maps      = color_maps;
colorbar_struct.caxis_limits    = caxis_limits;

color_map = vertcat(color_maps{:});

end


function color_map = get_brain_region_color_map()

analysis_directory = '/path/to/armadillo';
resources_directory = fullfile(analysis_directory, 'resources');
location_color_file = fullfile(resources_directory, 'brain_plots/location_colors', 'brain_plot_location_colors.txt');

brain_plot_location_colors = readtable(location_color_file);
color_map = [brain_plot_location_colors{:, 2:4}] / 255;

end