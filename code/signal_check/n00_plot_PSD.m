%%% This function generates a single power spectral density plot
%%% given plot parameters specific to input channel index.

function n00_plot_PSD(plot_info, plot_parameters, channel_idx)

n_signals =      plot_info.n_signals;
channel_number = plot_info.channel_numbers(channel_idx);
label =          plot_info.labels{channel_idx};
location =       plot_info.locations{channel_idx};
electrode_ID =   plot_info.electrode_IDs(channel_idx);
frequencies =    plot_info.frequencies;

font_size =     plot_parameters.font_size;
signal_colors = plot_parameters.signal_colors;
signal_types =  plot_parameters.signal_types;

signal_types = strrep(signal_types, 'signals', 'PSDs');

PSD_parameters = plot_parameters.PSD_parameters;

x_limits =      PSD_parameters.x_limits;
x_ticks =       PSD_parameters.x_ticks;
x_tick_labels = PSD_parameters.x_tick_labels;
y_limits =      PSD_parameters.y_limits;
y_ticks =       PSD_parameters.y_ticks;
y_tick_labels = PSD_parameters.y_tick_labels;

hold on

for idx = 1:n_signals
    plot(frequencies, plot_info.(signal_types{idx})(channel_idx, :), '-', 'Color', signal_colors(idx, :), 'LineWidth', 2);
end

xlim(x_limits); xticks(x_ticks); xticklabels([]);
ylim(y_limits); yticks(y_ticks); yticklabels([]);

if channel_number == max(plot_info.channel_numbers)

    for idx = 1:length(x_ticks)
    
        if ~isempty(x_tick_labels{idx})
        
            if idx == 1
                horizontal_alignment = 'left';
            elseif idx == length(y_ticks)
                horizontal_alignment = 'right';
            else
                horizontal_alignment = 'center';
            end
            
            text(x_ticks(idx), y_limits(1) + (0.01 * diff(y_limits)), x_tick_labels{idx}, 'Color', [225 150 25] / 255, 'FontSize', font_size, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'bottom');
        
        end
        
    end
    
    for idx = 1:length(y_ticks)
    
        if idx == 1
            vertical_alignment = 'bottom';
        elseif idx == length(y_ticks)
            vertical_alignment = 'top';
        else
            vertical_alignment = 'middle';
        end
        
        if ~isempty(y_tick_labels{idx})
            text(x_limits(2) - (0.01 * diff(x_limits)), y_ticks(idx), y_tick_labels{idx}, 'Color', [225 150 25] / 255, 'FontSize', font_size, 'HorizontalAlignment', 'right', 'VerticalAlignment', vertical_alignment);
        end
        
    end
    
else

    text(mean(x_limits), y_limits(1) + (0.01 * diff(y_limits)), location, 'FontSize', font_size * 0.5, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
    text(x_limits(1) + (0.01 * diff(x_limits)), y_limits(2) - (0.01 * diff(y_limits)), label, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top');
    text(x_limits(2) - (0.01 * diff(x_limits)), y_limits(2) - (0.01 * diff(y_limits)), num2str(electrode_ID), 'FontSize', font_size, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top');
    text(mean(x_limits), y_limits(2) - (0.01 * diff(y_limits)), num2str(channel_number), 'Color', [225 150 25] / 255, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

end

hold off

end