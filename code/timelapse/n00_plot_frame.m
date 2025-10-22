function n00_plot_frame(electrode_table, plot_parameters)

figure_handle   = plot_parameters.figure_handle;
axes_parameters = plot_parameters.axes_parameters;

n_axes = axes_parameters.n_axes;

axes_handles = zeros(n_axes, 1);

plot_with_timeline = plot_parameters.plot_with_timeline;

if plot_with_timeline
    
    timeline_parameters = axes_parameters.timeline_parameters;
    timeline_mode = plot_parameters.timeline_mode;
    
    axes_handles(timeline_parameters.axes_idx) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', timeline_parameters.position);
    
    if strcmp(timeline_mode, 'include')
        n00_plot_timeline(axes_handles(timeline_parameters.axes_idx), plot_parameters)
    else
        ax = gca;
        ax.Visible = 'off';
    end
    
end
    
plot_with_colorbar = plot_parameters.plot_with_colorbar;
colorbar_struct = plot_parameters.colorbar_struct;

if plot_with_colorbar

    colorbar_parameters = axes_parameters.colorbar_parameters;
    
    n_colorbars = colorbar_struct.n_colorbars;
    
    positions    = colorbar_parameters.positions;
    axes_indices = colorbar_parameters.axes_indices;
    
    colorbar_mode = plot_parameters.colorbar_mode;
    
    for idx = 1:n_colorbars
    
        axes_handles(axes_indices(idx)) = axes('Parent', figure_handle, 'Visible', 'off', 'Units', 'pixels', 'Position', positions{idx});
        
        if strcmp(colorbar_mode, 'include')
            n00_plot_colorbar(axes_handles, plot_parameters, idx)
        else
            ax = gca;
            ax.Visible = 'off';
        end
        
    end
    
end

view_list = plot_parameters.view_list;

view_parameters = axes_parameters.view_parameters;

positions    = view_parameters.positions;
axes_indices = view_parameters.axes_indices;

for idx = 1:plot_parameters.n_views

    brain_view = view_list{idx};
    
    is_part_of_view = is_part_of(brain_view, electrode_table, plot_parameters);
        
    axes_handles(axes_indices(idx)) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', positions{idx});
    
    n00_brain_plot(brain_view, electrode_table(is_part_of_view, :), plot_parameters);
    
end

plot_with_title = plot_parameters.plot_with_title;

if plot_with_title

    title_parameters = axes_parameters.title_parameters;
    
    position = title_parameters.position;
    axes_idx = title_parameters.axes_idx;
    
    axes_handles(axes_idx) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', position);
    
    n00_plot_title(axes_handles(axes_idx), plot_parameters);
    
end

plot_parameters.axes_handles = axes_handles;

end


function is_part_of_view = is_part_of(view, electrode_table, plot_parameters)

root_directory = plot_parameters.root_directory;
resources_directory = fullfile(root_directory, 'resources');

locations = electrode_table.neurologist_location;

is_left = strcmp(electrode_table.hemisphere, 'left');
list_directory = fullfile(resources_directory, 'brain_plot_view_location_lists');

view_location_list_name = regexprep(view, '(-left|-right)', '');
view_location_list_file = fullfile(list_directory, sprintf('%s_view_location_list.txt', view_location_list_name));

file_id = fopen(view_location_list_file, 'r');
view_location_list = textscan(file_id, '%s', 'Delimiter', '\n');
fclose(file_id);

is_part_of_view = ismember(locations, view_location_list{1});

if contains(view, 'left')
    is_part_of_view = is_part_of_view & is_left;
elseif contains(view, 'right')
    is_part_of_view = is_part_of_view & ~is_left;
end
        
end