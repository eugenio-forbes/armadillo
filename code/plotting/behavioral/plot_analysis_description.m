function plot_analysis_description(analysis_parameters, plot_parameters)

hold on

subplot_width  = plot_parameters.subplot_width;
subplot_height = plot_parameters.subplot_height;
font_name      = plot_parameters.font_name;
font_size      = plot_parameters.font_size;
color_maps     = plot_parameters.color_maps;
n_color_maps   = height(color_maps);

included_tasks         = strjoin(analysis_parameters.included_tasks, ', ');
experimental_condition = analysis_parameters.experimental_condition;
task_phase             = analysis_parameters.task_phase;
fixed_effect           = analysis_parameters.fixed_effect;
groupings              = analysis_parameters.groupings;
n_groupings            = analysis_parameters.n_groupings;

center_x = subplot_width / 2;
title_y = subplot_height - 5;

text(center_x, title_y, 'Analysis Parameters', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAligment', 'top');

parameter_x = 5;
value_x = 80;
row_y = title_height - 15:-15:title_height - (15 * 8);

text(parameter_x, row_y(1), 'Task:', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
text(value_x, row_y(1), included_tasks, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');

text(parameter_x, row_y(2), 'Condition:', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
text(value_x, row_y(2), experimental_condition, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');

text(parameter_x, row_y(3), 'Task Phase:', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
text(value_x, row_y(3), task_phase, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');

text(parameter_x, row_y(4), 'Fixed Effect:', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
text(value_x, row_y(4), fixed_effect, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');

text(parameter_x, row_y(5), 'Grouping by:', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');

for idx = 1:n_groupings
    text(value_x, row_y(4 + idx), ['-', groupings{idx}], 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
end

color_maps_y = subplot_height - 160;
color_map_type_x = 5;
color_map_min_x = 123;
color_map_max_x = 192;

text(center_x, color_maps_y, 'Color Maps', 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAligment', 'top');

row_y = color_maps_y:-20:color_maps_y - (20 * n_color_maps);

for idx = 1:n_colormaps

    color_map_type = color_maps.color_map_type{idx};
    caxis_limits = color_maps.caxis_limits{idx};
    color_map_min = caxis_limits(1)
    color_map_max = caxis_limits(2);
    color_map = color_maps.color_map{idx};
    
    n_colors = size(color_map, 1);
    color_map = reshape(color_map', [1, n_colors, 3]);
    
    color_map_x = [color_map_min_x, color_map_max_x];
    color_map_y = [row_y(idx) - font_size - 1, row_y(idx) + 1];
    
    color_map_box_x = [repmat(color_map_x(1), 1, 2), repmat(color_map_x(2), 1, 2), color_map_x(1)];
    color_map_box_y = [color_map_y(1), repmat(color_map_y(2), 1, 2), repmat(color_map_y(1), 1, 2)];
    
    text(color_map_type_x, row_y(idx), color_map_type, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
    text(color_map_min_x, row_y(idx), num2str(color_map_min), 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'right', 'VerticalAligment', 'top');
    text(color_map_max_x, row_y(idx), num2str(color_map_max), 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAligment', 'top');
    
    image(color_map_x, color_map_y, color_map)
    plot(color_map_box_x, color_map_box_y, '-k', 'LineWidth', 0.5)
    
end

xlim(gca, [0, subplot_width]); xticks([]); xticklabels([]);
ylim(gca, [0, subplot_height]); yticks([]); yticklabels([]);

hold off

end