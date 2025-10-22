%%% This function plots legend with each color representing a different signal type

function n00_plot_signal_colors(plot_parameters)

font_size =     plot_parameters.font_size;
signal_colors = plot_parameters.signal_colors;
signal_types =  plot_parameters.signal_types;

n_signals = length(signal_types);

x_limits = [0, n_signals * 250];
y_limits = [0, 1];

shape_x = [0, 0, 50, 50, 0];
shape_y = [0.1, 0.9, 0.9, 0.1, 0.1];

for idx = 1:n_signals

    current_x = 250 * (idx - 1) + 5;
    
    patch((ones(1, 5) * current_x) + shape_x, shape_y, signal_colors(idx, :));
    
    text(current_x + 75, 0.1, signal_types{idx}, 'FontSize', font_size);
    
end

xlim(x_limits);
ylim(y_limits);

ends