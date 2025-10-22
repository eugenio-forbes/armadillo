%%% This function takes event and recording pulse times,
%%% matches them in size, and plots pairs with event pulse
%%% time in x axis and recording pulse time in y axis.
%%% For correctly aligned pulses the result should be a
%%% straight line.

function plot_corresponding(plot_file, event_pulses, eeg_pulses)

max_length = min(length(event_pulses), length(eeg_pulses));

event_pulses = event_pulses(1:max_length);
min_event = min(event_pulses);
max_event = max(event_pulses);

eeg_pulses = eeg_pulses(1:max_length);
min_eeg = min(eeg_pulses);
max_eeg = max(eeg_pulses);

figure('Units', 'pixels', 'Position', [0, 0, 1920, 1080], 'Visible', 'off')
plot(event_pulses, eeg_pulses)
xlim([min_event, max_event]);
ylim([min_eeg, max_eeg]);

print(plot_file, '-dpng')

close all

end