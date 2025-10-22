%%% This function will take a list of electrodes, stimulation events,
%%% classifier parameter combination, and stimulation parameter search configurations;
%%% to perform classification of events flanking stimulation delivery.
%%% Returns probabilities in edited input events.

function solved_events = n01_perform_peristimulus_classifications(electrode_list, events, combination, configurations)

%%% Set parameters to classify events in the same manner as Elemem
buffer_duration = 500;
frequencies = [3, 7, 17, 37, 79, 161]; %%% Prime numbers to avoid harmonic stuff
morlet_width = 5;
n_normalization_events = 25;

%%% Get configuration parameters
pre_stim_classification_duration  = configurations.pre_stim_classification_duration;
post_stim_classification_duration = configurations.post_stim_classification_duration;
stim_duration                     = configurations.stim_duration;
post_stim_lockout                 = configurations.post_stim_lockout;

%%% Get classifier coefficients and intercept
classifier_results = combination.classifier_results{:};
coefficients       = classifier_results.coefficients;
intercept          = classifier_results.intercept;

%%% Get offsets to add to stimulation event times for classification windows
pre_stim_offset = -1 * pre_stim_classification_duration;
post_stim_offset = stim_duration + post_stim_lockout;

%%% Get features of events before and after stimulation
pre_stim_features = n00_get_features(electrode_list, events, pre_stim_classification_duration, pre_stim_offset, buffer_duration, frequencies, morlet_width, n_normalization_events);
post_stim_features = n00_get_features(electrode_list, events, post_stim_classification_duration, post_stim_offset, buffer_duration, frequencies, morlet_width, n_normalization_events);

%%% Use features to get classification probabilities
pre_stim_results = n00_solve_logistic_regression(pre_stim_features, coefficients, intercept);
post_stim_results = n00_solve_logistic_regression(post_stim_features, coefficients, intercept);

%%% Place results in events table
solved_events = events;
solved_events.pre_stim_results = pre_stim_results;
solved_events.post_stim_results = post_stim_results;
solved_events.probability_change = post_stim_results - pre_stim_results;

end