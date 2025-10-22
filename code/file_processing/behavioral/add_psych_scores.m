%%% This function takes non-stimulation events generated and
%%% psych scores made from experiment GUI.
%%% Psych scores are added to events based on timing. Returns edited events.

function events = add_psych_scores(events, psych_scores)

n_scores = height(psych_scores);
current_time = 0;

for idx = 1:n_scores

    this_score = psych_scores.score(idx);

    if idx < n_scores
        event_indices = events.mstime <= psych_scores.mstime(idx) & events.mstime > current_time;
    else
        event_indices = events.mstime > current_time;
    end

    n_events = sum(event_indices);

    if n_events > 0
        events.psych_score(event_indices) = repmat(this_score, n_events, 1);
    end

    current_time = psych_scores.mstime(idx);

end

end