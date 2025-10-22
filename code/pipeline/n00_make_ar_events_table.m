%%% The purpose of this function is to simplify and enhance the performance of all possible combinations of analyses
%%% that could be made with associative recoginition experiment data. This is done by reflecting the hierarchical nature
%%% of the task with column names that could be related to one another with code and used to programatically filter tables; 
%%% reducing the overall size of the events file by transorming all categorical data into 83 logical columns; 
%%% and reducing sizes of numerical values.
%%% Utilization of this events structure to produce all possible combinations of analyses is available on n00_get_analysis_parameters2.
  
function [n_events, n_blocks] = n00_make_ar_events_table(events, events_info, event_count, block_count, data_directory)

%%% Get session data from events info
this_subject    = events_info.subject{:};
this_task       = events_info.task{:};
this_session    = events_info.session{:};
this_subject_ID = events_info.subject_ID;
this_session_ID = events_info.session_ID;
is_aligned      = events_info.is_aligned;

save_file_name = fullfile(data_directory, this_subject, this_task, this_session, 'events_table.mat');

%%% Filter for encoding and retrieval events only
events = events(contains(events.event, {'ENC', 'RET'}), :);
n_events = height(events);

%%% Get data avout experiment block to produce a column with block IDs
unique_blocks = unique(events.block);
n_blocks = length(unique_blocks);
block_IDs = uint16(block_count + 1 : block_count + n_blocks);

%%% Reduce size of task computer time to uint32
mstime = uint32(events.mstime - min(events.mstime));

%%% eegfile replaced by number indicating index of unique EEGs in events file, eegoffset reduced in size to uint32
if is_aligned

    eegoffset       = uint32(events.eegoffset);
    unique_eegfiles = unique(events.eegfile);
    eegfile         = cellfun(@(x) uint8(find(strcmp(unique_eegfiles, x))), events.eegfile, 'UniformOutput', false);
    empty_eegfile   = cellfun(@isempty, eegfile);
    
    eegfile(empty_eegfile) = repelem({uint8(NaN)}, sum(empty_eegfile), 1);
    
else
    
    eegoffset = uint32(NaN(n_events, 1));
    eegfile   = uint8(NaN(n_events, 1));

end

%%% Columns for low size subject, session, block, and event IDs
subject_ID = repmat(this_subject_ID, n_events, 1);
session_ID = repmat(this_session_ID, n_events, 1);
block_ID   = arrayfun(@(x) block_IDs(unique_blocks == x), events.block);
event_ID   = uint32(event_count + 1 : event_count + n_events)';

%%% Logicals to indicate whether the experimental session contains a given experimental condition
practice = contains(events.event, 'PRA');

condition_practice    = repmat(any(practice), n_events, 1);
condition_stimulation = repmat(contains(this_task, 'stim'), n_events, 1);
condition_scopolamine = repmat(contains(this_task, 'Scopolamine'), n_events, 1);
condition_none        = ~condition_stimulation & ~condition_scopolamine;
condition_any         = true(n_events, 1);

%%% Logicals to indicate task phase of event
task_encoding  = contains(events.event, 'ENCODING');
task_retrieval = contains(events.event, 'RETRIEVAL');

%%% Logicals to indicate whether there was a response and whether the response was correct
outcome_responded_yes = events.response > 0;
outcome_responded_no  = ~outcome_responded_yes;

outcome_correct_yes = events.correct == 1;
outcome_correct_no  = outcome_responded_yes & ~outcome_correct_yes;

%%% Reduce size of timing of response to uint16 (max time 4000 ms).
outcome_press = uint16(outcome_responded_yes) .* uint16(events.mstime_toResp);

%%% Processing of events
word_pairs  = events.wp;

split_pairs = cellfun(@(x) strsplit(x, '/'), word_pairs, 'UniformOutput', false);
split_pairs = vertcat(split_pairs{:});

top_word    = split_pairs(:, 1);
bottom_word = split_pairs(:, 2);

%%% Encoding events answer, whether responded, response, whether correct, and response timing (24 bits)
encoding_answer_top      = task_encoding & events.correct_ans == 1;
encoding_answer_bottom   = task_encoding & events.correct_ans == 2;
encoding_responded_yes   = task_encoding & outcome_responded_yes;
encoding_responded_no    = task_encoding & outcome_responded_no;
encoding_response_top    = task_encoding & events.response == 1;
encoding_response_bottom = task_encoding & events.response == 2;
encoding_correct_yes     = task_encoding & outcome_correct_yes;
encoding_correct_no      = task_encoding & outcome_correct_no;
encoding_press           = uint16(task_encoding) .* outcome_press;

%%% Retrieval events answer, whether responded, response, whether correct, and response timing (24 bits)
retrieval_answer_rearranged   = task_encoding & logical(events.rearranged);
retrieval_answer_intact       = (task_encoding & ~retrieval_answer_rearranged) | (task_retrieval & events.correct_ans == 1);
retrieval_answer_rearranged   = retrieval_answer_rearranged | (task_retrieval & events.correct_ans == 2);
retrieval_answer_new          = task_retrieval & events.correct_ans == 3;
retrieval_responded_yes       = task_retrieval & outcome_responded_yes;
retrieval_responded_no        = task_retrieval & outcome_responded_no;
retrieval_response_intact     = task_retrieval & events.response == 1;
retrieval_response_rearranged = task_retrieval & events.response == 2;
retrieval_response_new        = task_retrieval & events.response == 3;
retrieval_correct_yes         = task_retrieval & outcome_correct_yes;
retrieval_correct_no          = task_retrieval & outcome_correct_no;
retrieval_press               = uint16(task_retrieval) .* outcome_press;

%%% Initialize arrays to hold data linking encoding events to retrieval events and vice versa
false_array = false(n_events, 1);
nan_array   = uint16(NaN(n_events, 1));

%%% Data for top word in a pair in opposite task phase
top_responded_yes       = false_array;
top_responded_no        = false_array;
top_response_intact     = false_array;
top_response_rearranged = false_array;
top_response_new        = false_array;
top_response_top        = false_array;
top_response_bottom     = false_array;
top_correct_yes         = false_array;
top_correct_no          = false_array;
top_press               = nan_array;

%%% Data for bottom word in a pair in opposite task phase
bottom_responded_yes       = false_array;
bottom_responded_no        = false_array;
bottom_response_intact     = false_array;
bottom_response_rearranged = false_array;
bottom_response_new        = false_array;
bottom_response_top        = false_array;
bottom_response_bottom     = false_array;
bottom_correct_yes         = false_array;
bottom_correct_no          = false_array;
bottom_press               = nan_array;

%%% Data for first word to appear in opposite task phase
first_responded_yes       = false_array;
first_responded_no        = false_array;
first_response_intact     = false_array;
first_response_rearranged = false_array;
first_response_new        = false_array;
first_response_top        = false_array;
first_response_bottom     = false_array;
first_correct_yes         = false_array;
first_correct_no          = false_array;
first_press               = nan_array;

%%% Data for second word to appear in opposite task phase
second_responded_yes       = false_array;
second_responded_no        = false_array;
second_response_intact     = false_array;
second_response_rearranged = false_array;
second_response_new        = false_array;
second_response_top        = false_array;
second_response_bottom     = false_array;
second_correct_yes         = false_array;
second_correct_no          = false_array;
second_press               = nan_array;

%%% Joining data of any word of the pair in opposite task phase
any_responded_yes       = false_array;
any_responded_no        = false_array;
any_response_intact     = false_array;
any_response_rearranged = false_array;
any_response_new        = false_array;
any_response_top        = false_array;
any_response_bottom     = false_array;
any_correct_yes         = false_array;
any_correct_no          = false_array;
any_press               = nan_array;

%%% Data about experiment condition in a given experiment phase
top_is_first = false_array;

encoding_stimulation  = false_array;
retrieval_stimulation = false_array;

if any(condition_stimulation)
    retrieval_stimulation = logical(events.retr_stim);
end

encoding_scopolamine = false_array;
retrieval_scopolamine = false_array;

if any(condition_scopolamine)
    retrieval_scopolamine = block_ID > 1;
    encoding_scopolamine  = block_ID > 2;
end

condition_control = ~retrieval_stimulation & ~encoding_scopolamine & ~retrieval_scopolamine;

%%% Loop to link encoding trial data to retrieval trial data
for idx = 1:n_events
    
    if task_encoding(idx)
    
        has_top    = task_retrieval & strcmp(top_word, top_word(idx));
        has_bottom = task_retrieval & strcmp(bottom_word, bottom_word(idx));
        
        if any(has_top)
            top_responded_yes(idx)       = retrieval_responded_yes(has_top);
            top_responded_no(idx)        = retrieval_responded_no(has_top);
            top_response_intact(idx)     = retrieval_response_intact(has_top);
            top_response_rearranged(idx) = retrieval_response_rearranged(has_top);
            top_response_new(idx)        = retrieval_response_new(has_top);
            top_correct_yes(idx)         = retrieval_correct_yes(has_top);
            top_correct_no(idx)          = retrieval_correct_no(has_top);
            top_press(idx)               = retrieval_press(has_top);
        end
        
        if any(has_bottom)
            bottom_responded_yes(idx)       = retrieval_responded_yes(has_bottom);
            bottom_responded_no(idx)        = retrieval_responded_no(has_bottom);
            bottom_response_intact(idx)     = retrieval_response_intact(has_bottom);
            bottom_response_rearranged(idx) = retrieval_response_rearranged(has_bottom);
            bottom_response_new(idx)        = retrieval_response_new(has_bottom);
            bottom_correct_yes(idx)         = retrieval_correct_yes(has_bottom);
            bottom_correct_no(idx)          = retrieval_correct_no(has_bottom);
            bottom_press(idx)               = retrieval_press(has_bottom);
        end
        
        if any(has_top) && any(has_bottom)
        
            top_is_first(idx) = mstime(has_top) < mstime(has_bottom);
            
            if top_is_first(idx)
                has_first  = has_top;
                has_second = has_bottom;
            else
                has_first  = has_bottom;
                has_second = has_top;
            end
            
            first_responded_yes(idx)       = retrieval_responded_yes(has_first);
            first_response_intact(idx)     = retrieval_response_intact(has_first);
            first_response_rearranged(idx) = retrieval_response_rearranged(has_first);
            first_response_new(idx)        = retrieval_response_new(has_first);
            first_correct_yes(idx)         = retrieval_correct_yes(has_first);
            first_correct_no(idx)          = retrieval_correct_no(has_second);
            first_press(idx)               = retrieval_press(has_first);
            
            second_responded_yes(idx)       = retrieval_responded_yes(has_second);
            second_response_intact(idx)     = retrieval_response_intact(has_second);
            second_response_rearranged(idx) = retrieval_response_rearranged(has_second);
            second_response_new(idx)        = retrieval_response_new(has_second);
            second_correct_yes(idx)         = retrieval_correct_yes(has_second);
            second_correct_no(idx)          = retrieval_correct_no(has_second);
            second_press(idx)               = retrieval_press(has_second);
            
            any_responded_yes(idx)       = top_responded_yes(idx) | bottom_responded_yes(idx);
            any_responded_no(idx)        = top_responded_no(idx) & bottom_responded_no(idx);
            any_response_intact(idx)     = top_response_intact(idx) | bottom_response_intact(idx);
            any_response_rearranged(idx) = top_response_rearranged(idx) | bottom_response_rearranged(idx);
            any_response_new(idx)        = top_response_new(idx) | bottom_response_rearranged(idx);
            any_correct_yes(idx)         = first_correct_yes(idx) | second_correct_yes(idx);
            any_correct_no(idx)          = first_correct_no(idx) & second_correct_no(idx);
            any_press(idx)               = mean([first_press(idx), second_press(idx)], 'omitnan');
            retrieval_press(idx)         = any_press(idx);
        
        end
    
    end
    
    if task_retrieval(idx)
    
        has_top = task_encoding & strcmp(top_word, top_word(idx));
        has_bottom = task_encoding & strcmp(bottom_word, bottom_word(idx));
        
        if any(has_top)
            top_responded_yes(idx)   = encoding_responded_yes(has_top);
            top_responded_no(idx)    = encoding_responded_no(has_top);
            top_response_top(idx)    = encoding_response_top(has_top);
            top_response_bottom(idx) = encoding_response_bottom(has_top);
            top_correct_yes(idx)     = encoding_correct_yes(has_top);
            top_correct_no(idx)      = encoding_correct_no(has_top);
            top_press(idx)           = encoding_press(has_top);
        end
        
        if any(has_bottom)
            bottom_responded_yes(idx)   = retrieval_responded_yes(has_bottom);
            bottom_responded_no(idx)    = retrieval_responded_no(has_bottom);
            bottom_response_top(idx)    = encoding_response_top(has_bottom);
            bottom_response_bottom(idx) = encoding_response_bottom(has_bottom);
            bottom_correct_yes(idx)     = encoding_correct_yes(has_bottom);
            bottom_correct_no(idx)      = encoding_correct_no(has_bottom);
            bottom_press(idx)           = encoding_press(has_bottom);
        end
        
        if any(has_top) && any(has_bottom)
        
            top_is_first(idx) = events.mstime(has_top) < events.mstime(has_bottom);
            
            if top_is_first(idx)
                has_first  = has_top;
                has_second = has_bottom;
            else
                has_first  = has_bottom;
                has_second = has_top;
            end
            
            first_responded_yes(idx)   = retrieval_responded_yes(has_first);
            first_responded_no(idx)    = retrieval_responded_no(has_first);
            first_response_top(idx)    = encoding_response_top(has_first);
            first_response_bottom(idx) = encoding_response_bottom(has_first);
            first_correct_yes(idx)     = encoding_correct_yes(has_first);
            first_correct_no(idx)      = encoding_correct_no(has_first);
            first_press(idx)           = encoding_press(has_first);
            
            second_responded_yes(idx)   = retrieval_responded_yes(has_second);
            second_responded_no(idx)    = retrieval_responded_no(has_second);
            second_response_top(idx)    = encoding_response_top(has_second);
            second_response_bottom(idx) = encoding_response_bottom(has_second);
            second_correct_yes(idx)     = encoding_correct_yes(has_second);
            second_correct_no(idx)      = encoding_correct_no(has_second);
            second_press(idx)           = encoding_press(has_second);        
            
            any_responded_yes(idx)   = encoding_responded_yes(has_top)|encoding_responded_yes(has_bottom);
            any_responded_no(idx)    = encoding_responded_no(has_top) & encoding_responded_no(has_bottom);
            any_response_top(idx)    = top_response_top(idx)|bottom_response_top(idx);
            any_response_bottom(idx) = top_response_bottom(idx)|bottom_response_bottom(idx);
            any_correct_yes(idx)     = encoding_correct_yes(has_top)|encoding_correct_yes(has_bottom);
            any_correct_no(idx)      = encoding_correct_no(has_top) & encoding_correct_no(has_bottom);
            any_press(idx)           = mean([first_press(idx), second_press(idx)], 'omitnan');
            
            encoding_press(idx) = any_press(idx);
        
        end
    
    end

end

%%% Make table with all columns and save
events_table = table(subject_ID, session_ID, block_ID, event_ID, ...
    condition_practice, condition_stimulation, condition_scopolamine, condition_none, condition_any...
    task_encoding, task_retrieval, ...
    outcome_responded_yes, outcome_responded_no, outcome_correct_yes, outcome_correct_no, outcome_press, ...
    encoding_answer_top, encoding_answer_bottom, ...
    encoding_responded_yes, encoding_responded_no, ...
    encoding_response_top, encoding_response_bottom, ...
    encoding_correct_yes, encoding_correct_no, ...
    encoding_press, ...
    retrieval_answer_intact, retrieval_answer_rearranged, retrieval_answer_new, ...
    retrieval_responded_yes, retrieval_responded_no, ...
    retrieval_response_intact, retrieval_response_rearranged, retrieval_response_new, ...
    retrieval_correct_yes, retrieval_correct_no, ...
    retrieval_press, ...
    top_responded_yes, top_responded_no, ...
    top_response_intact, top_response_rearranged, top_response_new, top_response_top, top_response_bottom, ...
    top_correct_yes, top_correct_no, ...
    top_press, ...
    bottom_responded_yes, bottom_responded_no, ...
    bottom_response_intact, bottom_response_rearranged, bottom_response_new, bottom_response_top, bottom_response_bottom, ...
    bottom_correct_yes, bottom_correct_no, ...
    bottom_press, ...
    first_responded_yes, first_responded_no, ...
    first_response_intact, first_response_rearranged, first_response_new, first_response_top, first_response_bottom, ...
    first_correct_yes, first_correct_no, ...
    first_press, ...
    second_responded_yes, second_responded_no, ...
    second_response_intact, second_response_rearranged, second_response_new, second_response_top, second_response_bottom, ...
    second_correct_yes, second_correct_no, ...
    second_press, ...
    any_responded_yes, any_responded_no, ...
    any_response_intact, any_response_rearranged, any_response_new, any_response_top, any_response_bottom, ...
    any_correct_yes, any_correct_no, ...
    any_press, ...
    top_is_first, ...
    practice, encoding_stimulation, retrieval_stimulation, encoding_scopolamine, retrieval_scopolamine, ...
    mstime, eegoffset, eegfile);

save(save_file_name, 'events_table');

end