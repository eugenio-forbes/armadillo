function n03_plot_CPS_trajectories(plot_file_name, events)

locations = events.lead1;
unique_locations = unique(locations);
n_locations = length(unique_locations);

plot_file_name = [plot_file_name, '_CPS_trajectories'];

%%% Plot parameters
figure_width = 1920;
figure_height = 1080;
subplot_height = figure_height / n_locations;
axes_y = linspace(figure_height - subplot_height, 0, n_locations)';
axes_positions = [zeros(n_locations, 1), axes_y, repmat(figure_width, n_locations, 1), repmat(subplot_height, n_locations, 1)];
color_map = makecolormap_EF('sigmoid3');

%%% Figure
figure_handle = figure('Units', 'pixels', 'Position', [0, 0, figure_width, figure_height], 'Visible', 'off');

for idx = 1:n_locations
    
    location = unique_locations{idx};
    location_events = events(strcmp(events.lead1, location), :);
    
    axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(idx, :), 'Visible', 'off')
    
    plot_location_trajectories(location_events, color_map);

end

print(plot_file_name, '-dpng')

close all

end

function plot_location_trajectories(events, color_map)

n_events = height(events);
is_stim = events.is_stim;

x_ticks = 5:5:n_events;
x_tick_labels = arrayfun(@num2str, x_ticks, 'UniformOutput', false);

amplitudes = events.amplitude;
unique_amplitudes = unique(amplitudes);
amplitude_labels = arrayfun(@num2str, unique_amplitudes, 'UniformOutput', false);

probability_changes = events.probability_change;
standard_deviation = median(abs(probability_changes)) / 0.6745;
c_limits = standard_deviation * [-3, 3];
probability_changes = round(1000 * (probability_changes / standard_deviation) + 3000);

too_low = probability_changes <= 0;
too_high = probability_changes > 6000;

probability_changes(too_low) = ones(sum(too_low), 1);
probability_changes(too_high) = 6000*ones(sum(too_high), 1);

colors = color_map(probability_changes, :);
colors(~is_stim, :) = repmat([0.3, 0.3, 0.3], sum(~is_stim), 1);

plot(1:n_events, amplitudes, '--', 'Color', [0.3, 0.3, 0.3])

scatter(1:n_events, amplitudes, [], colors, 'filled');

ylim([min(amplitudes) - 0.5, max(amplitudes) + 0.5]); yticks(unique_amplitudes); yticklabels(amplitude_labels);
xlim([0, n_events + 1]); xticks(x_ticks); xticklabels(x_tick_labels);

end