%%% This function generates 2D plots for each signal type in input plot information
%%% In each 2D plot y-axis represents channel numbe, x-axis sample number, and amplitude
%%% of signal is color coded with plotted colorbar indicating amplitudes.

function n00_plot_signals_together(plot_info, plot_parameters, idx)

sample_size =     plot_info.sample_size;
channel_numbers = plot_info.channel_numbers;

max_channel_number = max(channel_numbers);

font_size =   plot_parameters.font_size;
signal_type = plot_parameters.signal_types{idx};

signal_parameters = plot_parameters.signal_parameters;

x_limits =      signal_parameters.x_limits;
x_ticks =       signal_parameters.x_ticks;
x_tick_labels = signal_parameters.x_tick_labels;
y_limits =      signal_parameters.y_limits_together;
y_ticks =       signal_parameters.y_ticks_together;

caxis_limits = plot_parameters.colorbar_struct.caxis_limits{idx};

expanded_x_limits = [x_limits(1) - (0.03 * diff(x_limits)), x_limits(2) + (0.03 * diff(x_limits))];
expanded_y_limits = [y_limits(1) - (0.03 * diff(y_limits)), y_limits(2) + (0.03 * diff(y_limits))];

plot_box_x = [x_limits(1), x_limits(1), x_limits(2), x_limits(2), x_limits(1)];
plot_box_y = [y_limits(1), y_limits(2), y_limits(2), y_limits(1), y_limits(1)];

signal_image = zeros(max_channel_number, sample_size);
signal_image(channel_numbers, :) = [plot_info.(signal_type)];

color_map = makecolormap_EF('uniform1');

hold on

ax = gca;

imagesc(signal_image);

set(gca, 'YDir', 'normal');

colormap(color_map);
caxis(caxis_limits);

plot(plot_box_x, plot_box_y, '-k', 'LineWidth', 1.5);

for idx = 1:length(x_ticks)
    
    if ~isempty(x_tick_labels{idx})
        
        if idx == 1
            horizontal_alignment = 'left';
        elseif idx == length(x_ticks)
            horizontal_alignment = 'right';
        else
            horizontal_alignment = 'center';
        end
        
        text(x_ticks(idx), y_limits(1) + (0.01 * diff(y_limits)), x_tick_labels{idx}, 'Color', [225 150 25] / 255, 'FontSize', font_size, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'bottom');
    
    end
    
    plot([x_ticks(idx), x_ticks(idx)], [min(y_limits), min(y_limits) + (0.01 * diff(y_limits))], '-k', 'LineWidth', 1);

end

for idx = 1:length(y_ticks)

    if idx == 1
        vertical_alignment = 'bottom';
    elseif idx == length(y_ticks)
        vertical_alignment = 'top';
    else
        vertical_alignment = 'middle';
    end
    
    text(x_limits(1) + (0.01 * diff(x_limits)), y_ticks(idx), num2str(y_ticks(idx)), 'Color', [225 150 25] / 255, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', vertical_alignment);
    
    plot([min(x_limits), min(x_limits) + (0.02 * diff(x_limits))], [y_ticks(idx), y_ticks(idx)], '-k', 'LineWidth', 1);

end

text(mean(x_limits), y_limits(2), strrep(signal_type, '_', ' '), 'Color', [0.2 0.2 0.2], 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
text(mean(x_limits), y_limits(1), 'sample time (ms)', 'Color', [0.2 0.2 0.2], 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
text(x_limits(1), mean(y_limits), 'channel number', 'Color', [0.2 0.2 0.2], 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'Rotation', 90);

xlim(expanded_x_limits);
ylim(expanded_y_limits);

ax.Visible = 'off';

hold off

end