function [all_events, analysis_parameters] = n00_get_analysis_parameters(events_info, analysis_info)

data_directory = analysis_info.data_directory;

%%% Load all events
all_events = n00_get_all_events(data_directory, events_info);

%%% Analysis Info
analysis_type = analysis_info.analysis_type; 

switch analysis_type
    case 'behavioral'
        analysis_parameters = get_behavioral_analysis_parameters(all_events, analysis_info);
    otherwise
        analysis_parameters = table;
end
        
end


function analysis_parameters = get_behavioral_analysis_parameters(all_events, analysis_info)     

outcomes = analysis_info.outcomes;
task_phases = analysis_info.task_phases;
groupings = analysis_info.groupings;
answer_types = analysis_info.answer_types;
response_types = analysis_info.response_types;
other_responses = analysis_info.other_responses;
experimental_conditions = analysis_info.experimental_conditions;
random_effect_names = analysis_info.random_effect_names;
do_by_block = analysis_info.do_by_block;

all_groupings = get_all_groupings(groupings, other_responses);

n_task_phases = numel(task_phases);
n_experimental_conditions = numel(experimental_conditions);
n_groupings = numel(all_groupings);
n_do_by_block = length(do_by_block);

n_analyses = n_task_phases * n_experimental_conditions * n_groupings * n_do_by_block;
[Ax, Bx, Cx, Dx] = ndgrid(1:n_task_phases, 1:n_experimental_conditions, 1:n_groupings, 1:n_do_by_block);

outcomes = repelem({outcomes}, n_analyses, 1);
task_phase = vertcat(task_phases(Ax(:)))';
experimental_condition = vertcat(experimental_conditions(Bx(:)))';
grouping = vertcat(all_groupings(Cx(:)))';
do_by_block = do_by_block(Dx(:))';
general_filters = cell(n_analyses, 1);
n_groups = NaN(n_analyses, 1);

for idx = 1:n_analyses

    this_task_phase = task_phase{idx};
    this_experimental_condition = experimental_condition{idx};
    
    if any(contains(grouping{idx}, 'other'))
        other = task_phases{~strcmp(task_phases, this_task_phase)};
        grouping{idx} = strrep(grouping{idx}, 'other', other);
    end
    
    no_task_phase = ~contains(grouping{idx}, task_phases);
    grouping{idx}(no_task_phase) = append(this_task_phase, '_', grouping{idx}(no_task_phase));
    
    if ~strcmp(this_task_phase, 'any')
        general_filters{idx} = [general_filters{idx}, {sprintf('%s_task_phase', this_task_phase)}];
    else
        grouping{idx} = [grouping{idx}, {'task_phase'}];
    end
    
    if ~strcmp(this_experimental_condition, 'any')
    
        switch this_experimental_condition
            case 'none'
                general_filters{idx} = [general_filters{idx}, {'none_session'}];
            
            case 'control'
                general_filters{idx} = [general_filters{idx}, {'control'}];
            
            otherwise
                grouping{idx} = [grouping{idx}, {this_experimental_condition}];
                
                if contains(this_experimental_condition, 'stimulation')
                    general_filters{idx} = [general_filters{idx}, {'stimulation_session'}];
                end
                
                if contains(this_experimental_condition, 'scopolamine')
                    general_filters{idx} = [general_filters{idx}, {'scopolamine_session'}];
                end
        end
        
    end
    
    n_per_grouping = cellfun(@(x) length(unique(all_events.(x))), grouping{idx});
    n_groups(idx) = 1;
    
    for jdx = 1:length(n_per_grouping)
        n_groups(idx) = n_groups(idx) * n_per_grouping(jdx);
    end
    
end

analysis_parameters = table(outcomes, task_phase, experimental_condition, grouping, general_filters, n_groups, do_by_block);

end


function all_groupings = get_all_groupings(groupings, other_responses)

contain_other_responses = cellfun(@(x) any(contains(x, 'other_responses')), groupings);

if ~isempty(other_responses) && any(contain_other_responses) 
    
    simple_groupings = groupings(~contain_other_responses);
    complex_grouping_types = groupings(contain_other_responses);
    
    n_other_responses = size(other_responses, 1);
    n_complex_grouping_types = length(complex_grouping_types);
    
    n_complex_groupings = n_complex_group_types * n_other_responses;
    
    [Ax, Bx] = ndgrid(1:n_other_responses, 1:n_complex_groupings);
    response_index = Ax(:);
    grouping_index = Bx(:);
    
    complex_groupings = cell(n_complex_groupings, 1);
    
    for idx = 1:n_complex_grouping_types
    
        other_response = other_responses{response_index(idx)};
        grouping = complex_grouping_types{grouping_index(idx)};
        other_response_idx = contains(grouping, 'other_responses');
        grouping(other_response_idx) = [];
        grouping = [grouping, other_response];
        complex_groupings(idx) = grouping;
        
    end
    
    all_groupings = [simple_groupings, complex_groupings];

else
    all_groupings = groupings;
end

end