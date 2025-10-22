function [events_pulses, recording_pulses] = match_blocks(events_pulses, recording_pulses, pulse_info)

burst_starts_events = pulse_info.burst_starts_events;
break_starts_events = pulse_info.break_starts_events;
break_ends_events   = pulse_info.break_ends_events;

burst_starts_recording = pulse_info.burst_starts_recording;
break_starts_recording = pulse_info.break_start_recording;
break_ends_recording   = pulse_info.break_ends_recording;

n_total_pulses_events = length(events_pulses);

n_total_pulses_recording = length(recording_pulses);

if ~any(burst_starts_events == 1)
    block_starts_events = [1; burst_starts_events];
    block_ends_events = [burst_starts_events - 1; n_total_pulses_events];
else
    block_starts_events = burst_starts_events;
    block_ends_events = [burst_starts_events(2:end) - 1; n_total_pulses_events];
end

if ~any(burst_starts_recording == 1)
    block_starts_recording = [1; burst_starts_recording];
    block_ends_recording = [burst_starts_recording - 1; n_total_pulses_recording];
else
    block_starts_recording = burst_starts_recording;
    block_ends_recording = [burst_starts_recording(2:end) - 1; n_total_pulses_recording];
end

n_blocks_events = length(block_starts_events);

event_blocks = cell(n_blocks_events, 1);
n_block_pulses_events = zeros(n_blocks_events, 1);

for idx = 1:n_blocks_events

    event_blocks{idx} = block_starts_events(idx):block_ends_events(idx);
    n_block_pulses_events(idx) = length(event_blocks{idx});

end

n_blocks_recording = length(block_starts_recording);

recording_blocks = cell(n_blocks_recording, 1);
n_block_pulses_recording = zeros(n_blocks_recording, 1);

for idx = 1:n_blocks_recording
    recording_blocks{idx} = block_starts_recording(idx):block_ends_recording(idx);
    n_block_pulses_recording(idx) = length(recording_blocks{idx});
end

if n_blocks_recording > n_blocks_events
    
else

end

end