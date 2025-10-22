function n00_AR_behavioral_analysis_single(plots_directory, all_events, analysis_info, analysis_parameters, analysis_idx)

%%% Get analysis parameters
general_filters = analysis_parameters.general_filters{:};
n_groups        = analysis_parameters.n_groups;
group_labels    = analysis_parameters.group_labels{:};
group_filters   = analysis_parameters.group_filters{:};
has_condition   = analysis_parameters.has_condition;
condition       = analysis_parameters.condition;
outcomes        = analysis_parameters.outcomes{:};
n_outcomes      = analysis_parameters.n_outcomes;

%%% Get analysis info
random_effect_hierarchy        = analysis_info.random_effect_hierarchy;
random_effect_level_selections = analysis_info.random_effect_level_selections;
random_effect_groupings        = analysis_info.random_effect_groupings;
lme_levels                     = analysis_info.lme_levels;
correlation_levels             = analysis_info.correlation_levels;
boxplot_levels                 = analysis_info.boxplot_levels;

%%% Get color maps
color_maps = get_behavioral_color_maps();
behavior_correlation_color_map = color_maps.color_map{4};
time_correlation_color_map = color_maps.color_map{5};

%%% Filter for events included in these analyses
if ~isempty(general_filters)
    analysis_events = all_events(all(all_events{:, general_filters}), :);
else
    analysis_events = all_events;
end

%%% Add condition column for corresponding condition
if has_condition
    analysis_events.condition = analysis_events{:, condition};
else
    analysis_events.condition = true(height(analysis_events), 1);
end

%%% Make combinations of group and outcome indices to loop through analyses
[Ax, Bx] = ndgrid(1:n_outcomes, 1:n_groups);
outcome_indices = Ax(:);
group_indices   = Bx(:);

n_distributions = n_outcomes * n_groups

%%% Initialize cell matrices for distributions, for LME tables, and correlation arrays
cell_matrix = cell(n_outcomes, n_groups * (has_condition + 1));
behavior_correlation_arrays = cell_matrix;
time_correlation_arrays = cell_matrix; 
distributions = cell_matrix;
lme_tables = cell(n_outcomes, n_groups);

%%% Loop through combinations to get distributions, tables, and arrays for each outcome and group combination
for idx = 1:n_distributions
    
    outcome_index = outcome_indices(idx);
    
    outcome           = outcomes{outcome_index};
    
    boxplot_level     = boxplot_levels{outcome_index};
    lme_level         = lme_levels{outcome_index};
    correlation_level = lme_levels{outcome_index};
    
    lme_columns = [random_effect_hierarchy(1: find(strcmp(random_effect_hierarchy, lme_level)), {'condition'}];
    
    group_index  = group_indices(idx);
    
    group_filters = group_filters{group_index};
    if length(outcome) == 2
        group_filters = [group_filters, 'outcome_responded'];
        outcome = outcome{2};
    end
    
    group_mask = all(analysis_events{:, group_filters});
    group_events = analysis_events(group_mask, :);
    group_events.outcome = group_events(:, sprintf('outcome_%s', outcome));
    
    lme_tables{outcome_index, group_index} = group_summary(group_events, lme_columns, "mean", 'outcome');
    
    %%% Assuming there is a measurement for every group at each level
    if has_condition
    
        group_control_events = group_events(~group_events.condition, :);
        group_condition_events = group_events(group_events.condition, :);        
        
        distributions{outcome_index, (2 * group_index) - 1} = groupsummary(group_control_events, boxplot_level, "mean", 'outcome').mean_outcome;
        distributions{outcome_index, 2 * group_index} = groupsummary(group_condition_events, boxplot_level, "mean", 'outcome').mean_outcome;
        
        behavior_correlation_arrays{outcome_index, (2 * group_index) - 1} = groupsummary(group_control_events, correlation_level, "mean", 'outcome').mean_outcome;
        behavior_correlation_arrays{outcome_index, 2 * group_index} = groupsummary(group_condition_events, correlation_level, "mean", 'outcome').mean_outcome;
        
        time_correlation_arrays{outcome_index, (2 * group_index) - 1} = groupsummary(group_control_events, correlation_level, "mean", 'outcome_response_time').mean_outcome;
        time_correlation_arrays{outcome_index, 2 * group_index} = groupsummary(group_condition_events, correlation_level, "mean", 'outcome_response_time').mean_outcome;
        
    else
        distributions{outcome_index, group_index} = groupsummary(group_events, boxplot_level, "mean", 'óutcome').mean_outcome;
        behavior_correlation_arrays{outcome_index, group_index} = groupsummary(group_events, correlation_level, "mean", 'óutcome').mean_outcome;
        time_correlation_arrays{outcome_index, group_index} = groupsummary(group_events, correlation_level, "mean", 'óutcome_response_time').mean_outcome;
    end

end

%%% Make combinations of group and outcome indices to loop through analyses
[Ax, Bx, Cx] = ndgrid(1:n_outcomes, 1:n_groups, 1:n_groups);
outcome_indices = Ax(:);
group1_indices  = Bx(:);
group2_indices  = Cx(:);

n_combinations = n_outcomes * (n_groups^2);

%%% Initialize cell arrays with matrices to hold color map colors for plotting grids with results
color_grid                 = zeros(n_groups, n_groups, 3);
effect_grids               = repmat({color_grid}, n_outcomes, 1);
behavior_correlation_grids = repmat({color_grid}, n_outcomes, 1);
time_correlation_grids     = repmat({color_grid}, n_outcomes, 1);

%%% Loop through analysis combinations and perform analyses
for idx = 1:n_combinations
    
    outcome_index = outcome_indices(idx);
    outcome = outcomes{outcome_index};
        
    group1_index  = group1_indices(idx);
    group2_index  = group2_indices(idx);
    
    group1_lme_events = lme_tables{outcome_index, group1_index};
    group1_lme_events.group = true(height(group1_lme_events, 1);
    group2_lme_events = lme_tables{outcome_index, group2_index};
    group2_lme_events.group = false(height(group2_lme_events, 1);
    
    lme_events = [group1_lme_events; group2_lme_events];
    lme_level = lme_levels{outcome_index};
    lme_categorical_columns = random_effect_hierarchy(1: find(strcmp(random_effect_hierarchy, lme_level));
    
    lme_events(:, lme_categorical_columns) = varfun(@categorical, lme_events(:, lme_categorical_columns));
            
    if group1_index > group2_index 
    
        lme_formula = 'mean_outcome ~ condition*group';
        lme_color_map = color_maps.color_map{3};
        statistics_index = 4;
        skip_analysis = ~has_condition;
        
        if has_condition
            behavior_correlation_array1 = behavior_correlation_arrays{outcome_index, group1_index * 2};
            behavior_correlation_array2 = behavior_correlation_arrays{outcome_index, group2_index * 2};
            time_correlation_array1 = behavior_correlation_arrays{outcome_index, group1_index * 2};
            time_correlation_array2 = time_correlation_arrays{outcome_index, group2_index * 2};
        end        
        
    elseif group1_index == group2_index
    
        lme_formula = 'mean_outcome ~ condition';
        lme_color_map = color_maps.color_map{2};
        statistics_index = 2;
        skip_analysis = ~has_condition;
        
        if has_condition
            behavior_correlation_array1 = behavior_correlation_arrays{outcome_index, (group1_index * 2) - 1};
            behavior_correlation_array2 = behavior_correlation_arrays{outcome_index, group2_index * 2};
            time_correlation_array1 = behavior_correlation_arrays{outcome_index, group1_index * 2};
            time_correlation_array2 = time_correlation_arrays{outcome_index, (group2_index * 2) - 1};
        end
               
    else
    
        lme_formula = 'mean_outcome ~ group';
        lme_color_map = color_maps.color_map{1};
        statistics_index = 2;
        skip_analysis = false;
        
        if has_condition
            behavior_correlation_array1 = behavior_correlation_arrays{outcome_index, (group1_index * 2) - 1};
            behavior_correlation_array2 = behavior_correlation_arrays{outcome_index, (group2_index * 2) - 1};
            time_correlation_array1 = behavior_correlation_arrays{outcome_index, (group1_index * 2) - 1};
            time_correlation_array2 = time_correlation_arrays{outcome_index, (group2_index * 2) - 1};
        else
            behavior_correlation_array1 = behavior_correlation_arrays{outcome_index, group1_index};
            behavior_correlation_array2 = behavior_correlation_arrays{outcome_index, group2_index};
            time_correlation_array1 = behavior_correlation_arrays{outcome_index, group1_index};
            time_correlation_array2 = time_correlation_arrays{outcome_index, group2_index};
        end
                 
    end
        
    switch lme_level
        case 'subject_ID'
            random_effects_terms = ' + (1|subject_ID)';
            
        case 'session_ID'
            random_effects_terms = ' + (1|subject_ID) + (1|session_ID) + (1|subject_ID:session_ID)';
            
        case {'block_ID', 'event_ID'}
            random_effects_terms = ' + (1|subject_ID) + (1|session_ID) + (1|block_ID) + (1|subject_ID:session_ID) + (1|session_ID:block_ID)';
                         
    end
    
    if ~skip_analysis
    
        lme_formula = [lme_formula, random_effects_terms];
        lme_model = (lme_events, lme_formula);
        t_statistic = lme_model.Coefficients.tStat(statistics_index);
        
        if t_statistic < -3
            t_statistic = -2.999;
        elseif t_statistic > 3
            t_statistic = 3;
        end
        
        color_map_index = floor((t_statistic + 3) * 1000);
        effect_grids{outcome_index}(group1_index, group2_index, :) = lme_color_map(color_map_index, :);
        
        behavior_rho = corr(behavior_correlation_array1, behavior_correlation_array2);
        behavior_R2 = behavior_rho^2;
        
        if behavior_R2 < 0.0002
            behavior_R2 = 0.0002;
        end
        
        color_map_index = floor(behavior_R2 * 6000);
        behavior_correlation_grids{outcome_index}(group1_index, group2_index, :) = behavior_correlation_color_map(color_map_index, :);
        
        time_rho = corr(time_correlation_array1, time_correlation_array2);
        time_R2 = time_rho^2;
        
        if time_R2 < 0.0002
            time_R2 = 0.0002;
        end
        
        color_map_index = floor(time_R2 * 6000);
        time_correlation_grids{outcome_index}(group1_index, group2_index, :) = time_correlation_color_map(color_map_index, :);
        
    end
        
end

%%% Gather results in struct and save
results = struct;
results.distributions              = distributions;
results.effect_grids               = effect_grids;
results.behavior_correlation_grids = behavior_correlation_grids;
results.time_correlation_grids     = time_correlation_grids;

save(results_file, 'results');

%%% Plot results
plot_behavioral_analysis(plots_directory, analysis_parameters, results, analysis_idx);

end