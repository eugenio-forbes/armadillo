%%% This function takes an events table for which peristimulus classifications
%%% have been performed, and for each combination of stimulation parameters,
%%% gets t-statistics of classification probability changes relative to SHAM events.
%%% arranges results in matrix for plotting, and returns results in struct.

function PS_results = n02_get_PS_results(events)

is_sham = strcmp(events.event_type, 'SHAM');
is_stim = strcmp(events.event_type, 'STIMULATION_CONFIGURATION');

stim_events = events(is_stim, :);
sham_events = events(is_sham, :);

locations = stim_events.label;
amplitudes = stim_events.amplitude;
frequencies = stim_events.frequency;
pulse_widths = stim_events.pulse_width;

unique_locations = unique(locations);
unique_amplitudes = unique(amplitudes);
unique_frequencies = unique(frequencies);
unique_pulse_widths = unique(pulse_widths);

n_locations = length(unique_locations);
n_amplitudes = length(unique_amplitudes);
n_frequencies = length(unique_frequencies);
n_pulse_widths = length(unique_pulse_widths);

[Ax, Bx, Cx, Dx] = ndgrid(1:n_pulse_widths, 1:n_frequencies, 1:n_amplitudes, 1:n_locations);
combinations = table;
combinations.location = unique_locations(Dx(:));
combinations.amplitude = unique_amplitudes(Cx(:));
combinations.frequency = unique_frequencies(Bx(:));
combinations.pulse_width = unique_pulse_widths(Ax(:));

n_combinations = height(combinations);

pre_sham = mean(sham_events.pre_stim_results);
post_sham = mean(sham_events.post_stim_results);
change_sham = post_sham - pre_sham;

zero_array = zeros(n_combinations, 1);

pre_stim      = zero_array;
post_stim     = zero_array;
change_stim   = zero_array;
pre_tstats    = zero_array;
post_tstats   = zero_array;
change_tstats = zero_array;
pre_pval      = zero_array;
post_pval     = zero_array;
change_pval   = zero_array;

for idx = 1:n_combinations

    location    = combinations.location{idx};
    amplitude   = combinations.amplitude(idx);
    frequency   = combinations.frequency(idx);
    pulse_width = combinations.pulse_width(idx);

    location_match = strcmp(locations, location);
    amplitude_match = amplitudes == amplitude;
    frequency_match = frequencies == frequency;
    pulse_match = pulse_widths == pulse_width;
    corresponding = location_match & amplitude_match & frequency_match & pulse_match;

    corresponding_events = stim_events(corresponding, :);
    n_corresponding = height(corresponding_events);

    if n_corresponding > 0
        
        pre_stim(idx) = mean(corresponding_events.pre_stim_results);
        post_stim(idx) = mean(corresponding_events.post_stim_results);
        change_stim(idx) = mean(corresponding_events.probability_change);
        
        [~, pre_pval(idx), ~, test1] = ttest2(corresponding_events.pre_stim_results, sham_events.pre_stim_results);
        [~, post_pval(idx), ~, test2] = ttest2(corresponding_events.post_stim_results, sham_events.post_stim_results);
        [~, change_pval(idx), ~, test3] = ttest2(corresponding_events.probability_change, sham_events.probability_change);
        
        pre_tstats(idx) = test1.tstat;
        post_tstats(idx) = test2.tstat;
        change_tstats(idx) = test3.tstat;
    
    end
    
end

pre_stim      = reshape(pre_stim, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
post_stim     = reshape(post_stim, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
change_stim   = reshape(change_stim, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
pre_tstats    = reshape(pre_tstats, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
post_tstats   = reshape(post_tstats, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
change_tstats = reshape(change_tstats, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
pre_pval      = reshape(pre_pval, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
post_pval     = reshape(post_pval, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);
change_pval   = reshape(change_pval, n_locations, n_amplitudes, n_frequencies * n_pulse_widths);

max_results = zeros(n_locations, 1);

for idx = 1:n_locations
    max_results(idx) = max(change_tstats(idx, :, :), [], 'all');
end

[~, sorting_indices] = sort(max_results, 'descend');

if n_locations > 9
    best_indices = sorting_indices(1:10);
    n_plotted = 9;
else
    best_indices = sorting_indices;
    n_plotted = n_locations;
end

PS_results = struct;
PS_results.n_plotted     = n_plotted;
PS_results.locations     = locations(best_indices);
PS_results.amplitudes    = unique_amplitudes;
PS_results.frequencies   = unique_frequencies;
PS_results.pulse_widths  = unique_pulse_widths;
PS_results.pre_stim      = pre_stim;
PS_results.post_stim     = post_stim(best_indices, :, :);
PS_results.change_stim   = change_stim(best_indices, :, :);
PS_results.pre_tstats    = pre_tstats(best_indices, :, :);
PS_results.post_tstats   = post_tstats(best_indices, :, :);
PS_results.change_tstats = change_tstats(best_indices, :, :);
PS_results.pre_pval      = pre_pval(best_indices, :, :);
PS_results.post_pval     = post_pval(best_indices, :, :);
PS_results.change_pval   = change_pval(best_indices, :, :);

end