%%% This function takes original event times and alignment results.
%%% Based on alignment results it adjusts event times to accurately
%%% reflect recording times.

function [corrected_events_pulses, corrected_events_times] = adjust_computer_time(event_times, alignment_info)

original_events_pulses = alignment_info.original_events_pulses;
relative_events_pulses = alignment_info.relative_events_pulses;
recording_pulses       = alignment_info.recording_pulses;
min_pulse_start        = alignment_info.min_pulse_start;

pulse_time_differences = recording_pulses - relative_events_pulses;

corrected_events_pulses = recording_pulses;

n_events = length(event_times);
corrected_events_times = NaN(n_events, 1);

min_event_time = min(original_events_pulses);

for idx = 1:n_events

    event_time = event_times(idx);
    event_index = find(original_events_pulses < event_time, 1, 'last');

    if ~isempty(event_index)
        corrected_events_times(idx) = event_time - min_event_time + pulse_time_differences(event_index) + min_pulse_start;        
    end

end

end