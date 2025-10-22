function CPS_results = n01_get_CPS_results(events)

is_sham = events.is_sham;
is_stim = events.is_stim;

unique_amplitudes = unique(events.amplitude);
unique_locations = unique(events.lead1);
n_amplitudes = length(unique_amplitudes);
n_locations = length(unique_locations);

CPS_results = struct;
CPS_results.amplitudes = unique_amplitudes;
CPS_results.locations = unique_locations;

zero_matrix = zeros(n_amplitudes, n_locations);

pre_sham      = zero_matrix;
pre_stim      = zero_matrix;
post_sham     = zero_matrix;
post_stim     = zero_matrix;
change_sham   = zero_matrix;
change_stim   = zero_matrix;
pre_tstats    = zero_matrix;
post_tstats   = zero_matrix;
change_tstats = zero_matrix;
pre_pval      = zero_matrix;
post_pval     = zero_matrix;
change_pval   = zero_matrix;

for idx = 1:n_amplitudes

    this_amp = unique_amplitudes(idx);
    
    for jdx = 1:n_locations
        
        this_loc = unique_locations(jdx);
        corresponding = events.amplitude == this_amp & strcmp(events.lead1, this_loc);
        
        if sum(corresponding > 0)
        
            sham_events = events(corresponding & is_sham, :);
            stim_events = events(corresponding & is_stim, :);
            
            pre_sham(idx, jdx) = mean(sham_events.prestim_result);
            pre_stim(idx, jdx) = mean(stim_events.prestim_result);
            post_sham(idx, jdx) = mean(sham_events.poststim_result);
            post_stim(idx, jdx) = mean(stim_events.poststim_result);
            change_sham(idx, jdx) = mean(sham_events.probability_change);
            change_stim(idx, jdx) = mean(stim_events.probability_change);
            
            [~, pre_pval(idx, jdx), ~, test1] = ttest2(stim_events.prestim_result, sham_events.prestim_result);
            [~, post_pval(idx, jdx), ~, test2] = ttest2(stim_events.poststim_result, sham_events.poststim_result);
            [~, change_pval(idx, jdx), ~, test3] = ttest2(stim_events.probability_change, sham_events.probability_change);
            
            pre_tstats(idx, jdx) = test1.tstat;
            post_tstats(idx, jdx) = test2.tstat;
            change_tstats(idx, jdx) = test3.tstat;
            
        end
        
    end
    
end

CPS_results.pre_sham      = pre_sham;
CPS_results.pre_stim      = pre_stim;
CPS_results.post_sham     = post_sham;
CPS_results.post_stim     = post_stim;
CPS_results.change_sham   = change_sham;
CPS_results.change_stim   = change_stim;
CPS_results.pre_tstats    = pre_tstats;
CPS_results.post_tstats   = post_tstats;
CPS_results.change_tstats = change_tstats;
CPS_results.pre_pval      = pre_pval;
CPS_results.post_pval     = post_pval;
CPS_results.change_pval   = change_pval;

end