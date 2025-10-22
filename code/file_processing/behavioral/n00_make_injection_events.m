%%% This function takes a recording list of a given recording system 
%%% from an experimental session that had injection administration.
%%% Based on the timespan of the recording and some time window restrictions,
%%% it generates as many events that have the same configurations as
%%% the stimulation parameter search, for training the classifier.
%%% Events that occur after injection end time are marked as having injection.
%%% Function returns events table.

function events = n00_make_injection_events(session_info, injection_start_time, injection_end_time, recording_list, recording_system, configurations)

%%% Initialize empty output
events = [];

%%% Get session info
subject    = session_info.subject{:};
subject_ID = session_info.subject_ID;
task       = session_info.task{:};
session    = session_info.session{:};
session_ID = session_info.session_ID;

%%% Important variables
min_offset = 120000;        %%% Starting to create events 2 minutes into the recording
peri_injection_cut = 60000; %%% Taking off one minute before and after the logged injection times to reduce movement artifact
max_n_events = 10000;       %%% 10000 should be plenty to initialize events assuming single session lasts at most 4-5 hours

%%% Processing the events as if the classifications would happen around a
%%% stimulus, because ultimately that is how classifications would be carried out
pre_stim_classification_duration  = configurations.pre_stim_classification_duration;
stim_duration                     = configurations.stim_duration;
post_stim_lockout                 = configurations.post_stim_lockout;
post_stim_classification_duration = configurations.post_stim_classification_duration;
inter_trial_interval              = configurations.inter_trial_interval;
inter_trial_jitter                = configurations.inter_trial_jitter;

trial_duration = pre_stim_classification_duration + stim_duration + post_stim_lockout + post_stim_classification_duration;
total_trial_duration = trial_duration + inter_trial_interval;

%%% Recording info
n_recordings = height(recording_list);
file_stems = recording_list.file_stem;

%%% Get actual recording starts and end times relative to the start of the first recording
recording_starts  = zeros(n_recordings, 1);
recording_ends    = zeros(n_recordings, 1);
time_differences  = zeros(n_recordings, 1);
recording_ends(1) = recording_list.n_samples(1);

if n_recordings > 1

    for idx = 2:n_recordings

        switch recording_system
            case 'nihon_kohden'
                time_differences(idx) = milliseconds(recording_list.start_time{idx} - recording_list.start_time{1});

            case 'blackrock'
                time_differences(idx) = sum(recording_list.n_samples(1:idx - 1));
        end

        recording_starts(idx) = time_differences(idx);
        recording_ends(idx) = recording_ends(idx) + time_differences(idx);

    end

end

event_count = 0;
mstime = zeros(max_n_events, 1);
max_event_time = max(recording_ends) - min_offset; %%% Similarly cutting out two minutes before the recording ends

current_time = min_offset;
time_cut = injection_start_time - peri_injection_cut;
time_remaining = time_cut - current_time;

while event_count < max_n_events && time_remaining > total_trial_duration

    first_event_time = current_time;
    second_event_time = current_time + pre_stim_classification_duration + stim_duration + post_stim_lockout;
    
    this_inter_trial_duration = inter_trial_interval + (inter_trial_jitter * randn);
    this_trial_duration = trial_duration + this_inter_trial_duration;
    
    potential_end_time = current_time + this_trial_duration;

    if potential_end_time < time_cut
        mstime(event_count + 1) = first_event_time;
        mstime(event_count + 2) = second_event_time;
        event_count = event_count + 2;
    end

    current_time = current_time + this_trial_duration;
    time_remaining = time_cut - current_time;
    
end

current_time = injection_end_time + peri_injection_cut;
time_cut = max_event_time;
time_remaining = time_cut - current_time;

while event_count < max_n_events && time_remaining > total_trial_duration

    first_event_time = current_time;
    second_event_time = current_time + pre_stim_classification_duration + stim_duration + post_stim_lockout;
    
    this_inter_trial_duration = inter_trial_interval + (inter_trial_jitter * randn);
    this_trial_duration = trial_duration + this_inter_trial_duration;
    
    potential_end_time = current_time + this_trial_duration;
    
    if potential_end_time < time_cut
        mstime(event_count + 1) = first_event_time;
        mstime(event_count + 2) = second_event_time;
        event_count = event_count + 2;
    end
    
    current_time = potential_end_time;
    time_remaining = time_cut - current_time;
    
end

if event_count > 0
    
    mstime = mstime(1:event_count);
    
    if n_recordings > 1
    
        bad_times = false(event_count, 1);
        
        for idx = 1:n_recordings-1
            bad_time_indices = mstime > recording_ends(idx) & mstime < recording_starts(idx+1);
            bad_times(bad_time_indices) = true;
        end
        
        mstime(bad_times) = [];
        n_bad_times = sum(bad_times);
        event_count = event_count - n_bad_times;
        
    end
    
    cell_array = cell(event_count, 1);
    zero_array = zeros(event_count, 1);
    false_array = false(event_count, 1);
    
    %%% All variables that would go into events columns. Some initialized to be set later.
    subject                = repelem({subject}, event_count, 1);
    subject_ID             = repmat(subject_ID, event_count, 1);
    task                   = repelem({task}, event_count, 1);
    session                = repelem({session}, event_count, 1);
    session_ID             = repmat(session_ID, event_count, 1);
    injectionless          = mstime < injection_start_time;
    is_even                = false_array;
    is_ketamine            = mstime > injection_end_time;
    injection_administered = mstime > injection_end_time;
    psych_rating           = zero_array;
    psych_score            = zero_array;
    clinician_scale        = zero_array;
    eegfile                = cell_array;
    eegoffset              = zero_array;

    for idx = 1:n_recordings
        event_indices = mstime > recording_starts(idx) & mstime < recording_ends(idx);
        n_matches = sum(event_indices);
        eegfile(event_indices) = repelem(file_stems(idx), n_matches, 1);
        eegoffset(event_indices) = floor(mstime(event_indices) - recording_starts(idx));
    end
    
    events = table(subject, subject_ID, task, session, session_ID, injectionless, is_even, is_ketamine, ...
        injection_administered, psych_rating, psych_score, clinician_scale, mstime, eegfile, eegoffset);

end

end