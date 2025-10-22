%%% This function takes events and recording pulse times;
%%% calculates time differentials for each set, the ratio
%%% between differentials, and time differences between
%%% matched pairs in each set. Plots 5 different subplots
%%% with y axis being these series, and x axis being
%%% recording or event pulse time.
%%% Saves plot in .png with given plot file name.

function plot_differentials(plot_file, events_pulses, recording_pulses)

%%% Match array sizes and get min and max pulse times for plot x limits
max_length = min(length(events_pulses), length(recording_pulses));

events_pulses = events_pulses(1:max_length);
min_events = min(events_pulses);
max_events = max(events_pulses);

recording_pulses = recording_pulses(1:max_length);
min_recording = min(recording_pulses);
max_recording = max(recording_pulses);

%%% Get pulse time differentials, ratios, and time differences
%%% Min and max of each for plot y limits
diff_events = diff([0; events_pulses]);
min_diff_events = min(diff_events);
max_diff_events = max(diff_events);

diff_recording = diff([0; recording_pulses]);
min_diff_recording = min(diff_recording);
max_diff_recording = max(diff_recording);

diff_ratios = diff_events ./ diff_recording;

pair_difference = recording_pulses - events_pulses;
min_difference = min(pair_difference);
max_difference = max(pair_difference);

%%% 5 by 1 subplots of these measures
figure('Units', 'pixels', 'Position', [0, 0, 1920, 1080], 'Visible', 'off')

subplot(5, 1, 1) %%% Diffential of event pulse times
plot(events_pulses, diff_events)
xlim([min_events, max_events]);
ylim([min_diff_events, max_diff_events]);

subplot(5, 1, 2) %%% Differential of recording pulse times
plot(recording_pulses, diff_recording)
xlim([min_recording, max_recording]);
ylim([min_diff_recording, max_diff_recording]);

subplot(5, 1, 3) %%% Matched pair ratio of differentials
plot(recording_pulses, diff_ratios)
xlim([min_recording, max_recording]);
ylim([0.98, 1.02]);

subplot(5, 1, 4) %%% Matched pair difference of differentials
plot(recording_pulses, diff_recording - diff_events);
xlim([min_events, max_events]);
ylim([-10, 10]);

subplot(5, 1, 5) %%% Matched pair time difference
plot(recording_pulses, pair_difference)
xlim([min_events, max_events]);
ylim([min_difference, max_difference]);

print(plot_file, '-dpng')

close all

end