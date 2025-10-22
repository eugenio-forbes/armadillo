%%% This function processes stimulation parameter search experiment events.
%%% Adjusts time of stimulation delivery based on client-server communications and alignment results.

function stimulation_events = process_stimulation_events(session_info, events_file, ...
    communications_file, parameters_used_file, recording_list, recording_system, alignment_info)

has_events         = session_info.has_events;
has_communications = session_info.has_communications;

%%% Initialize empty output
stimulation_events = [];

%%% Recording info
n_recordings = height(recording_list);
file_stems = recording_list.file_stem;

%%% Get actual recording starts and end times relative to the start of the first recording
recording_starts = zeros(n_recordings, 1);
recording_ends = zeros(n_recordings, 1);
time_differences = zeros(n_recordings, 1);
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

%%% Process events
if has_communications && isfile(communications_file)
    communications = read_communications(communications_file);
end

if has_events && isfile(events_file)
    
    stimulation_events = read_events(events_file);
    stimulation_events.mstime = stimulation_events.time * 1000;
    
elseif has_communications && isfile(communications_files)

    stimulation_events = n00_get_events_from_communications(subject, session, communications);

end

%%% Adjust times and offsets
if ~isempty(stimulation_events)

    n_events = height(stimulation_events);
    eegfile = cell(n_events, 1);
    eegoffset = zeros(n_events, 1);
    
    %%% First adds time difference based on communications files, then adjusts computer time based on alignment
    if has_communications && isfile(communications_file)
        stimulation_events = adjust_stimulation_times(stimulation_events, communications, parameters_used_file);
    end
    
    [~, stimulation_events.mstime] = adjust_computer_time(stimulation_events.mstime, alignment_info);
    
    for idx = 1:n_recordings
        event_indices = stimulation_events.mstime > recording_starts(idx) & stimulation_events.mstime < recording_ends(idx);
        n_matches = sum(event_indices);
        eegfile(event_indices) = repelem(file_stems(idx), n_matches, 1);
        eegoffset(event_indices) = stimulation_events.mstime(event_indices) - recording_starts(idx);
    end
    
    stimulation_events.eegfile = eegfile;
    stimulation_events.eegoffset = eegoffset;
    
end

end