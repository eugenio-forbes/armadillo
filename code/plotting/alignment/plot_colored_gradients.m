%%% This function takes events and recording pulse times,
%%% assigns colors to each pulse based on elapsed time from previous pulse
%%% and plots two subplots comparing pulse differential between
%%% behavioral events and recording pulses. Also plots lines indicating
%%% a break in pulses.
%%% Saves plot in .png with given plot file name.

function plot_colored_gradients(plot_file, events_pulses, recording_pulses)

%%% Minima and maxima of pulse times for plot limits
min_events = min(events_pulses);
max_events = max(events_pulses);

min_recording = min(recording_pulses);
max_recording = max(recording_pulses);

%%% Get differentials of pulse times to identify breaks and assign colors to pulses
diff_events = diff([0; events_pulses]);
events_breaks =  events_pulses(diff_events > 7500);
events_colors = get_diff_colors(diff_events);

diff_recording = diff([0; recording_pulses]);
recording_breaks = recording_pulses(diff_recording > 7500);
recording_colors = get_diff_colors(diff_recording);

%%% Plotting of pulses with assigned colors and black lines indicating breaks

figure('Units', 'pixels', 'Position', [0, 0, 1920, 1080], 'Visible', 'off')

subplot(2, 1, 1)
hold on

scatter(events_pulses, events_pulses, [], events_colors);

for idx = 1:length(events_breaks)
    plot(repmat(events_breaks(idx), 1, 2), [min_events, max_events], '-k')
end

hold off
xlim([min_events, max_events]);
ylim([min_events, max_events]);
title('Events')


subplot(2, 1, 2)
hold on

scatter(recording_pulses, recording_pulses, [], recording_colors);

for idx = 1:length(recording_breaks)
    plot(repmat(recording_breaks(idx), 1, 2), [min_recording, max_recording], '-k')
end

hold off
xlim([min_recording, max_recording]);
ylim([min_recording, max_recording]);
title('Recording')

print(plot_file, '-dpng')

close all

end