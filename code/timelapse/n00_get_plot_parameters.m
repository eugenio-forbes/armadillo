function plot_parameters = n00_get_plot_parameters(varargin)

[view_list, plot_title, colorbar_struct, timelapse_parameters] = process_vars(varargin);

plot_parameters = struct;

plot_parameters.scale_down             = 3; %%%Configurable  %%% Set to 1, 2, 3 to get full, quarter, or ninth of standard screen number of pixels.

plot_parameters.max_figure_width       = 1920 / plot_parameters.scale_down;
plot_parameters.max_figure_height      = 1080 / plot_parameters.scale_down;

plot_parameters.view_list              = view_list;

plot_parameters.plot_with_title        = ~isempty(plot_title);
plot_parameters.title                  = plot_title;

plot_parameters.plot_with_colorbar     = ~isempty(colorbar_struct);
plot_parameters.colorbar_struct        = colorbar_struct;
plot_parameters.n_colorbars            = 0;

if ~isempty(colorbar_struct)
    plot_parameters.n_colorbars        = colorbar_struct.n_colorbars;
end

plot_parameters.plot_with_timeline     = false;
plot_parameters.timelapse_parameters   = timelapse_parameters;
plot_parameters.timeline_info          = [];

if ~isempty(timelapse_parameters)
    plot_parameters.plot_with_timeline = ~isempty(timelapse_parameters.timeline_info);
    plot_parameters.timeline_info      = timelapse_parameters.timeline_info;
end

plot_parameters.n_views                = length(view_list);

if plot_parameters.n_views > 2
    plot_parameters.single_view_size   = plot_parameters.max_figure_width / 4;
else
    plot_parameters.single_view_size   = plot_parameters.max_figure_width / 2;
end

plot_parameters.title_height           = 14 * (4 - plot_parameters.scale_down);
plot_parameters.timeline_height        = 13 * (4 - plot_parameters.scale_down);
plot_parameters.colorbar_height        = 13 * (4 - plot_parameters.scale_down);
plot_parameters.font_size              = 10 + (4 * (3 - plot_parameters.scale_down));

[figure_width, figure_height, axes_parameters] = n00_get_frame_axes_parameters(plot_parameters);

plot_parameters.figure_width           = figure_width;
plot_parameters.figure_height          = figure_height;
plot_parameters.axes_parameters        = axes_parameters;

end


function [view_list, plot_title, colorbar_struct, timelapse_parameters] = process_vars(variables)

view_list = {'superior', 'lateral-right', 'medial-right', 'deep-right', 'inferior', 'lateral-left', 'medial-left', 'deep-left'};
plot_title = [];
colorbar_struct = [];
timelapse_parameters = [];

n_varargin = length(variables);

if n_varargin >= 1

    temp_view_list = variables{1};
    
    if ~isempty(temp_view_list)
        view_list = temp_view_list;
    end
    
end

if n_varargin >= 2
    plot_title = variables{2};
end

if n_varargin >= 3
    colorbar_struct = variables{3};
end

if n_varargin >= 4
    timelapse_parameters = variables{4};
end

end