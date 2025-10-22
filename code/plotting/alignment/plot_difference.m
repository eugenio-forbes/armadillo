function plot_difference(subplot_title, x, y, n_observations, color, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends)

n_eeg_files = length(eeg_starts);

hold on

scatter(x, y, [], repmat(color, n_observations, 1));

if n_eeg_files > 1
    
    for idx = 2:n_eeg_files
    
        plot([eeg_ends(idx - 1), eeg_ends(idx - 1)], y_limits, '--k')
        plot([eeg_starts(idx), eeg_starts(idx)], y_limits, '--k')
    
    end

end

for idx = 1:length(x_ticks)

    if idx == 1
        horizontal_alignment = 'left';
    elseif idx == length(x_ticks)
        horizontal_alignment = 'right';
    else
        horizontal_alignment = 'center';
    end

    plot([x_ticks(idx), x_ticks(idx)], [y_limits(1), y_limits(1) + diff(y_limits) / 100], '-k')

    if ~strcmp(x_tick_labels{idx}, '')
        text(x_ticks(idx), y_limits(1) + diff(y_limits) / 100, x_tick_labels{idx}, 'FontSize', 12, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'bottom');
    end

end

for idx = 1:length(y_ticks)

    if idx == 1
        horizontal_alignment = 'left';
    elseif idx == length(y_ticks)
        horizontal_alignment = 'right';
    else
        horizontal_alignment = 'center';
    end

    if ~strcmp(y_tick_labels{idx}, '')
        text(x_limits(1), y_ticks(idx), y_tick_labels{idx}, 'FontSize', 12, 'HorizontalAlignment', horizontal_alignment, 'VerticalAlignment', 'top', 'Rotation', 90);
    end

end

text(mean(x_limits), y_limits(2), subplot_title, 'FontSize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

xlim(x_limits);xticks([]);xticklabels([]);
ylim(y_limits);yticks([]);yticklabels([]);

hold off

end