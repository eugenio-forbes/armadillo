function [events_pulses, recording_pulses] = block_crosscorrelation(plot_file, events_pulses, recording_pulses, pulse_info)

n_blocks_events     = pulse_info.n_blocks_events;
block_starts_events = pulse_info.block_starts_events;
block_ends_events   = pulse_info.block_ends_events;

events_blocks = cell(n_blocks_events, 1);

for idx = 1:n_blocks_events
    events_blocks{idx} = block_starts_events(idx):block_ends_events(idx);
    n_block_pulses_events(idx) = length(events_blocks{idx});
end

n_blocks_recording     = pulse_info.n_blocks_recording;
block_starts_recording = pulse_info.block_starts_recording;
block_ends_recording   = pulse_info.block_ends_recording;

recording_blocks = cell(n_blocks, 1);

for idx = 1:n_blocks_recording
    recording_blocks{idx} = block_starts_recording(idx):block_ends_recording(idx);
    n_block_pulses_recording(idx) = length(recording_blocks{idx});
end

false_grid = false(n_blocks_events, n_blocks_recording);
cell_grid = cell(n_blocks_events, n_blocks_recording);

number_match_grid = false_grid;
correlation_match_grid = false_grid;
bad_pulses_events_grid = cell_grid;
bad_pulses_recording_grid = cell_grid;

for idx = 1:n_blocks_events

    for jdx = 1:n_blocks_recording
    
        event_indices = events_blocks{idx};
        eeg_indices = recording_blocks{jdx};
        
        number_match_grid(idx, jdx) = n_block_pulses_events(idx) == n_block_pulses_recording(jdx);
        
        if n_block_pulses_events(idx) > n_block_pulses_recording(jdx)
            [bad_pulses_events(event_indices), crosscorrelations] = crosscorrelate_pulses(events_pulses(event_indices), recording_pulses(eeg_indices));
        else
            [bad_pulses_recording(eeg_indices), crosscorrelations] = crosscorrelate_pulses(recording_pulses(eeg_indices), events_pulses(event_indices));
        end
        
    end
    
end

plot_crosscorrelation(plot_file, crosscorrelations)

if any(bad_pulses_events)
    events_pulses(bad_pulses_events) = [];
end

if any(bad_pulses_recording)
    recording_pulses(bad_pulses_recording) = [];
end

end