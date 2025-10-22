%%% This function sets a random sample index for every session's first recording.
%%% Returns sample indices.

function sample_idx = n00_set_sample_idx(electrode_list, events_info)

n_sessions = height(events_info);

session_IDs = electrode_list.session_ID;

event_indices = arrayfun(@(x) find(events_info.session_ID == x), session_IDs);

eeg_file_length = cellfun(@(x) x(1), events_info.eeg_file_length);

sample_indices = round(eeg_file_length .* (rand(n_sessions, 1) * 0.4 + 0.3));

sample_idx = sample_indices(event_indices);

end