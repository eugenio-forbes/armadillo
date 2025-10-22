function [figure_width, figure_height, axes_parameters] = n00_get_frame_axes_parameters(plot_parameters)

figure_height = 0;
figure_width = 0;

axes_count = 0;
current_axis_bottom = 0;

axes_parameters = struct;
timeline_parameters = struct;
colorbar_parameters = struct;
view_parameters = struct;
title_parameters = struct;

plot_with_timeline = plot_parameters.plot_with_timeline;
plot_with_colorbar = plot_parameters.plot_with_colorbar;
plot_with_title    = plot_parameters.plot_with_title;
colorbar_struct    = plot_parameters.colorbar_struct;

n_views = plot_parameters.n_views;
n_colorbars = plot_parameters.n_colorbars;
single_view_size = plot_parameters.single_view_size;

axes_parameters.n_axes = n_views + plot_with_title + n_colorbars + plot_with_timeline;

switch num2str(n_views)
    case {'1', '2', '3'}
        n_rows = 1;
    otherwise
        n_rows = 2;
end

figure_height = figure_height + (single_view_size * n_rows);

switch num2str(n_views)
    case {'1'}
        figure_width = single_view_size;
    case {'2', '4'}
        figure_width = single_view_size * 2;
    case {'3', '5', '6'}
        figure_width = single_view_size * 3;
    case {'7', '8'}
        figure_width = single_view_size * 4;
end

switch num2str(n_views)
    case {'1', '2', '3'}
        change_row_idx = n_views;
    case {'4'}
        change_row_idx = [2, n_views];
    case {'5', '6'}
        change_row_idx = [3, n_views];
    case {'7', '8'}
        change_row_idx = [4, n_views];
end

if plot_with_timeline
    figure_height = figure_height + plot_parameters.timeline_height;
end

if plot_with_colorbar
    figure_height = figure_height + plot_parameters.colorbar_height;
end

if plot_with_title
    figure_height = figure_height + plot_parameters.title_height;
end

if plot_with_timeline
    timeline_parameters.axes_idx = axes_count + 1;
    axes_count = axes_count + 1;
    timeline_parameters.position = [0, current_axis_bottom, figure_width, plot_parameters.timeline_height];
    current_axis_bottom = current_axis_bottom + plot_parameters.timeline_height;
end

if plot_with_colorbar
    colorbar_parameters.axes_indices = axes_count + 1 : axes_count + n_colorbars;
    axes_count = axes_count + n_colorbars;
    colorbar_positions = cell(n_colorbars, 1);
    colorbar_width = figure_width / n_colorbars;
    for idx = 1:n_colorbars
        colorbar_positions{idx} = [(idx - 1) * colorbar_width, current_axis_bottom, colorbar_width, plot_parameters.colorbar_height];
    end
    current_axis_bottom = current_axis_bottom + plot_parameters.colorbar_height;
    colorbar_parameters.positions = colorbar_positions;
end

view_parameters.axes_indices = axes_count + 1 : axes_count + n_views;

axes_count = axes_count + n_views;

view_positions = cell(n_views, 1);
current_view_left = 0;

for idx = 1:n_views

    view_positions{idx} = [current_view_left, current_axis_bottom, single_view_size, single_view_size];
    
    if ismember(idx, change_row_idx)
        current_view_left = 0;
        current_axis_bottom = current_axis_bottom + single_view_size;
    else
        current_view_left = current_view_left + single_view_size;
    end
    
end

view_parameters.positions = view_positions;

if plot_with_title
    title_parameters.axes_idx = axes_count + 1;
    title_parameters.position = [0, current_axis_bottom, figure_width, plot_parameters.title_height];
end

axes_parameters.timeline_parameters = timeline_parameters;
axes_parameters.colorbar_parameters = colorbar_parameters;
axes_parameters.view_parameters     = view_parameters;
axes_parameters.title_parameters    = title_parameters;

end