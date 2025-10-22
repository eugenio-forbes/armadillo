function n04_check_events(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    mode = 'asdf';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    mode = 'recheck';
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
subjects_directory = fullfile(analysis_directory, 'subject_files');
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');
if ~isfolder(data_directory)
    mkdir(data_directory);
end

load(fullfile(list_directory, 'subject_list.mat'), 'subject_list');
load(fullfile(list_directory, 'session_list.mat'), 'session_list');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

electrode_session_IDs = electrode_list.session_ID;

%%% Loop through sessions to load events files, change EEG file to current
%%% noreref folder path, and correct any errors in the files. Initialize
%%% table columns for events file information to be able to identify events
%%% files that might need to be realigned, and to exclude subjects with
%%% incomplete sessions.

n_sessions = height(session_list);

a = NaN(n_sessions, 1);
b = false(n_sessions, 1);
c = cell(n_sessions, 1);
d = zeros(n_sessions, 1);

subject = c;
task = c;
session = c;
subject_ID = a;
session_ID = a;
n_study_blocks = a;
n_test_blocks = a;
n_blocks = a;
has_practice = b;
block_study_pairs = a;
total_study_pairs = a;
n_study_intact = a;
n_study_rearranged = a;
f_response_study = a;
f_correct_study = a;
f_response_correct_study = a;
response_time_study = a;
block_test_pairs = a;
total_test_pairs = a;
n_test_intact = a;
n_test_rearranged = a;
n_test_new = a;
f_response_test = a;
f_correct_test = a;
f_response_correct_test = a;
response_time_test = a;
n_empty_study_blocks = d;
n_empty_test_blocks = d;
n_shared_blocks = a;
mismatch_indices_study = repelem({[]}, n_sessions, 1);
mismatch_indices_test = repelem({[]}, n_sessions, 1);
rearranged_across_block_indices = repelem({[]}, n_sessions, 1);
n_electrodes = d;
is_aligned = b;
n_recordings = a;
computer_time_length = a;
eeg_time_length = c;
eeg_file_length = c;
missing_channels = c;
study_pair_duration = a;
test_pair_duration = a;
study_section_duration = a;
test_section_duration = a;
break_duration = a;
bad_session = b;
reason_bad = repelem({''}, n_sessions, 1);
repeated_words = c;

for idx = 1:n_sessions

    %%% Get session information
    this_subject    = session_list.subject{idx};
    subject_number  = str2double(this_subject(end-2:end));
    subject{idx}    = this_subject;
    this_task       = session_list.task{idx};
    task{idx}       = this_task;
    this_session    = session_list.session{idx};
    session{idx}    = this_session;
    subject_ID(idx) = session_list.subject_ID(idx);
    session_ID(idx) = session_list.session_ID(idx);
    
    n_electrodes(idx) = sum(electrode_session_IDs == session_ID(idx));
    
    if strcmp(mode, 'recheck')
        events_file_path = fullfile(data_directory, this_subject, this_task, this_session, 'events.mat');
        load(events_file_path, 'events')
    else        
        %%% Path to original events file in subject's directory
        events_file_path = fullfile(subjects_directory, this_subject, 'behavioral', this_task, this_session, 'events.mat');
        
        %%% Load events and convert to table
        load(events_file_path, 'events')
        events = struct2table(events);
    end
    
    if iscell(events.correct_ans)
        events.correct_ans = cellfun(@str2double, events.correct_ans);
    end
    
    fields = events.Properties.VariableNames;
    
    if iscell(events.correct_opp_1)
        replacement = events.correct_opp_1;
        empty_cells = cellfun(@isempty, replacement);
        replacement(empty_cells) = repelem({0}, sum(empty_cells), 1);
        events.correct_opp_1 = vertcat(replacement{:});
    end
    
    events.correct_opp_1 = events.correct_opp_1 == 1;
    
    if iscell(events.correct_opp_2)
        replacement = events.correct_opp_2;
        empty_cells = cellfun(@isempty, replacement);
        replacement(empty_cells) = repelem({0}, sum(empty_cells), 1);
        events.correct_opp_2 = vertcat(replacement{:});
    end
    
    events.correct_opp_2 = events.correct_opp_2 == 1;
    
    if iscell(events.retrieval_ans_1)
        replacement = events.retrieval_ans_1;
        empty_cells = cellfun(@isempty, replacement);
        replacement(empty_cells) = repelem({NaN}, sum(empty_cells), 1);
        events.retrieval_ans_1 = vertcat(replacement{:});
    end
    
    events.retrieval_ans_1 = double(events.retrieval_ans_1);
    
    if iscell(events.retrieval_ans_2)
        replacement = events.retrieval_ans_2;
        empty_cells = cellfun(@isempty, replacement);
        replacement(empty_cells) = repelem({NaN}, sum(empty_cells), 1);
        events.retrieval_ans_2 = vertcat(replacement{:});
    end
    
    events.retrieval_ans_2 = double(events.retrieval_ans_2);
    
    if ismember('eegoffset', fields)
        
        if iscell(events.eegoffset)
            replacement = events.eegoffset;
            empty_cells = cellfun(@isempty, replacement);
            replacement(empty_cells) = repelem({NaN}, sum(empty_cells), 1);
            events.eegoffset = double(vertcat(replacement{:}));
        else
            events.eegoffset = double(events.eegoffset);
        end
    
    end
    
    if ismember('mstime', fields)
        events.mstime = double(events.mstime);
    end
    
    if ismember('mstime_toResp', fields)
        events.mstime_toResp = double(events.mstime_toResp);
    end
    
    events.correct = events.correct == 1;
    events.rearranged = events.rearranged == 1;
    events.response = double(events.response);

    computer_time_length(idx) = (max(events.mstime)-min(events.mstime))/(1000*60*60);
    
    if ismember('block', fields)
    
        practice_indices = strcmp(events.block, 'PRACTICE') | contains(events.event, 'PRA');
        if any(practice_indices) && iscell(events.block)
            events.block(practice_indices) = repelem({'0'}, sum(practice_indices), 1);
            events.block = cellfun(@str2double, events.block);
        elseif any(practice_indices) && any(isnan(events.block(practice_indices)))
            events.block(practice_indices) = zeros(sum(practice_indices), 1);
        end
    
    else
    
        events.block = NaN(height(events), 1);
        block_number = 0;
        
        for jdx = 1:height(events)
            
            events.block(jdx) = block_number;
            
            if contains(events.event{jdx}, 'TEST END')
                if ~contains(events.event{jdx}, 'STUDY')
                    block_number = block_number +1;
                end
            end
        
        end
            
    end
    
    is_study = contains(events.event, 'ENCODING');
    is_test = contains(events.event, 'RETRIEVAL');
    encoding_events = events(is_study, :);
    retrieval_events = events(is_test, :);
    
    encoding_word_pairs = encoding_events.wp;
    retrieval_word_pairs = retrieval_events.wp;
    
    if ~isempty(encoding_word_pairs) && ~isempty(retrieval_word_pairs)
        
        encoding_split_pairs = cellfun(@(x) strsplit(x, '/'), encoding_word_pairs, 'UniformOutput', false);
        encoding_split_pairs = vertcat(encoding_split_pairs{:});
        encoding_top_words = encoding_split_pairs(:, 1);
        encoding_bottom_words = encoding_split_pairs(:, 2);
        encoding_all_words = [encoding_top_words;encoding_bottom_words];
        encoding_unique_words = unique(encoding_all_words);
        encoding_counts = cellfun(@(x) sum(strcmp(encoding_all_words, x)), encoding_unique_words);
        
        
        retrieval_split_pairs = cellfun(@(x) strsplit(x, '/'), retrieval_word_pairs, 'UniformOutput', false);
        retrieval_split_pairs = vertcat(retrieval_split_pairs{:});
        retrieval_top_words = retrieval_split_pairs(:, 1);
        retrieval_bottom_words = retrieval_split_pairs(:, 2);
        retrieval_all_words = [retrieval_top_words;retrieval_bottom_words];
        retrieval_unique_words = unique(retrieval_all_words);
        retrieval_counts = cellfun(@(x) sum(strcmp(retrieval_all_words, x)), retrieval_unique_words);
             
        if any(ismember(encoding_top_words, retrieval_bottom_words))||any(ismember(encoding_bottom_words, retrieval_top_words))
            bad_session(idx) = true;
            reason_bad{idx} = update_reason(reason_bad{idx}, '<top_bottom_switch>');
        end
        
        if any(encoding_counts > 1)
            bad_session(idx) = true;
            reason_bad{idx} = update_reason(reason_bad{idx}, '<encoded_more_than_once>');
            encoding_repeats = encoding_unique_words(encoding_counts>1);
            repeated_words{idx} = [repeated_words{idx};encoding_repeats];
        end
        
        if any(retrieval_counts > 1)
            bad_session(idx) = true;
            retrieval_repeats = retrieval_unique_words(retrieval_counts>1);
            repeated_words{idx} = [repeated_words{idx};retrieval_repeats];
            reason_bad{idx} = update_reason(reason_bad{idx}, '<retrieved_more_than_once>');
        end
        
    end
        
    has_practice(idx) = any(contains(events.event, 'PRACTICE'));
    unique_study_blocks = unique(encoding_events.block);
    unique_test_blocks = unique(retrieval_events.block);
    n_study_blocks(idx) = length(unique_study_blocks);
    n_test_blocks(idx) = length(unique_test_blocks);
    n_blocks(idx) = max(n_study_blocks(idx), n_test_blocks(idx));
    
    if any(~ismember(unique_study_blocks, unique_test_blocks))
        bad_session(idx) = true;
        reason_bad{idx} = update_reason(reason_bad{idx}, '<unpaired_study>');
    end
    
    if any(~ismember(unique_test_blocks, unique_study_blocks))
        bad_session(idx) = true;
        reason_bad{idx} = update_reason(reason_bad{idx}, '<unpaired_test>');
    end
    
    if ~isempty(encoding_events)
        block_study_pairs(idx) = max(arrayfun(@(x) sum(encoding_events.block == x), unique_study_blocks));
        total_study_pairs(idx) = height(encoding_events);
        n_study_rearranged(idx) = sum(encoding_events.rearranged);
        n_study_intact(idx) = total_study_pairs(idx) - n_study_rearranged(idx);
        
        has_response = encoding_events.response > 0;
        is_correct = encoding_events.correct == 1;
        f_response_study(idx) = sum(has_response)/total_study_pairs(idx);
        f_correct_study(idx) = sum(is_correct)/total_study_pairs(idx);
        f_response_correct_study(idx) = sum(has_response&is_correct)/sum(has_response);
        
        if ismember('mstime_toResp', fields)
            response_time_study(idx) = mean(encoding_events.mstime_toResp(has_response));
        end
    
        n_unique_study = length(unique_study_blocks);
        incomplete_block = false(n_unique_study, 1);
        
        for jdx = 1:n_unique_study
        
            this_block = unique_study_blocks(jdx);
            block = encoding_events(encoding_events.block == this_block, :);
            is_practice = this_block == 0 || any(contains(block.event, 'PRA'));
            
            if height(block) < block_study_pairs(idx) && ~is_practice
                incomplete_block(jdx) = true;
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<incomplete_study>');
            end
            
            if ~any(block.response > 0)
                n_empty_study_blocks(idx) = n_empty_study_blocks(idx) + 1;
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<empty_study>');
            end
        
        end
        
        bad_blocks = unique_study_blocks(incomplete_block);
        unique_study_blocks(incomplete_block) = [];
        encoding_events(ismember(encoding_events.block, bad_blocks), :) = [];
    
    end
   
    if ~isempty(retrieval_events)
        block_test_pairs(idx) = max(arrayfun(@(x) sum(retrieval_events.block == x), unique_test_blocks));
        total_test_pairs(idx) = height(retrieval_events);
        n_test_intact(idx) = sum(retrieval_events.correct_ans == 1);
        n_test_rearranged(idx) = sum(retrieval_events.correct_ans == 2);
        n_test_new(idx) = sum(retrieval_events.correct_ans == 3);
        
        has_response = retrieval_events.response > 0;
        is_correct = retrieval_events.correct == 1;
        f_response_test(idx) = sum(has_response)/total_test_pairs(idx);
        f_correct_test(idx) = sum(is_correct)/total_test_pairs(idx);
        f_response_correct_test(idx) = sum(has_response & is_correct)/sum(has_response);
        
        if ismember('mstime_toResp', fields)
            response_time_test(idx) = mean(retrieval_events.mstime_toResp(has_response));
        end
        
        n_unique_test = length(unique_test_blocks);
        incomplete_block = false(n_unique_test, 1);
        
        for jdx = 1:n_unique_test
            
            this_block = unique_test_blocks(jdx);
            block = retrieval_events(retrieval_events.block == this_block, :);
            is_practice = this_block == 0 || any(contains(block.event, 'PRA'));
            
            if height(block) < block_test_pairs(idx) && ~is_practice
                incomplete_block(jdx) = true;
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<incomplete_test>');
            end
            
            if ~any(block.response>0)
                n_empty_test_blocks(idx) = n_empty_test_blocks(idx) + 1;
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<empty_test>');
            end
        
        end
        
        bad_blocks = unique_test_blocks(incomplete_block);
        unique_test_blocks(incomplete_block) = [];
        retrieval_events(ismember(retrieval_events.block, bad_blocks), :) = [];
        
    end
    
    shared_blocks = unique_study_blocks(ismember(unique_study_blocks, unique_test_blocks));
    n_shared_blocks(idx) = length(shared_blocks);
    
    if ~isempty(shared_blocks)
    
        paired_encoding_events = encoding_events(ismember(encoding_events.block, shared_blocks), :);
        paired_retrieval_events = retrieval_events(ismember(retrieval_events.block, shared_blocks), :);            
        
        split = cellfun(@(x) strsplit(x, '/'), paired_retrieval_events.wp, 'UniformOutput', false);
        split = vertcat(split{:});
        paired_top_words = split(:, 1);
        paired_bottom_words = split(:, 2);
        
        for jdx = 1:height(paired_encoding_events)
            
            event = paired_encoding_events(jdx, :);
            block = event.block;
            pair = event.wp{:};
            correct_ans = event.correct_ans;
            response = event.response;
            is_correct = event.correct;
            is_rearranged = event.rearranged;
            
            correct_opp_1 = event.correct_opp_1;
            correct_opp_2 = event.correct_opp_2;
            retrieval_ans_1 = event.retrieval_ans_1;
            retrieval_ans_2 = event.retrieval_ans_2;
            possible_test_pairs = paired_retrieval_events(paired_retrieval_events.block == block, :);
            split = cellfun(@(x) strsplit(x, '/'), possible_test_pairs.wp, 'UniformOutput', false);
            split = vertcat(split{:});
            possible_top_words = split(:, 1);
            possible_bottom_words = split(:, 2);
            
            if ismember('pressed', fields)
                
                pressed = event.pressed{:};
                
                switch pressed
                    case 'T'
                        comparison = response == 1;
                    
                    case 'B'
                        comparison = response == 2;
                    
                    case 'NONE'
                        comparison = response < 1;
                    
                    otherwise
                        comparison = true;
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<bad_key_press>');                        
                end
                
                if ~comparison
                    mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                    bad_session(idx) = true;
                    reason_bad{idx} = update_reason(reason_bad{idx}, '<pressed_response_mismatch>');
                end
            
            end
            
            if (response == correct_ans && ~is_correct) || (response ~= correct_ans && is_correct)
                
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<correct_study_mismatch>');
            end
            
            if is_rearranged
            
                mislabeled = any(strcmp(possible_test_pairs.wp, pair));
                any_block_mislabeled = any(strcmp(paired_retrieval_events.wp, pair));
                pair = strsplit(pair, '/');
                top_word = pair{1};
                bottom_word = pair{2};
                has_top = strcmp(possible_top_words, top_word);
                has_bottom = strcmp(possible_bottom_words, bottom_word);
                
                if any(has_top) && any(has_bottom) && ~mislabeled
                
                    test_top = possible_test_pairs(has_top, :);
                    test_bottom = possible_test_pairs(has_bottom, :);
                    
                    if subject_number < 235
                    
                        if test_top.mstime < test_bottom.mstime
                            opp1 = test_top;
                            opp2 = test_bottom;
                        else
                            opp1 = test_bottom;
                            opp2 = test_top;
                        end
                        
                    else
                        opp1 = test_top;
                        opp2 = test_bottom;
                    end
                    
                    if opp1.response ~= retrieval_ans_1
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<retrieval_ans_1_mismatch>');
                    end
                    
                    if opp1.correct ~= correct_opp_1
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<correct_opp_1_mismatch>');
                    end
                    
                    if ~opp2.response == retrieval_ans_2
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<retrieval_ans_2_mismatch>');
                    end
                    
                    if opp2.correct ~= correct_opp_2
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<correct_opp_2_mismatch>');
                    end
                
                else
                
                    any_block_has_top = strcmp(paired_top_words, top_word);
                    any_block_has_bottom = strcmp(paired_bottom_words, bottom_word);
                    
                    if mislabeled || any_block_mislabeled
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<mislabeled_condition>');
                    elseif height(possible_test_pairs) < (4/3)*(block_study_pairs(idx))
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<incomplete_test>');
                    else
                    
                        if any(any_block_has_top) && any(any_block_has_bottom)
                            rearranged_across_block_indices{idx} = cat(1, rearranged_across_block_indices{idx}, jdx);
                            bad_session(idx) = true;
                            reason_bad{idx} = update_reason(reason_bad{idx}, '<rearranged_across_block>');
                        else
                            mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                            bad_session(idx) = true;
                            reason_bad{idx} = update_reason(reason_bad{idx}, '<missing_rearranged>');
                        end
                        
                    end
                
                end
            
            else
            
                has_pair = strcmp(possible_test_pairs.wp, pair);
                
                if any(has_pair)
                
                    test_pair = possible_test_pairs(has_pair, :);
                    
                    if test_pair.response ~= retrieval_ans_1
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<retrieval_ans_1_mismatch>');
                    end
                    
                    if test_pair.correct ~= correct_opp_1
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<correct_opp_1_mismatch>');
                    end
                    
                else
                
                    any_block_has_pair = strcmp(paired_retrieval_events.wp, pair);
                    pair = strsplit(pair, '/');
                    top_word = pair{1};
                    bottom_word = pair{2};
                    has_top = contains(possible_test_pairs.wp, top_word);
                    has_bottom = contains(possible_test_pairs.wp, bottom_word);
                    any_block_has_top = contains(paired_retrieval_events.wp, top_word);
                    any_block_has_bottom = contains(paired_retrieval_events.wp, bottom_word);
                    
                    if any(any_block_has_pair)
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<intact_in_other_block');
                    elseif any(has_top) || any(has_bottom)
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<mislabeled_intact');
                    elseif any(any_block_has_top) || any(any_block_has_bottom)
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<mislabeled_intact_other_block');
                    elseif height(possible_test_pairs) < (4/3)*(block_study_pairs(idx))
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<incomplete_test>');
                    else
                        mismatch_indices_study{idx} = cat(1, mismatch_indices_study{idx}, jdx);
                    	bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<missing_intact>');
                    end
                
                end
            
            end
        
        end
        
        for jdx = 1:height(paired_retrieval_events)
        
            event = paired_retrieval_events(jdx, :);
            correct_ans = event.correct_ans;
            response = event.response;
            is_correct = event.correct;
            
            if ismember('pressed', fields)
                
                pressed = event.pressed{:};
                
                switch pressed
                    case 'S'
                        comparison = response == 1;
                    
                    case 'R'
                        comparison = response == 2;
                    
                    case 'N'
                        comparison = response == 3;
                    
                    case 'NONE'
                        comparison = response < 1;
                    
                    otherwise
                        comparison = true;
                        mismatch_indices_test{idx} = cat(1, mismatch_indices_test{idx}, jdx);
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<bad_key_press>');                        
                end
                
                if ~comparison
                    mismatch_indices_test{idx} = cat(1, mismatch_indices_test{idx}, jdx);
                    bad_session(idx) = true;
                    reason_bad{idx} = update_reason(reason_bad{idx}, '<pressed_response_mismatch>');
                end
            
            end
            
            if (response == correct_ans && ~is_correct) || (response ~= correct_ans && is_correct)
                mismatch_indices_test{idx} = cat(1, mismatch_indices_test{idx}, jdx);
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<mismatch_correct_test>');
            end
            
        end
        
    else
        bad_session(idx) = true;
        reason_bad{idx} = update_reason(reason_bad{idx}, '<no_shared_blocks>');
    end
    
    if ismember('eegfile', fields) && ismember('eegoffset', fields)
        
        if iscell(events.eegoffset)
            events.eegoffset = cellfun(@str2double, events.eegoffset);
        end
        
        if any(~cellfun(@isempty, events.eegfile) & events.eegoffset > 0)
            is_aligned(idx) = true;
        end
        
        if is_aligned(idx)
            
            unaligned_study_events = cellfun(@isempty, encoding_events.eegfile) | encoding_events.eegoffset <= 0;
            
            if any(unaligned_study_events)
                encoding_events(unaligned_study_events, :) = [];
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<unaligned_study_events>');
            end
            
            unaligned_test_events = cellfun(@isempty, retrieval_events.eegfile) | retrieval_events.eegoffset <= 0;
            
            if any(unaligned_test_events)
                retrieval_events(unaligned_test_events, :) = [];
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<unaligned_test_events>');
            end
            
            if ~isempty(encoding_events)
                
                study_offsets = encoding_events.eegoffset;
                study_offsets = diff(study_offsets);
                study_offsets(study_offsets < 0) = [];
                study_offsets = sort(study_offsets, 'descend');
                
                if n_study_blocks > 1
                    study_offsets(1:n_study_blocks-1) = [];
                end
                
                study_pair_duration(idx) = round(mean(study_offsets)/10)/100;
            
            end
            
            if ~isempty(retrieval_events)
            
                test_offsets = retrieval_events.eegoffset;
                test_offsets = diff(test_offsets);
                test_offsets(test_offsets < 0)= [];
                test_offsets = sort(test_offsets, 'descend');
                
                if n_test_blocks > 1
                    test_offsets(1:n_test_blocks-1) = [];
                end
                
                test_pair_duration(idx) = round(mean(test_offsets)/10)/100;
            
            end
            
            if ~isempty(encoding_events) && ~isempty(retrieval_events)
                
                unique_study_blocks = unique(encoding_events.block);
                unique_test_blocks = unique(retrieval_events.block);
                shared_blocks = unique_study_blocks(ismember(unique_study_blocks, unique_test_blocks));
                temp_shared_blocks = length(shared_blocks);
                
                if temp_shared_blocks > 0
                    
                    temp_study_duration = NaN(temp_shared_blocks, 1);
                    temp_test_duration = NaN(temp_shared_blocks, 1);
                    temp_break_duration = NaN(temp_shared_blocks, 1);
                    
                    for jdx = 1:temp_shared_blocks
                        this_block = shared_blocks(jdx);
                        this_study = encoding_events(encoding_events.block == this_block, :);
                        this_test = retrieval_events(retrieval_events.block == this_block, :);
                        temp_study_duration(jdx) = this_study.eegoffset(end) - this_study.eegoffset(1) + study_pair_duration(idx);
                        temp_break_duration(jdx) = this_test.eegoffset(1) - (this_study.eegoffset(end) + study_pair_duration(idx));
                        temp_test_duration(jdx) = this_test.eegoffset(end) - this_test.eegoffset(1) + test_pair_duration(idx);
                    end
                    
                    temp_study_duration(temp_study_duration < 0 | isnan(temp_study_duration)) = [];
                    temp_break_duration(temp_break_duration < 0 | isnan(temp_break_duration)) = [];
                    temp_test_duration(temp_test_duration < 0 | isnan(temp_test_duration)) = [];
                    
                    if ~isempty(temp_study_duration)
                        study_section_duration(idx) = round(mean(temp_study_duration, 1)/10)/100;
                    end
                    
                    if ~isempty(temp_break_duration)
                        break_duration(idx) = round(mean(temp_break_duration, 1)/10)/100;
                    end
                    
                    if ~isempty(temp_test_duration)
                        test_section_duration(idx) = round(mean(temp_test_duration, 1)/10)/100;
                    end
                    
                end
                
            end
            
            %%% All possible changes needed to be made to eegfile paths listed
            %%% below.
            
            if any(cellfun(@isempty, events.eegfile))
                empty_cells = cellfun(@isempty, events.eegfile);
                events.eegfile(empty_cells) = repelem({''}, sum(empty_cells), 1);
            end
            
            if any(contains(events.eegfile, '/Volumes'))
                events.eegfile = strrep(events.eegfile, '/Volumes', '');
            end
            
            %%% Saving a copy of events to analysis directory with the EEG file
            %%% path switched from reref (common average reference) to noreref so
            %%% that own referencing method can be used.
            
            if any(contains(events.eegfile, {'eeg.reref', 'eeg.bipolar'}))
                events.eegfile = regexprep(events.eegfile, 'eeg.(bipolar|reref)', 'eeg.noreref');
            end
            
            temp_events = events;
            temp_events(cellfun(@isempty, temp_events.eegfile), :) = [];
            unique_recording_files = unique(temp_events.eegfile, 'stable');
            
            n_recordings(idx) = length(unique_recording_files);
            
            if n_recordings(idx) > 1
                bad_session(idx) = true;
                reason_bad{idx} = update_reason(reason_bad{idx}, '<multiple_recordings>');
            end
            
            session_electrodes = electrode_list(electrode_list.session_ID == session_ID(idx), :);
            channel_numbers = unique(session_electrodes.channel_number);
            bipolar_references = unique(vertcat(session_electrodes.bipolar_reference{:}));
            WM_references = unique(vertcat(session_electrodes.WM_reference{:}));
            all_channel_numbers = unique([channel_numbers;bipolar_references;WM_references]);
            
            temp_file_length = NaN(1, n_recordings(idx));
            temp_time_length = NaN(1, n_recordings(idx));
            temp_missing = cell(1, n_recordings(idx));
            
            for jdx = 1:n_recordings(idx)
                
                recording_file = unique_recording_files{jdx};
                
                has_this_file = strcmp(temp_events.eegfile, recording_file);
                this_recording_events = table2struct(temp_events(has_this_file, :));
                
                temp_time_length(jdx) = max([this_recording_events.eegoffset]) - min([this_recording_events.eegoffset]);
                channel_template = [recording_file, '.%03d'];
                channel_files = arrayfun(@(x) sprintf(channel_template, x), all_channel_numbers, 'UniformOutput', false);
                is_missing = ~cellfun(@isfile, channel_files);
                temp_missing{jdx} = session_electrodes.electrode_ID(ismember(session_electrodes.channel_number, all_channel_numbers(is_missing)));
                
                if all(is_missing)
                
                    bad_session(idx) = true;
                    reason_bad{idx} = update_reason(reason_bad{idx}, '<all_channels_missing>');
                
                else
                    
                    not_missing = all_channel_numbers(~is_missing);
                    sample_channel = not_missing(1);
                    temp_eeg = gete(sample_channel, this_recording_events(1), 0);
                    temp_file_length(jdx) = length(temp_eeg{1});
                    
                    if any(is_missing)
                        bad_session(idx) = true;
                        reason_bad{idx} = update_reason(reason_bad{idx}, '<some_channels_missing>');
                    end
                
                end
            
            end
            
            eeg_time_length{idx} = temp_time_length;
            eeg_file_length{idx} = temp_file_length;
            missing_channels{idx} = temp_missing;
            
        else
            bad_session(idx) = true;
            reason_bad{idx} = update_reason(reason_bad{idx}, '<unaligned_session>');
        end
        
    else
    
        bad_session(idx) = true;
        reason_bad{idx} = update_reason(reason_bad{idx}, '<unaligned_session>');
        
    end
    
    if ~strcmp(mode, 'recheck')
        save_path = fullfile(data_directory, this_subject, this_task, this_session);
        
        if ~isfolder(save_path)
            mkdir(save_path);
        end
        
        save(fullfile(save_path, 'events.mat'), 'events');
    end
    
end

events_info = table(subject, task, session, subject_ID, session_ID, ...
    n_electrodes, is_aligned, bad_session, reason_bad, ...
    n_recordings, computer_time_length, eeg_time_length, eeg_file_length, missing_channels, repeated_words, ...
    n_study_blocks, n_test_blocks, n_blocks, n_shared_blocks, n_empty_study_blocks, n_empty_test_blocks, ...
    has_practice, block_study_pairs, total_study_pairs, n_study_intact, n_study_rearranged, ...
    f_response_study, f_correct_study, f_response_correct_study, response_time_study, ...
    block_test_pairs, total_test_pairs, n_test_intact, n_test_rearranged, n_test_new, ...
    f_response_test, f_correct_test, f_response_correct_test, response_time_test, ...
    mismatch_indices_study, mismatch_indices_test, rearranged_across_block_indices, ...
    study_pair_duration, test_pair_duration, study_section_duration, ...
    test_section_duration, break_duration);

if strcmp(mode, 'recheck')
    events_info_recheck = events_info;
    save(fullfile(list_directory, 'events_info_recheck.mat'), 'events_info_recheck');
else
    save(fullfile(list_directory, 'events_info.mat'), 'events_info');
end

end


function reason_bad = update_reason(reason_bad, reason)

if ~contains(reason_bad, reason)
    reason_bad = append(reason_bad, reason);
end

end