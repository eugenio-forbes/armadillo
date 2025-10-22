function plot_behavioral_grid(analysis_parameters, plot_parameters, behavioral_grid, grid_type)

hold on

subplot_width  = plot_parameters.subplot_width;
subplot_height = plot_parameters.subplot_height;
x_margin       = plot_parameters.x_margin;
y_margin       = plot_parameters.y_margin;
font_name      = plot_parameters.font_name;
font_size      = plot_parameters.font_size;

n_groups      = analysis_parameters.n_groups;
group_labels  = analysis_parameters.group_labels;
has_condition = analysis_parameters.has_condition;
condition     = analysis_parameters.condition;

x_space = [x_margin, subplot_width - x_margin];
y_space = [y_margin, subplot_height - y_margin];

grid_width = diff(x_space);
grid_height = diff(y_space);

square_width = grid_width / n_groups;
square_height = grid_height / n_groups;

grid_x = [x_space(1) + (square_width / 2), x_space(2) - (square_width / 2)];
grid_y = [y_space(1) + (square_height / 2), y_space(2) - (square_height / 2)];

grid_box_x = [repmat(x_space(1), 1, 2), repmat(x_space(2), 1, 2), x_space(1)];
grid_box_y = [y_space(1), repmat(y_space(2), 1, 2), repmat(y_space(1), 1, 2)];

x_coordinates = linspace(grid_x(1), grid_x(2), n_groups);
y_coordinates = linspace(grid_y(2), grid_y(1), n_groups);

grid_lines_x = x_coordinates(1:end - 1) + (square_width / 2);
grid_lines_y = y_coordinates(1:end - 1) + (square_height / 2);

diagonal_x = [reshape(repmat(x_coordinates - (square_width / 2), 2, 1), [], 1); reshape(repmat(fliplr(x_coordinates + (square_width / 2)), 2, 1), [], 1); x_space(1)];
diagonal_y = [y_space(2); reshape(repmat(y_coordinates - (square_height / 2), 2, 1), [], 1); reshape(repmat(fliplr(y_coordinates + (square_height / 2)), 2, 1), [], 1)];

y_label = '';

switch grid_type
    case 'effects'
        x_label = 'group fixed effect';
        if has_condition
            y_label = sprintf('%s interaction', condition);
        end
    
    case 'behavior_correlation'
        x_label = 'group correlation';
        if has_condition
            y_label = sprintf('%s correlation', condition);
        end
        
    case 'time_correlation'
        x_label = 'time correlation';
        if has_condition
            y_label = sprintf('%s correlation', condition);
        end         
end

x_label_x = subplot_width / 2;
x_label_y = y_margin - 1;

y_label_x = x_space(2) + 1;
y_label_y = subplot_height / 2;

image(grid_x, grid_y, behavioral_grid);

for idx = 1:n_groups - 1

    plot(repmat(grid_lines_x(idx), 2, 1), y_space, '-k', 'LineWidth', 1);
    plot(x_space, repmat(grid_lines_y(idx), 2, 1), '-k', 'LineWidth', 1);
    
end

plot(grid_box_x, grid_box_y, '-k', 'LineWidth', 2);

if has_condition
    plot(diagonal_x, diagonal_y, '-k', 'LineWidth', 2);
end

text(x_label_x, x_label_y, x_label, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(y_label_x, y_label_y, y_label, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'center', 'Rotation', 290);

for idx = 1:n_groups

    text(x_coordinates(idx), y_space(2) + 1, group_labels{idx}, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    text(x_space(1) - 1, y_coordinates(idx), group_labels{idx}, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'center');

end

xlim(gca, [0, subplot_width]); xticks([]); xticklabels([]);
ylim(gca, [0, subplot_height]); yticks([]); yticklabels([]);

hold off

end