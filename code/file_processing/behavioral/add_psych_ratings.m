%%% This function takes non-stimulation events generated and
%%% psych ratings made from experiment GUI.
%%% Psych ratings are added to events based on timing. Returns edited events.

function events = add_psych_ratings(events, psych_ratings)

n_ratings = height(psych_ratings);
current_time = 0;

for idx = 1:n_ratings

    this_rating = psych_ratings.rating(idx);

    if idx < n_ratings
        event_indices = events.mstime <= psych_ratings.mstime(idx) & events.mstime > current_time;
    else
        event_indices = events.mstime > current_time;
    end

    n_events = sum(event_indices);

    if n_events > 0
        events.psych_rating(event_indices) = repmat(this_rating, n_events, 1);
    end

    current_time = psych_ratings.mstime(idx);

end

end