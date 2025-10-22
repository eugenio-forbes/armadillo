%%% This function takes start times and end times of split recordings with missing intervening data,
%%% to identify event pulse times that would fall within this window and remove them. Returns logical
%%% array indicating event pulses that should be removed.

function bad_events_pulses = remove_pulses_between_split_recordings(events_pulses, recording_pulses, pulse_info, recording_starts, recording_ends)

block_starts_events    = pulse_info.block_starts_events;
block_starts_recording = pulse_info.block_starts_events;

n_recordings = length(recording_starts);

n_blocks = length(block_starts_events);

bad_events_pulses = false(length(events_pulses), 1);

for idx = 1:n_recordings - 1

    break_start = recording_ends(idx);
    
    block_split = find(recording_pulses(block_starts_recording) < break_start, 1, 'last');
    
    events_block_start = block_starts_events(block_split);
    eeg_block_start = block_starts_recording(block_split);

    if block_split<n_blocks
        events_block_end = block_starts_events(block_split+1)-1;
        eeg_block_end = block_starts_recording(block_split+1)-1;
    else
        events_block_end = length(events_pulses);
        eeg_block_end = length(recording_pulses);
    end

    n_block_pulses_events = events_block_end - events_block_start + 1;
    n_block_pulses_eeg = eeg_block_end - eeg_block_start + 1;
    
    block_pulses_eeg = recording_pulses(eeg_block_start:eeg_block_end);
    
    n_before_split = sum(block_pulses_eeg < break_start);
    n_missing = n_block_pulses_events - n_block_pulses_eeg;

    if n_missing > 0
        pulse_exclusion = false(n_block_pulses_events, 1);
        pulse_exclusion(n_before_split + 1:n_before_split + n_missing) = true(n_missing, 1);
        bad_events_pulses(events_block_start:events_block_end) = pulse_exclusion;
    end

end

end