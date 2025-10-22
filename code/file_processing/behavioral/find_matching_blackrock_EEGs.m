function matching_indices = find_matching_blackrock_EEGs(blackrock_list, session_info, pulses)

%%% Estimate task computer end time based on range of pulses
session_start_time = datetime(session, 'yyyy-MM-dd_HH-mm-SS');

max_pulse_time = max(pulses.time);
min_pulse_time = min(pulses.time);

estimated_elapsed_time_seconds = seconds(ceil(max_pulse_time - min_pulse_time));
session_end_time = session_start_time + estimated_elapsed_time_seconds; 

%%% Filter blackrock list
has_subject = contains(blackrock_list.subject, )

%%% Calculate blackrock recording end times based on sampling rates and number of samples
recording_start_times    = blackrock_list.start_time;
recording_n_samples      = blackrock_list.n_samples;
recording_sampling_rates = blackrock_list.sampling_rate;

recording_elapsed_times_seconds = seconds(ceil(recording_n_samples ./ recording_sampling_rates));
recording_end_times = recording_start_times + recording_elapsed_times_seconds;

recording_start_within = recording_start_times > session_start_time & recording_start_times < session_end_time;
recording_end_within = recording_end_times > session_start_time & recording_end_times < session_end_time;
session_start_within = recording_start_times < session_start_time & recording_end_times > session_start_time;
session_end_within = recording_start_times < session_end_time & recording_end_times > session_end_time;

good_matches = recording_start_within | recording_end_within | session_start_within | session_end_within;

matching_indices = find(good_matches);

end