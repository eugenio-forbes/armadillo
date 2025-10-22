function [events_pulses, events_times] = adjust_clock_stop(events_pulses, events_times, recording_pulses, pulse_info)

block_starts_events = sort([1; pulse_info.burst_ends_events]);
block_starts_recording = sort([1; pulse_info.burst_ends_recording]);

n_blocks_events = length(block_starts_events);

for idx = 1:n_blocks_events

    start_time = events_pulses(block_starts_events(idx));
    
    if idx < n_blocks_events
        end_time = events_pulses(block_starts_events(idx+1));
        indices_pulses = block_starts_events(idx):block_starts_events(idx+1)-1;
    else
        end_time = events_pulses(end);
        indices_pulses = block_starts_events(idx):length(events_pulses);
    end
    
    indices_events = events_times > start_time & events_times < end_time;
    
    difference = recording_pulses(block_starts_recording(idx)) - events_pulses(indices_pulses(1));
    
    events_pulses(indices_pulses) = events_pulses(indices_pulses) + difference;
    events_times(indices_events) = events_times(indices_events) + difference;

end

end