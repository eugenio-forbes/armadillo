%%% This function takes non-stimulation events generated and clinician assessments.
%%% Based on timing of clinician positive scale assessment,
%%% it adds scale scores to events. Returns edited events.

function events = add_clinician_scale(events, clinician_scale)

%%% Timing of clinician assessments in minutes and milliseconds following injection administration
post_injection_times = [10, 20, 30, 45, 60]; % minutes
post_injection_times_ms = post_injection_times * 60000; % milliseconds

n_post = length(post_injection_times);

injection_index = find(events.injection_administered, 1, 'first');
min_injection_time = events.mstime(injection_index);
n_injectionless = injection_index - 1;

%%% Add clinician assessment made prior to injection administration to injectionless events.
if n_injectionless > 0
    events.clinician_scale(1:n_injectionless) = clinician_scale.post_0m;
end

previous_time = min_injection_time;
current_time = min_injection_time + post_injection_times_ms(1);

%%% Add clinician scale scores to corresponding events post injection based on timing
for idx = 1 : n_post

    this_clinician_scale = clinician_scale.(sprintf('post_%dm', post_injection_times(idx)));
    
    event_indices = (events.mstime >= previous_time) & (events.mstime <= current_time);
    n_events = sum(event_indices);
    
    events.clinician_scale(event_indices) = repmat(this_clinician_scale, n_events, 1);
    
    previous_time = min_injection_time + post_injection_times_ms(idx);
    if idx < n_post
       current_time = min_injection_time + post_injection_times_ms(idx + 1);
    end
    
end

end