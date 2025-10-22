function plot_mismatch(plot_file, event_pulses, eeg_pulses, fitted_pulses, event_times, original_offsets, fitted_offsets, eeg_starts, eeg_ends)

n_pulses = length(event_pulses);
n_events = length(event_times);

differences_pulses = zeros(n_pulses, 3);
differences_pulses(:, 1) = eeg_pulses - event_pulses;
differences_pulses(:, 2) = fitted_pulses - eeg_pulses;
differences_pulses(:, 3) = fitted_pulses - event_pulses;

differences_offsets = zeros(n_events, 3);
differences_offsets(:, 1) = original_offsets - event_times;
differences_offsets(:, 2) = fitted_offsets - original_offsets;
differences_offsets(:, 3) = fitted_offsets - event_times;

min_time = min([0, fitted_pulses(1), fitted_offsets(1), original_offsets(1)]);
max_time = max([event_pulses(end), eeg_pulses(end), fitted_pulses(end), max(event_times), fitted_offsets(end), original_offsets(end)]);
span = ceil(max_time)-floor(min_time);

n5_min = 300000;
n_lines = ceil(span / n5_min);
n_missing = (n_lines * n5_min) - span;

signals = false(6, span + n_missing);

for idx = 1:n_pulses

    events_idx = floor(event_pulses(idx) - floor(min_time)) + 1;
    eeg_idx = floor(eeg_pulses(idx) - floor(min_time)) + 1;
    fitted_idx = floor(fitted_pulses(idx) - floor(min_time)) + 1;

    if events_idx > 0
        signals(1, events_idx) = true;
    end

    if eeg_idx > 0
        signals(2, eeg_idx) = true;
    end

    if fitted_idx > 0
        signals(3, fitted_idx) = true;
    end

end

for idx = 1:n_events

    events_idx = floor(event_times(idx) - floor(min_time)) + 1;
    eeg_idx = floor(original_offsets(idx) - floor(min_time)) + 1;
    fitted_idx = floor(fitted_offsets(idx) - floor(min_time)) + 1;

    if events_idx > 0
        signals(4, events_idx) = true;
    end

    if eeg_idx > 0
        signals(5, eeg_idx) = true;
    end

    if fitted_idx > 0
        signals(6, fitted_idx) = true;
    end

end

[~, red, blue, orange, purple, green, pink] = get_color_selection();

figure_width = 1920;
figure_height = 1080;

n1_hr = n5_min * 12;

x_limits = [min_time - (span * 0.1), max_time + (span * 0.1)];

x_ticks = unique([min_time, 0:n5_min:max_time, max_time]);

x_tick_labels = repelem({''}, length(x_ticks), 1);
x_tick_labels{x_ticks == min_time} = [num2str(min_time), 'ms'];    
x_tick_labels{x_ticks == max_time} = [sprintf('%.2f', max_time/n1_hr), 'hr'];

figure_handle = figure('Units', 'pixels', 'Position', [0, 0, figure_width, figure_height], 'Visible', 'off');

subplot_height_error = figure_height / 3;
subplot_height = figure_height / 2;
subplot_width = figure_width - (2 * subplot_height_error);

subplot_title = 'Pulses: Events(green), EEG (red), Fitted (blue)';
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [0, subplot_height, subplot_width, subplot_height], 'Visible', 'off')
plot_signals(subplot_title, signals(1:3, :), green, red, blue);

subplot_title = 'Offsets: Events(purple), Original (pink), Fitted (orange)';
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [0, 0, subplot_width, subplot_height], 'Visible', 'off')
plot_signals(subplot_title, signals(4:6, :), purple, pink, orange);

subplot_height = subplot_height_error;
subplot_x = subplot_width;

subplot_title = 'EEG Pulses - Event Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 1));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height * 2, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 1), n_pulses, blue, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Pulses - EEG Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 2));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 2), n_pulses, green, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Pulses - Event Pulses';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_pulses(:, 3));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, 0, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_pulses, differences_pulses(:, 3), n_pulses, red, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_x = subplot_width + subplot_height_error;

subplot_title = 'Original Offsets - Event times';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 1));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height*2, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 1), n_events, purple, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Offsets - Original Offsets';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 2));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, subplot_height, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 2), n_events, orange, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

subplot_title = 'Fitted Offsets - Event Times';
[y_limits, y_ticks, y_tick_labels] = get_y_ticks(differences_offsets(:, 3));
axes('Parent', figure_handle, 'Units', 'pixels', 'Position', [subplot_x, 0, subplot_height, subplot_height], 'Visible', 'off')
plot_difference(subplot_title, event_times, differences_offsets(:, 3), n_events, pink, x_limits, x_ticks, x_tick_labels, y_limits, y_ticks, y_tick_labels, eeg_starts, eeg_ends);

print(plot_file, '-dpng')

close all

end