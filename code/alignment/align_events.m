time_ratios = diff(events_pulses) ./ diff(recording_pulses);
bad_ratios = time_ratios > 1.005 & time_ratios < 0.995;
good_ratios = sum(bad_ratios) <= n_recordings - 1;

bad_idx = find(bad_ratios, 1, 'first');

[corrected_event_pulses, corrected_event_times] = adjust_computer_time(events_pulses, relative_events_pulses, recording_pulses);

coefficients = polyfit(corrected_event_pulses, recording_pulses, 1);

fitted_pulse_starts = round(polyval(coefficients, corrected_event_pulses));

fitted_eegoffset = round(polyval(coefficients, corrected_event_times));

plot_file = sprintf(file_name_holder, '7-corrected');
if ~isfile(plot_file)
    plot_mismatch(plot_file, corrected_event_pulses, recording_pulses, fitted_pulse_starts, corrected_event_times, original_events_pulses, fitted_eegoffset, recording_starts, recording_ends);
end

offset_mismatch = any(original_events_pulses ~= fitted_eegoffset);

if offset_mismatch
    offset_error = original_events_pulses-fitted_eegoffset;
    mean_offset_error = mean(offset_error);
end

fitted_eegoffset = floor(fitted_eegoffset) + min_pulse_start;
adjusted_fitted_eegoffset = fitted_eegoffset;

new_eegfile = repelem({''}, n_events, 1);

corresponding = fitted_eegoffset >= eeg_starts(1) & fitted_eegoffset <= eeg_ends(1)+min_pulse_start-5000;
n_corresponding = sum(corresponding);

new_eegfile(corresponding) = repelem(unique_eegs(1), n_corresponding, 1);

if length(unique_eegs) > 1
    
    for idx = 2:length(unique_eegs)
        time_difference = milliseconds(eeg_dates{idx} - eeg_dates{1});
        corresponding = fitted_eegoffset >= eeg_starts(idx) + min_pulse_start & fitted_eegoffset <= eeg_ends(idx) + min_pulse_start - 5000;
        adjusted_fitted_eegoffset(corresponding) = fitted_eegoffset(corresponding) - time_difference;
        new_eegfile(corresponding) = repelem(unique_eegs(idx), sum(corresponding), 1);
    end

end

out_of_bounds = strcmp(new_eegfile, '') | adjusted_fitted_eegoffset <= 0;

writematrix(corrected_event_pulses, new_pulses_file);