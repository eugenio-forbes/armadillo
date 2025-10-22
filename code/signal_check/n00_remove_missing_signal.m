function [electrode_list, events_info] = n00_remove_missing_signal(electrode_list, events_info)

electrode_IDs = electrode_list.electrode_ID;
session_IDs = electrode_list.session_ID;

is_aligned = events_info.is_aligned;
unaligned_sessions = events_info.session_ID(~is_aligned);

events_info = events_info(is_aligned, :);

missing_channels = contains(events_info.reason_bad, 'channels_missing');
sessions_missing_channels = events_info.session_ID(missing_channels);
missing_channels = horzcat(events_info.missing_channels{missing_channels});
missing_channels = horzcat(missing_channels{:});

is_missing = ismember(electrode_IDs, missing_channels) & ismember(session_IDs, sessions_missing_channels);
is_missing = is_missing | ismember(session_IDs, unaligned_sessions);
electrode_list(is_missing, :) = [];

over_256 = electrode_list.channel_number > 256;
electrode_list(over_256, :) = [];

end