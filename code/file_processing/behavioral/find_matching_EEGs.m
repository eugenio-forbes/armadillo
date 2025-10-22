%%% This function will take a Nihon Kohden or Blackrock recording list table,
%%% a session's start time (based on date time in folder name), and events pulses
%%% to estimate recording and events time spans, and determine which recordings
%%% overlap with a session. Returns indices of recording list if matches are found.

function matching_indices = find_matching_EEGs(recording_list, session_info, events_pulses)

session = session_info.session;

%%% Estimate task computer end time based on range of pulses
session_start_time = datetime(session, 'InputFormat', 'yyyy-MM-dd_HH-mm-SS');

max_events_time = max(events_pulses.time);
min_events_time = min(events_pulses.time);

estimated_elapsed_time_seconds = seconds(ceil(max_events_time - min_events_time));
session_end_time = session_start_time + estimated_elapsed_time_seconds; 

%%% Calculate recording end times based on sampling rates and number of samples
recording_start_times    = vertcat(recording_list.start_time{:});
recording_n_samples      = recording_list.n_samples;
recording_sampling_rates = recording_list.sampling_rate;

recording_elapsed_times_seconds = seconds(ceil(recording_n_samples ./ recording_sampling_rates));
recording_end_times = recording_start_times + recording_elapsed_times_seconds;

%%% Find overlap between recording and session times
recording_start_within = recording_start_times > session_start_time & recording_start_times < session_end_time;
recording_end_within = recording_end_times > session_start_time & recording_end_times < session_end_time;
session_start_within = recording_start_times < session_start_time & recording_end_times > session_start_time;
session_end_within = recording_start_times < session_end_time & recording_end_times > session_end_time;

good_matches = recording_start_within | recording_end_within | session_start_within | session_end_within;

matching_indices = find(good_matches);

end