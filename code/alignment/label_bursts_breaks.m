%%% This function will take events and recording pulse times.
%%% Based on the elapsed time between them, it will label them
%%% and plot them into three different categories:
%%% Burst pulses: short time interval between them
%%% Regular pulses: regular time interval between them
%%% Breaks: longer than expected time interval between them
%%% Returns struct with information about pulse bursts and breaks
%%% Plots two subplots comparing pulse labeling between events and recording.

function pulse_info = label_bursts_breaks(plot_file, events_pulses, recording_pulses, recording_starts, recording_ends, time_differences, inter_burst_time, do_plot)

n_recordings = length(recording_starts);
n_pulses_events = length(events_pulses);
n_pulses_recording = length(recording_pulses);

pulse_info = struct;

%%% Information about bursts
[diff_burst_events, n_bursts_events, burst_n_pulses_events, burst_starts_events, burst_ends_events] = find_sync_pulse_bursts(events_pulses, inter_burst_time);
[diff_burst_recording, n_bursts_recording, burst_n_pulses_recording, burst_starts_recording, burst_ends_recording] = find_sync_pulse_bursts(recording_pulses, inter_burst_time);

pulse_info.diff_burst_events        = diff_burst_events;
pulse_info.n_bursts_events          = n_bursts_events;
pulse_info.burst_n_pulses_events    = burst_n_pulses_events;
pulse_info.burst_starts_events      = burst_starts_events;
pulse_info.burst_ends_events        = burst_ends_events;
pulse_info.diff_burst_recording     = diff_burst_recording;
pulse_info.n_bursts_recording       = n_bursts_recording;
pulse_info.burst_n_pulses_recording = burst_n_pulses_recording;
pulse_info.burst_starts_recording   = burst_starts_recording;
pulse_info.burst_ends_recording     = burst_ends_recording;

%%% Information about breaks
[diff_break_events, n_breaks_events, break_starts_events, break_ends_events] = find_sync_pulse_breaks(events_pulses);
[diff_break_recording, n_breaks_recording, break_starts_recording, break_ends_recording] = find_sync_pulse_breaks(recording_pulses);

pulse_info.diff_break_events      = diff_break_events;
pulse_info.n_breaks_events        = n_breaks_events;
pulse_info.break_starts_events    = break_starts_events;
pulse_info.break_ends_events      = break_ends_events;
pulse_info.diff_break_recording   = diff_break_recording;
pulse_info.n_breaks_recording     = n_breaks_recording;
pulse_info.break_starts_recording = break_starts_recording;
pulse_info.break_ends_recording   = break_ends_recording;

%%% Use information about bursts and breaks to identify blocks of pulses in
%%% events and recording. There shouldn't be any breaks in events pulses,
%%% but still handling just in case there is a missing pulse/clock shift that would introduce a break.

if n_breaks_events > 0 && ~isempty(break_ends_events)

    block_starts_events = sort(unique([1; (break_ends_events + 1)]));
    block_ends_events = sort(unique([break_starts_events; n_pulses_events]));
    
elseif n_bursts_events > 1 && ~isempty(burst_ends_events)

    block_starts_events = sort(unique([1; (burst_ends_events + 1)]));
    block_ends_events = sort(unique([burst_ends_events; n_pulses_events]));
    
else

    block_starts_events = 1;
    block_ends_events = n_pulses_events;
    
end

n_blocks_events = length(block_starts_events);

%%% Get timespans of events pulse blocks for matching.
block_timespans_events = zeros(n_blocks_events, 1);

for idx = 1:n_blocks_events
    block_timespans_events(idx) = events_pulses(block_ends_events(idx)) - events_pulses(block_starts_events(idx));
end

%%% Handling of recording pulse breaks caused by automatic splitting of recording
if n_breaks_recording > 0 && n_recordings > 1

    split_durations = time_differences(2:end) - (recording_ends(1:end-1) - recording_starts(1:end-1) + min_pulse_start);
    
    split_times = recording_ends(1:end-1);
    
    bad_splits = split_durations > 0;
    n_bad_splits = sum(bad_splits);
    
    if n_bad_splits > 0
    
        break_start_times = recording_pulses(break_starts_recording);
        bad_split_times = split_times(bad_splits);
        excluded_breaks = false(n_breaks_recording, 1);
        
        for idx = 1:n_bad_splits
        
            break_differences = break_start_times - bad_split_times(idx);
            
            close_differences = abs(break_differences) < 8000;
        
            if any(close_differences)
                excluded_breaks(close_differences) = true;
            end
        
        end
        
        if any(excluded_breaks)
            n_excluded_breaks = sum(excluded_breaks);
            break_starts_recording(excluded_breaks) = [];
            break_ends_recording(excluded_breaks) = [];
            n_breaks_recording = n_breaks_recording - n_excluded_breaks;
        end
        
    end
    
end

if n_breaks_recording > 0 && ~isempty(break_ends_recording)

    block_starts_recording = sort(unique([1; (break_ends_recording + 1)]));
    block_ends_recording = sort(unique([break_starts_recording; n_pulses_recording]));

elseif n_bursts_recording > 1 && ~isempty(burst_ends_recording)

    block_starts_recording = sort(unique([1; (burst_ends_recording + 1)]));
    block_ends_recording = sort(unique([burst_ends_recording; n_pulses_recording]));

else

    block_starts_recording = 1;
    block_ends_recording = n_pulses_recording;

end

%%% Get timespans of recording pulse blocks for matching
n_blocks_recording = length(block_starts_recording);

block_timespans_recording = zeros(n_blocks_recording, 1);

for idx = 1:n_blocks_recording
    block_timespans_recording = recording_pulses(block_ends_recording(idx)) - recording_pulses(block_starts_recording(idx));
end

%%% Information about blocks
pulse_info.n_blocks_events           = n_blocks_events;
pulse_info.block_starts_events       = block_starts_events;
pulse_info.block_ends_events         = block_ends_events;
pulse_info.block_timespans_events    = block_timespans_events;
pulse_info.n_blocks_recording        = n_blocks_recording;
pulse_info.block_starts_recording    = block_starts_recording;
pulse_info.block_ends_recording      = block_ends_recording;
pulse_info.block_timespans_recording = block_timespans_recording;

%%% Plotting with labeling of breaks and blocks
if do_plot

    figure_width = 640;
    figure_height = 360;

    common_limits = [min(events_pulses(1), recording_pulses(1)), max(events_pulses(end), recording_pulses(end))];

    red = [240, 60, 15] / 255;
    green = [180, 240, 60] / 255;
    blue = [60, 140, 240] / 255;

    figure('Units', 'pixels', 'Position', [0, 0, figure_width, figure_height], 'Visible', 'off')
    
    %%% First subplot
    subplot(1, 2, 1)
    
    hold on
    
    scatter(events_pulses(~diff_burst_events), events_pulses(~diff_burst_events), [], repmat(blue, sum(~diff_burst_events), 1), 'o');
    
    if n_bursts_events > 0
        scatter(events_pulses(diff_burst_events), events_pulses(diff_burst_events), [], repmat(green, sum(diff_burst_events), 1), 'o', 'filled');
    end
    
    if n_breaks_events > 0
        scatter(events_pulses(diff_break_events), events_pulses(diff_break_events), [], repmat(red, sum(diff_break_events), 1), 'o', 'filled');
    end
    
    xlim(common_limits); xticks([]); xticklabels([]);
    ylim(common_limits); yticks([]); yticklabels([]);
    
    if n_recordings > 1
    
        for idx = 2:n_recordings
            plot([recording_ends(idx - 1), recording_ends(idx - 1)], common_limits, '--k')
            plot([recording_starts(idx), recording_starts(idx)], common_limits, '--k')
        end
        
    end
    
    hold off
    
    title('Events')
    
    %%% Second subplot
    subplot(1, 2, 2)
    
    hold on
    
    scatter(recording_pulses(~diff_burst_recording), recording_pulses(~diff_burst_recording), [], repmat(blue, sum(~diff_burst_recording), 1), 'o');
    
    if n_bursts_recording > 0
        scatter(recording_pulses(diff_burst_recording), recording_pulses(diff_burst_recording), [], repmat(green, sum(diff_burst_recording), 1), 'o', 'filled');
    end
    
    if n_breaks_recording > 0
        scatter(recording_pulses(diff_break_recording), recording_pulses(diff_break_recording), [], repmat(red, sum(diff_break_recording), 1), 'o', 'filled');
    end
    
    xlim(common_limits); xticks([]); xticklabels([]);
    ylim(common_limits); yticks([]); yticklabels([]);
    
    if n_recordings > 1
    
        for idx = 2:n_recordings
            plot([recording_ends(idx - 1), recording_ends(idx - 1)], common_limits, '--k')
            plot([recording_starts(idx), recording_starts(idx)], common_limits, '--k')
        end
        
    end
    
    hold off
    
    title('Recording')
    
    print(plot_file, '-dpng')
    
    close all

end

end