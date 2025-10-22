function [all_events, analysis_parameters] = n00_get_analysis_parameters(events_info, analysis_info)

data_directory = analysis_info.data_directory;

%%% Load all events
all_events = n00_get_all_events(data_directory, events_info);

%%% Analysis Info
analysis_type = analysis_info.analysis_type; 

switch analysis_type
    case 'behavioral'
        analysis_parameters = get_behavioral_analysis_parameters(all_events(1, :), analysis_info);

    otherwise
        analysis_parameters = table;
end

end


function analysis_parameters = get_behavioral_analysis_parameters(event, analysis_info)     

%%% Get analysis info for selection of valid parameters
analysis_level_selections            = analysis_info.analysis_level_selections; 
condition_selections                 = analysis_info.condition_selections;
outcome_selections                   = analysis_info.outcome_selections;
outcome_groupings                    = analysis_info.outcome_groupings;
all_outcome_labels                   = analysis_info.outcome_labels;
task_phase_selections                = analysis_info.task_phase_selections;
task_phase_characteristic_selections = analysis_info.task_phase_characteristic_selections;
task_phase_characteristic_groupings  = analysis_info.task_phase_characteristic_groupings;
other_selections                     = analysis_info.other_selections;
other_characteristic_selections      = analysis_info.other_characteristic_selections;
other_characteristic_groupings       = analysis_info.other_characteristic_groupings;

%%% Get column names from event table row and filter out task computer time, recording file and offset
column_names = event.Properties.VariableNames;
column_names(contains(column_names, {'mstime', 'eegoffset', 'eegfile'})) = [];

%%% Different types of measurable outcomes (whether there was a response, whether response is correct, response timing)
all_outcomes = column_names(contains(column_names, 'outcome_'));
outcome_names = strrep(all_outcomes, 'outcome_', '');

is_binary = cellfun(@(x) islogical(event.(x)), all_outcomes);
is_numerical = ~is_binary;

binary_outcomes = cellfun(@(x) any(is_binary(contains(outcome_names, x))), all_outcomes);
numerical_outcomes = cellfun(@(x) any(is_numerical(contains(outcome_names, x))), all_outcomes);

%%% Random effects like subject, session, block, or event IDs
random_effects = column_names(contains(column_names, '_ID'));
random_effect_names = strrep(random_effects, '_ID', '');

%%% Whether a session includes a given experimental condition
conditions = column_names(contains(column_names, 'condition_'));
condition_names = strrep(conditions, 'condition_', '');

%%% Task phases
task_phases = column_names(contains(column_names, 'task_'));
task_phase_names = strrep(task_phases, 'task_', '');
n_task_phases = length(task_phases);

%%% Whether a trial has an experimental condition in a given task phase
experimental_conditions = column_names(contains(column_names, condition_names) & contains(column_names, task_phase_names));

%%% Column names include task phase and characteristic (e.g. encoding trials can be divided by answer, response, or combination of both)
task_phase_characteristics = cell(n_task_phases, 1);
task_phase_characteristic_types = cell(n_task_phases, 1);
task_phase_characteristic_type_names = cell(n_task_phases, 1);

for idx = 1:n_task_phases
    
    task_phase = task_phase_names{idx};
    
    characteristics = column_names(contains(column_names, task_phase));
    characteristics(contains(characteristics, [condition_names, outcome_names])) = [];
    characteristic_names = strrep(characteristics, [task_phase, '_'], '');
    characteristic_names = unique(regexprep(characteristic_names, '_[a-z]*$', ''));
    
    n_characteristics = length(characteristic_names);
    characteristic_types = cell(1, n_characteristics);
    characteristic_type_names = cell(1, n_characteristics);
    
    for jdx = 1:n_characteristics
        characteristic = characteristic_names{jdx};
        characteristic_types{jdx} = characteristics(contains(characteristics, characteristic));
        characteristic_type_names{jdx} = strrep(characteristic_types{jdx}, [characteristic, '_'], '');
    end
    
    task_phase_characteristics{idx} = characteristic_names;
    task_phase_characteristic_types{idx} = characteristic_types;
    task_phase_characteristic_type_names{idx} = characteristic_type_names;

end

%%% The column names that link encoding and retrieval trial data.
%%% For example, retrieval trials can be divided based on whether encoding answer was top or bottom. 
%%% Encoding trials can be divided on whether retrieval answer is intact, rearranged or new.
other_types = column_names(contains(column_names, '_'));
other_types(contains(other_types, [condition_names, task_phase_names, random_effect_names, outcome_names])) = [];
other_type_names = unique(regexprep(other_types, '_[a-z]*_[a-z]*$', ''));

n_other_types = length(other_type_names);

other_characteristics = cell(n_task_phases, 1);
other_characteristic_types = cell(n_task_phases, 1);
other_characteristic_type_names = cell(n_task_phases, 1);

for idx = 1:n_task_phases
    
    phase_characteristic_types = task_phase_characteristic_types{idx};
        
    characteristics = other_types(~contains(other_types, [phase_characteristic_types{:}]));
    characteristic_names = strrep(characteristics, other_type_names, '');
    characteristic_names = regexprep(characteristics, '^_', '');
    characteristic_names = unique(regexprep(characteristic_names, '_[a-z]*$', ''));
    
    n_characteristics = length(characteristic_names);
    characteristic_types = cell(1, n_characteristics);
    characteristic_type_names = cell(1, n_characteristics);
    
    for jdx = 1:n_characteristics
        characteristic = characteristic_names{jdx};
        characteristic_types{jdx} = characteristics(contains(characteristics, characteristic));
        characteristic_type_names{jdx} = strrep(characteristic_types{jdx}, [characteristic, '_'], '');
    end
    
    other_characteristics{idx} = characteristics;
    other_characteristic_types{idx} = characteristic_types;
    other_characteristic_type_names{idx} = characteristic_type_names;

end

n_conditions = length(conditions);
n_task_phases = length(task_phases);
n_task_phase_characteristic_groupings = length(task_phase_characteristic_groupings);
n_other_groupings = length(other_characteristic_groupings);

%%% Initialize empty output
analysis_parameters = [];

%%% Analyses comparing and correlating encoding and retrieval outcomes for every condition
if ismember('task_phase', analysis_level_selections)

    n_new_rows = n_conditions;
    
    cell_array  = cell(n_new_rows, 1);
    ones_array = ones(n_new_rows, 1);
    false_array = false(n_new_rows, 1);

    general_filters = cell_array;
    n_groups        = ones_array * 2;
    group_labels    = repmat({'E', 'R'}, n_new_rows, 1);
    group_filters   = repmat({task_phases(:)}, n_new_rows, 1);
    has_condition   = false_array;
    condition       = cell_array;
    outcomes        = repmat({all_outcomes}, n_new_rows, 1);
    outcome_labels  = repmat({all_outcome_labels}, n_new_rows, 1);
    n_outcomes      = ones_array * length(all_outcomes);
    bad_rows        = ~ismember(condition_names, condition_selections);

    for idx = 1:n_new_rows
        general_filters(idx) = conditions(idx);  
    end

    new_rows = table(general_filters, n_groups, group_labels, group_filters, has_condition, condition, outcomes, n_outcomes);
    new_rows(bad_rows, :) = [];
    analysis_parameters = [analysis_parameters; new_rows];

end

%%% Analyses comparing/correlating trial outcomes of a task phase based on characteristics
if ismember('characteristics', analysis_level_selections)
    
    [Ax, Bx, Cx] = ndgrid(1:n_conditions, 1:n_task_phases, 1:n_task_phase_characteristic_groupings);
    condition_indices = Ax(:);
    task_phase_indices = Bx(:);
    characteristic_indices = Cx(:);

    n_new_rows = n_conditions * n_task_phases * n_task_phase_characteristic_groupings;
    
    cell_array  = cell(n_new_rows, 1);
    zeros_array = zeros(n_new_rows, 1);
    false_array = false(n_new_rows, 1);
    
    general_filters = cell_array;
    n_groups        = zeros_array;
    group_labels    = cell_array;
    group_filters   = cell_array;
    has_condition   = false_array;
    condition       = cell_array;
    outcomes        = cell_array;
    outcome_labels  = cell_array;
    n_outcomes      = zeros_array;
    bad_rows        = false_array;
        
    for idx = 1:n_new_rows
    
        condition_index = condition_indices(idx);
        task_phase_index = task_phase_indices(idx);
        characteristic_index = characteristic_indices(idx);
        
        this_condition = conditions{condition_index};
        condition_name = condition_names{condition_index};
        
        task_phase = task_phases{task_phase_index};
        task_phase_name = task_phase_names{task_phase_index};
        
        this_task_phase_characteristics = task_phase_characteristics{task_phase_index};
        this_task_phase_characteristic_types = task_phase_characteristic_types{task_phase_index};
        this_task_phase_characteristic_type_names = task_phase_characteristic_type_names{task_phase_index};
        
        characteristic_selections = ismember(this_task_phase_characteristics, task_phase_characteristic_groupings{characteristic_index});
        
        this_task_phase_characteristic_types = this_task_phase_characteristic_types(characteristic_selections);
        this_task_phase_characteristic_type_names = this_task_phase_characteristic_type_names(characteristic_selections);
        n_characteristic_selections = sum(characteristic_selections);

        bad_rows(idx) = ~ismember(condition_name, condition_selections) | ~ismember(task_phase_name, task_phase_selections);
        
        if ~bad_rows(idx)
                        
            if any(contains(task_phase_characteristic_groupings{characteristic_index}, 'response'))
                general_filters{idx} = {this_condition, task_phase, 'outcome_responded_yes'};
                n_outcomes(idx) = 1;
                outcomes{idx} = {'press'};
                outcome_labels{idx} = {'response_time'};
            else
                general_filters{idx} = {this_condition, task_phase};
                n_outcomes(idx) = length(all_outcomes);
                outcomes{idx} = all_outcomes;
                outcome_labels{idx} = all_outcome_labels;
            end
            
            if ismember(condition_name, {'scopolamine', 'stimulation'})
                valid_condition = contains(experimental_conditions, condition_name) & contains(experimental_conditions, task_phase_name); 
                has_condition(idx) = any(valid_condition);
                if any(valid_condition)
                    condition{idx} = experimental_conditions(valid_condition);
                end
            end
            
            if n_characteristic_selections == 1
                n_groups(idx) = length(this_task_phase_characteristic_types{1});
                group_filters{idx} = this_task_phase_characteristic_types{1};
                group_labels{idx} = cellfun(@(x) upper(x(1)), this_task_phase_characteristic_types{1}, 'UniformOutput', false);
            else
                filters1 = this_task_phase_characteristic_types{1};
                filters2 = this_task_phase_characteristic_types{2};
                
                labels1 = cellfun(@(x) upper(x(1)), filters1, 'UniformOutput', false);
                labels2 = cellfun(@(x) upper(x(1)), filters2, 'UniformOutput', false);
                
                n_types1 = length(filters1);
                n_types2 = length(filters2);
                
                n_groups(idx) = n_types1 * n_types2;
                
                [Dx, Ex] = ndgrid(1:n_types1, 1:n_types2);
                
                filters1 = filters1(Dx(:));
                filters2 = filters2(Ex(:));
                
                labels1 = labels1(Dx(:));
                labels2 = labels2(Ex(:));
                
                this_filters = cell(n_groups(idx), 1);
                this_labels = cell(n_groups(idx), 1);
                
                for jdx = 1:n_groups(idx)
                    this_filters(jdx) = {filters1{jdx}, filters2{jdx}}; 
                    this_labels{jdx} = [labels1{jdx}, labels2{jdx}];
                end
                
                group_filters{idx} = this_filters;
                group_labels{idx} = this_labels;
                          
            end
        
        end
        
    end
    
    new_rows = table(general_filters, n_groups, group_labels, group_filters, has_condition, condition, outcomes, n_outcomes);
    new_rows(bad_rows, :) = [];
    if height(new_rows) == 0
        new_rows = [];
    end
    analysis_parameters = [analysis_parameters; new_rows];
    
end

if ismember('other_characteristics', analysis_level_selections)

    [Ax, Bx, Cx, Dx] = ndgrid(1:n_conditions, 1:n_task_phases, 1:n_task_phase_characteristic_groupings, 1:n_other_characteristic_groupings);
    condition_indices = Ax(:);
    task_phase_indices = Bx(:);
    characteristic_indices = Cx(:);
    other_indices = Dx(:);
    
    n_new_rows = n_conditions * n_task_phases * n_task_phase_characteristic_groupings * n_other_groupings;

    cell_array  = cell(n_new_rows, 1);
    zeros_array = zeros(n_new_rows, 1);
    false_array = false(n_new_rows, 1);

    general_filters = cell_array;
    n_groups        = zeros_array;
    group_labels    = cell_array;
    group_filters   = cell_array;
    has_condition   = false_array;
    condition       = cell_array;
    outcomes        = cell_array;
    outcome_labels  = cell_array;
    n_outcomes      = zeros_array;
    bad_rows        = false_array;
    
    for idx = 1:n_new_rows
        
        condition_index = condition_indices(idx);
        task_phase_index = task_phase_indices(idx);
        characteristic_index = characteristic_indices(idx);
        other_index = other_indices(idx);
        
        this_condition = conditions{condition_index};
        condition_name = condition_names{condition_index};
        
        task_phase = task_phases{task_phase_index};
        task_phase_name = task_phase_names{task_phase_index};
        
        this_task_phase_characteristics = task_phase_characteristics{task_phase_index};
        this_task_phase_characteristic_types = task_phase_characteristic_types{task_phase_index};
        this_task_phase_characteristic_type_names = task_phase_characteristic_type_names{task_phase_index};
        
        this_other_characteristics = other_characteristics{task_phase_index};
        this_other_characteristic_types = other_characteristic_types{task_phase_index};
        this_other_characteristic_type_names = other_characteristic_type_names{task_phase_index};
        
        characteristic_selections = ismember(this_task_phase_characteristics, task_phase_characteristic_groupings{characteristic_index});
        other_selections = ismember(this_other_characteristics, other_characteristic_groupings{other_index});
        
        this_task_phase_characteristic_types = this_task_phase_characteristic_types(characteristic_selections);
        this_task_phase_characteristic_type_names = this_task_phase_characteristic_type_names(characteristic_selections);
        n_characteristic_selections = sum(characteristic_selections);
        
        this_other_characteristic_types = this_other_characteristic_types(other_selections);
        this_other_characteristic_type_names = this_other_characteristic_type_names(other_selections);
        n_other_selections = sum(other_selections);
        
        bad_rows(idx) = ~ismember(condition_name, condition_selections) | ~ismember(task_phase_name, task_phase_selections);
        
        if ~bad_rows(idx)
                        
            if any(contains(task_phase_characteristic_groupings{characteristic_index}, 'response'))
                general_filters{idx} = {this_condition, task_phase, 'outcome_responded_yes'};
                n_outcomes(idx) = 1;
                outcomes{idx} = {'press'};
                outcome_labels{idx} = {'response_time'};
            else
                general_filters{idx} = {this_condition, task_phase};
                n_outcomes(idx) = length(all_outcomes);
                outcomes{idx} = all_outcomes;
                outcome_labels{idx} = all_outcome_labels;
            end
            
            if ismember(condition_name, {'scopolamine', 'stimulation'})
                valid_condition = contains(experimental_conditions, condition_name) & contains(experimental_conditions, task_phase_name); 
                has_condition(idx) = any(valid_condition);
                if any(valid_condition)
                    condition{idx} = experimental_conditions(valid_condition);
                end
            end
            
            if n_characteristic_selections == 1
                n_characteristics = length(this_task_phase_characteristic_types{1});
                characteristic_filters = this_task_phase_characteristic_types{1};
                characteristic_labels = cellfun(@(x) upper(x(1)), this_task_phase_characteristic_types{1}, 'UniformOutput', false);
            else
                filters1 = this_task_phase_characteristic_types{1};
                filters2 = this_task_phase_characteristic_types{2};
                
                labels1 = cellfun(@(x) upper(x(1)), filters1, 'UniformOutput', false);
                labels2 = cellfun(@(x) upper(x(1)), filters2, 'UniformOutput', false);
                
                n_types1 = length(filters1);
                n_types2 = length(filters2);
                
                n_characteristics = n_types1 * n_types2;
                
                [Ex, Fx] = ndgrid(1:n_types1, 1:n_types2);
                
                filters1 = filters1(Ex(:));
                filters2 = filters2(Fx(:));
                
                labels1 = labels1(Ex(:));
                labels2 = labels2(Fx(:));
                
                characteristic_filters = cell(n_characteristics, 1);
                characteristic_labels = cell(n_characteristics, 1);
                
                for jdx = 1:n_characteristics
                    characteristic_filters(jdx) = {filters1{jdx}, filters2{jdx}}; 
                    characteristic_labels{jdx} = [labels1{jdx}, labels2{jdx}];
                end
                                          
            end
            
            if n_other_selections == 1
                n_other = length(this_other_characteristic_types{1});
                other_filters = this_other_characteristic_types{1};
                other_labels = cellfun(@(x) upper(x(1)), this_other_characteristic_types{1}, 'UniformOutput', false);
            else
                filters1 = this_other_characteristic_types{1};
                filters2 = this_other_characteristic_types{2};
                
                labels1 = cellfun(@(x) upper(x(1)), filters1, 'UniformOutput', false);
                labels2 = cellfun(@(x) upper(x(1)), filters2, 'UniformOutput', false);
                
                n_types1 = length(filters1);
                n_types2 = length(filters2);
                
                n_other = n_types1 * n_types2;
                
                [Dx, Ex] = ndgrid(1:n_types1, 1:n_types2);
                
                filters1 = filters1(Ex(:));
                filters2 = filters2(Fx(:));
                
                labels1 = labels1(Ex(:));
                labels2 = labels2(Fx(:));
                
                other_filters = cell(n_other, 1);
                other_labels = cell(n_other, 1);
                
                for jdx = 1:n_other
                    other_filters(jdx) = {filters1{jdx}, filters2{jdx}}; 
                    other_labels{jdx} = [labels1{jdx}, labels2{jdx}];
                end
                                          
            end
            
            n_groups(idx) = n_characteristics * n_other;
                
            [Ex, Fx] = ndgrid(1:n_characteristics, 1:n_other);
                
            characteristic_filters = characteristic_filters(Ex(:));
            other_filters = other_filters(Fx(:));
                
            characteristic_labels = characteristic_labels(Ex(:));
            other_labels = other_labels(Fx(:));
                
            this_filters = cell(n_groups(idx), 1);
            this_labels = cell(n_groups(idx), 1);
                
            for jdx = 1:n_groups(idx)
                this_filters(jdx) = {characteristic_filters{jdx}, other_filters{jdx}}; 
                this_labels{jdx} = [characteristic_labels{jdx}, other_labels{jdx}];
            end
                
            group_filters{idx} = this_filters;
            group_labels{idx} = this_labels;
        
        end
            
    end
    
    new_rows = table(general_filters, n_groups, group_labels, group_filters, has_condition, condition, outcomes, n_outcomes);
    new_rows(bad_rows, :) = [];
    if height(new_rows) == 0
        new_rows = [];
    end
    analysis_parameters = [analysis_parameters; new_rows];
    
end

end