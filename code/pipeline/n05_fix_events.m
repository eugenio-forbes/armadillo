function n05_fix_events(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
list_directory = fullfile(analysis_directory, 'lists');
data_directory = fullfile(analysis_directory, 'data');

load(fullfile(list_directory, 'events_info.mat'), 'events_info');
load(fullfile(list_directory, 'electrode_list.mat'), 'electrode_list');

electrode_session_IDs = electrode_list.session_ID;
electrode_IDs = electrode_list.electrode_ID;

%%% Loop through sessions to load events files, change EEG file to current
%%% noreref folder path, and correct any errors in the files. Initialize
%%% table columns for events file information to be able to identify events
%%% files that might need to be realigned, and to exclude subjects with
%%% incomplete sessions.

n_sessions = height(events_info);
removed_session = false(n_sessions, 1);
reason_session_removed = repelem({''}, n_sessions, 1);
removed_electrodes = false(n_sessions, 1);
electrodes_removed = cell(n_sessions, 1);
n_electrodes_removed = zeros(n_sessions, 1);
removed_blocks = false(n_sessions, 1);
n_blocks_removed = zeros(n_sessions, 1);

%%% Initialize parpool
pool_object = gcp('nocreate');
if isempty(pool_object)
    parpool(24);
end

rearranged_different = {'UT217', 'UT220', 'UT224', 'UT225', 'UT228', 'UT229', 'UT231', 'UT232'};
%%% For these subjects, the word pairs were rearranged in such a way that
%%% more than half of all rearranged pairs had a word presented in a
%%% different test block, thus it wouldn't be rearranged, it would be
%%% seminew.

bad_subjects = {'UT062', 'UT085', 'UT096', 'UT105', 'UT111', 'UT147', 'UT171', 'UT178', ...
    'UT184', 'UT187', 'UT204', 'UT205', 'UT269', 'UT316', 'UT365', 'UT372', 'UT373', 'UT394'};
%%% UT062 didn't really do task.
%%% UT085 didn't really do task because feeling unwell.
%%% UT096 subject was not feeling well and quit after practice
%%% UT105 sync pulses did not log in eeglog file.
%%% UT111 note of subject appearing to be pushing buttons at random
%%% UT147 Subject wasn't really paying attention and was sleepy
%%% UT171 subject missed more than half of responses and less than a third
%%% were correct. Notes about it.
%%% UT178 patient was not feeling well and sounds like test execution was
%%% very poor.
%%% UT184 didn't complete even practice test.
%%% UT187 Complaint about micros cart noise making patient dizzy, recording
%%% split into 4 fragments, subject missed more than half responses and
%%% less than third correct.
%%% UT204 only completed practice, but missed a lot of responses in test
%%% and in the notes states that subject was falling asleep and visibly
%%% tired and would switch from pressing NSR to TB??? It was not aligned and
%%% EEG was not downloaded.
%%% UT205 was really tired and missed more than half of responses with
%%% close to a third correct.
%%% UT269 had been sleep deprived, many distractions during both tests, and
%%% had pulled out electrodes.
%%% UT316 some weird stuff in all 4 sessions (sleep
%%% deprived/hallucinations?/bad coordination/task too hard/symptom monitoring)
%%% UT365 testing incomplete, with interruptions, seizures and sync error
%%% UT372 would only press one key each session
%%% UT373 no logged responses
%%% UT394 had not been pressing correct keys

questionable_subjects = {'UT075', 'UT076', 'UT081', 'UT087', 'UT092', 'UT118', ...
    'UT128', 'UT139', 'UT149', 'UT155', 'UT159''UT172', 'UT173', 'UT190', 'UT199', ...
    'UT284', 'UT289', 'UT292', 'UT311', 'UT312', 'UT330', 'UT331', 'UT337', 'UT394'};
%%% UT075 phone ringing and sublclinical events throughout session
%%% UT076 struggling with instructions, button press with left hand, distractions
%%% UT081 test 2 potentially affected by medication administration
%%% UT087 test 2 potentially affected by medication administration
%%% UT092 note of subject not feeling well at the end
%%% UT118 Part of block 1 had been started in session_0, restarted in
%%% session 1 (block 0 session 1). Block 2 only study. Glitches in practice
%%% UT128 feeling unwell at end of test and then had seizure
%%% UT139 had a headache and quit in session_0 before block 2
%%% UT149 many sittings, only included 1st one because everything else got
%%% repeated, struggling at practice and block 2 incomplete. Only block 1
%%% might be good.
%%% UT155 had to get responses from keylog file. Seems accurate but many
%%% early responses
%%% UT159 had to get responses from keylog file. Seems accurate and not too
%%% many early responses
%%% UT172 Missed a lot of responses. Thought most were new. Notes about it.
%%% UT173 only because they're a grid patient and loud snoring throughout but looks good in responses.
%%% UT190 button press in practice test because feeling aura
%%% UT199 dozing off in all sessions although responses might be ok
%%% UT284 had push button event close to the end with no confirmed
%%% discharges or epilleptic activity.
%%% UT289 said had not understood task until after block 1
%%% UT292 in session_1 said had thought rearranged was switching top and
%%% bottom prior to starting
%%% UT311 meds in middle of test 1 AR_stim
%%% UT312 EMU push button in session_0 and parent on phone troughout
%%% session_1
%%% UT330 questionable whether responding during testing and no artifact
%%% UT331 no artifact, stim channel slipped out of jumper, some
%%% distractions
%%% UT337 Did not understand instructions well, would press too early and was
%%% annoyed with only one test after practice

events_count = 0;
block_count = 0;

for idx = 1:n_sessions

    subject = events_info.subject{idx};
    task = events_info.task{idx};
    session = events_info.session{idx};
    session_ID = events_info.session_ID(idx);
    reason_bad = events_info.reason_bad{idx};
    repeated_words = events_info.repeated_words{idx};
    
    events_file = fullfile(data_directory, subject, task, session, 'events.mat');
    load(events_file, 'events')    
    session_electrodes = electrode_session_IDs == session_ID;
    n_starting_blocks = length(unique(events.block));
    
    if ismember(subject, rearranged_different) && ~strcmp(subject, 'UT224') && ~strcmp(session, 'session_1')
        removed_session(idx) = true;
        reason_session_removed{idx} = append(reason_session_removed{idx}, '<rearranged_differently>');
        removed_electrodes(idx) = true;
        electrodes_removed{idx} = electrode_IDs(session_electrodes);
        n_electrodes_removed(idx) = length(electrodes_removed{idx});
    end
    
    if ismember(subject, questionable_subjects)
        removed_session(idx) = true;
        reason_session_removed{idx} = append(reason_session_removed{idx}, '<questionable_session>');
        removed_electrodes(idx) = true;
        electrodes_removed{idx} = electrode_IDs(session_electrodes);
        n_electrodes_removed(idx) = length(electrodes_removed{idx});
    end
    
    if ismember(subject, bad_subjects)
        removed_session(idx) = true;
        reason_session_removed{idx} = append(reason_session_removed{idx}, '<bad_session>');
        removed_electrodes(idx) = true;
        electrodes_removed{idx} = electrode_IDs(session_electrodes);
        n_electrodes_removed(idx) = length(electrodes_removed{idx});
    end
    
    switch subject
        case 'UT076'
            events = remove_blocks(events, [0, 2]);
        
        case {'UT080'}
            events = match_incomplete_block(events, 2);
            %%% UT080 no notes
        
        case {'UT081', 'UT090', 'UT092', 'UT128', 'UT195', 'UT243', 'UT274', 'UT276'}
            events = remove_blocks(events, 2);
            %%% UT081 was getting medications at the end
            %%% UT090 test 2 was accidentally started after task
            %%% had stopped.
            %%% UT092 Wasn't feeling well at the end empty study
            %%% UT128 wasn't feeling well at end and had a seizure
            %%% UT195 no responses logged block 2. Note in run.log
            %%% correct ans 91 filler events?
            %%% UT243 unpaired study plus distraction
            %%% UT274 there was an issue with controller after
            %%% bathroom break following encoding block 2.
            %%% UT276 removed because of errors in math portion and
            %%% restarting of session leading to repeat
        
        case {'UT097', 'UT186'}
            if strcmp(session, 'session_0')
                removed_session(idx) = true;
                electrodes_removed{idx} = find(session_electrodes);
            end
            %%% UT097 was drowsy during the first session only
            %%% UT186 The first session there was a lot of noise, EEG restarts, and
            %%% block 1 study was repeated
        
        case {'UT118'}
            if strcmp(session, 'session_1')
                events = remove_blocks(events, [0, 2]);
            end
        
        case {'UT149'}
            events = remove_blocks(events, [0, 2, 3]);
            %%% Many repeat sessions and block 1 might be the only good
            %%% one
        
        case {'UT105', 'UT119', 'UT140', 'UT190', 'UT192', 'UT217', 'UT225', ...
                'UT235', 'UT261', 'UT293', 'UT337', 'UT385', 'UT394'}
            events = remove_blocks(events, 0);
            %%% UT105 had trouble understanding instructions in practice
            %%% UT119 Pressing wrong buttons in practice test noted
            %%% UT140 Practice had been repeated in saved run.
            %%% UT190 missed half practice test because of push
            %%% button event with no confirmed seizure.
            %%% UT192 Notes of not understanding instructions during practice
            %%% UT217 and UT225 repeated practice
            %%% UT235 used keyboard until test 1
            %%% UT261 trouble with instructions at start
            %%% UT293 interruption in practice study
            %%% UT337 subject only pressed S or R
            %%% UT385 used keyboard in practice
            %%% UT394 didn't press key in practice retrieval
        
        case {'UT224'}
            if strcmp(session, 'session_0')
                events = remove_blocks(events, 3); %%% Distracted
            end
        
        case {'UT229'}
            if strcmp(session, 'session_1')
                events = remove_blocks(events, 0); %%% No logged responses
            end
        
        case {'UT231'}
            if strcmp(session, 'session_0')
                events = remove_blocks(events, 2); %%% Study and test separated by a day
            end
            if strcmp(session, 'session_1')
                events = remove_blocks(events, 0);
            end
        
        case {'UT232'}
            events = remove_blocks(events, 1); %%% Distracted
        
        case {'UT238', 'UT396'}
            events = remove_blocks(events, 4);
            %%% UT238 Only did half of it in session_0 and session_1 it
            %%% was repeated
            %%% UT396 was nodding off
        
        case {'UT248'}
            events = remove_blocks(events, 3);
            %%% Only did half of it in session_0 and session_1 it
            %%% was repeated
        
        case {'UT249', 'UT253', 'UT271'}
            events = remove_blocks(events, 6);
            %%% UT249: Computer died after end of encoding block 6.
            %%% UT253: Computer died after end of encoding block 6.
            %%% UT271: Subject quit task because of headache after
            %%% encoding block 6.
        
        case {'UT265'}
            if strcmp(task, 'AR_stim')
                events = remove_blocks(events, 2:6);
                %%% No logged responses
            end
        
        case {'UT284'}
            if strcmp(task, 'AR_stim')
                events = remove_blocks(events, 2:6);
                %%% No logged responses
            end
        
        case 'UT289'
            events = remove_blocks(events, 0:1);
            %%% Misunderstanding instructions
        
        case 'UT292'
            if strcmp(session, 'session_0')
                events = remove_blocks(events, 0:2);
                %%% Confusion with keys and interruptions
            end
        
        case 'UT297'
            events = remove_blocks(events, [2, 4]);
            %%% Soemthing happened that caused the subject not
            %%% to respond the last third of block 2 retrieval and
            %%% session was interrupted. 4 is unpaired study
        
        case 'UT316'
            if strcmp(task, 'AR') && strcmp(session, 'session_0')
                events = remove_blocks(events, 2);
                %%% UT316 was sleepy and could not complete after
                %%% encoding 2.
            end
        
        case {'UT360'}
            if strcmp(session, 'session_1')
                events = remove_blocks(events, 0);
                %%% No logged responses
            end
        
        case {'UT390'}
            events = remove_blocks(events, [0, 4]);
            %%% UT390 didnt press in practice, closing eyes at end
        
    end
    
    if contains(reason_bad, 'more_than_once') && ~isempty(repeated_words)
        pair_indices = find(contains(events.event, {'ENCODING', 'RETRIEVAL'}));
        word_pairs = events.wp(pair_indices, :);
        split_pairs = cellfun(@(x) strsplit(x, '/'), word_pairs, 'UniformOutput', false);
        split_pairs = vertcat(split_pairs{:});
        top_words = split_pairs(:, 1);
        bottom_words = split_pairs(:, 2);
        contains_repeated_words = ismember(top_words, repeated_words) | ismember(bottom_words, repeated_words);
        events(pair_indices(contains_repeated_words), :) = [];
    end
    
    [n_events, n_blocks] = n00_make_ar_events_table(events, events_info(idx, :), events_count, block_count, data_directory);
    events_count = events_count + n_events;
    block_count = block_count + n_blocks;
    
    save(events_file, 'events');
    
    if n_starting_blocks > n_blocks
        removed_blocks(idx) = true;
        n_blocks_removed(idx) = n_starting_blocks - n_blocks;
    end
    
end

events_changes = events_info(:, {'bad_session', 'reason_bad', 'subject', 'task', ...
    'session', 'subject_ID', 'session_ID', 'missing_channels', 'is_aligned', 'n_blocks', 'n_electrodes'});

events_changes.removed_session        = removed_session;
events_changes.reason_session_removed = reason_session_removed;
events_changes.removed_electrodes     = removed_electrodes;
events_changes.n_electrodes_removed   = n_electrodes_removed;
events_changes.removed_blocks         = removed_blocks;
events_changes.n_blocks_removed       = n_blocks_removed;

save(fullfile(list_directory, 'events_changes.mat'), 'events_changes');

make_exclusions(analysis_directory, events_changes);

end


function events = remove_blocks(events, removed_blocks)

for idx = 1:length(removed_blocks)
    removed_block = removed_blocks(idx);
    events(events.block == removed_block, :) = [];
end

end


function events = match_incomplete_block(events, uneven_block)

n_events = height(events);
all_indices = 1:n_events;

block_indices = find(events.block == uneven_block);
preceding_indices = all_indices<block_indices(1);
succeeding_indices = all_indices>block_indices(end);

block = events(block_indices, :);
preceding_events = events(preceding_indices, :);
succeeding_events = events(succeeding_indices, :);

n_block_events = height(block);
encoding_word_pairs = block.wp(contains(block.event, 'ENCODING'));
retrieval_word_pairs = block.wp(contains(block.event, 'RETRIEVAL'));
bad_indices = false(n_block_events, 1);

for idx = 1:n_block_events
    
    event = block.event{idx};
    
    if contains(event, 'ENCODING')
        
        rearranged = block.rearranged(idx);
        word_pair = block.wp{idx};
        
        if rearranged
            
            words = strsplit(word_pair, '/');
            top_word = [words{1}, '/'];
            bottom_word = ['/', words{2}];
            
            if ~any(contains(retrieval_word_pairs, top_word)) && ~any(contains(retrieval_word_pairs, bottom_word))
                bad_indices(idx) = true;
            end
        
        else
        
            if ~any(strcmp(retrieval_word_pairs, word_pair))
                bad_indices(idx) = true;
            end
            
        end
   
    end
    
    if contains(event, 'RETRIEVAL')
    
        isnew = block.correct_ans(idx) == 3;
        
        if ~isnew
        
            rearranged = block.correct_ans(idx) == 2;
            word_pair = block.wp{idx};
            
            if rearranged
                
                words = strsplit(word_pair, '/');
                top_word = [words{1}, '/'];
                bottom_word = ['/', words{2}];
                
                if ~any(contains(encoding_word_pairs, top_word)) && ~any(contains(encoding_word_pairs, bottom_word))
                    bad_indices(idx) = true;
                end
            
            else
                
                if ~any(strcmp(encoding_word_pairs, word_pair))
                    bad_indices(idx) = true;
                end
            
            end
            
        end
        
    end
    
end

block(bad_indices, :) = [];
events = [preceding_events;block;succeeding_events];

end


function make_exclusions(analysis_directory, events_changes)

electrode_fields = {'subject', 'task', 'session', 'channel_number', 'subject_ID', 'session_ID', 'electrode_ID'};
session_fields = {'subject', 'task', 'session', 'subject_ID', 'session_ID'};
subject_fields = {'subject', 'subject_ID'};

list_directory = fullfile(analysis_directory, 'lists');

load(fullfile(list_directory, 'subject_list'), 'subject_list');
load(fullfile(list_directory, 'session_list'), 'session_list');
load(fullfile(list_directory, 'electrode_list'), 'electrode_list');
exclusion_directory = fullfile(analysis_directory, 'exclusion_lists');

electrode_file = fullfile(exclusion_directory, 'excluded_electrodes.mat');
session_file = fullfile(exclusion_directory, 'excluded_sessions.mat');
subject_file = fullfile(exclusion_directory, 'excluded_subjects.mat');

if isfile(electrode_file)
    load(electrode_file, 'excluded_electrodes')
else
    excluded_electrodes = [];
end

if isfile(subject_file)
    load(subject_file, 'excluded_subjects')
else
    excluded_subjects = [];
end

if isfile(session_file)
    load(session_file, 'excluded_sessions')
else
    excluded_sessions = [];
end

empty_cells = cellfun(@isempty, events_changes.missing_channels);
events_changes.missing_channels(empty_cells) = repelem({{0}}, sum(empty_cells), 1);
events_changes.missing_channels = cellfun(@(x) vertcat(x{:}), events_changes.missing_channels, 'UniformOutput', false);
missing_channels = vertcat(events_changes.missing_channels{:});

if ~isempty(missing_channels)
    
    removed = electrode_list(missing_channels, electrode_fields);
    electrode_list(missing_channels, :) = [];
    removed.reason_for_exclusion = repelem({'<missing_channel>'}, height(removed), 1);
    newly_excluded_electrodes = removed;
    excluded_electrodes = [excluded_electrodes;newly_excluded_electrodes];
    
    potentially_excluded_sessions = unique(newly_excluded_electrodes.session_ID);
    unexcluded_sessions = unique(electrode_list.session_ID);
    actually_excluded = ~ismember(potentially_excluded_sessions, unexcluded_sessions);
    excluded_sessions_IDs = potentially_excluded_sessions(actually_excluded);
    
    if ~isempty(excluded_sessions_IDs)
        newly_excluded_sessions = session_list(ismember(session_list.session_ID, excluded_sessions_IDs), session_fields);
        newly_excluded_sessions.reason_for_exclusion = repelem({'Bad session.'}, height(newly_excluded_sessions), 1);
        excluded_sessions = [excluded_sessions;newly_excluded_sessions];           
    end
    
    potentially_excluded_subjects = unique(newly_excluded_electrodes.subject_ID);
    unexcluded_subjects = unique(electrode_list.subject_ID);
    actually_excluded = ~ismember(potentially_excluded_subjects, unexcluded_subjects);
    excluded_subjects_IDs = potentially_excluded_subjects(actually_excluded);
    
    if ~isempty(excluded_subjects_IDs)
        newly_excluded_subjects = subject_list(ismember(subject_list.subject_ID, excluded_subjects_IDs), subject_fields);
        newly_excluded_subjects.reason_for_exclusion = repelem({'<missing_channels>'}, height(newly_excluded_subjects), 1);
        excluded_subjects = [excluded_subjects; newly_excluded_subjects];       
    end
    
end

reasons_sessions_removed = event_changes.reason_session_removed;
unique_reasons = unique(reasons_sessions_removed);
empty_reasons = cellfun(@(x) strcmp(x, ''), unique_reasons);
unique_reasons(empty_reasons) = [];
n_reasons = length(unique_reasons);

for idx = 1:n_reasons
    
    reason = unique_reasons(idx);
    
    removed_sessions = events_changes(strcmp(reasons_sessions_removed, reason), :);
    removed_electrodes = vertcat(removed_sessions.removed_electrodes{:});
    removed_sessions = removed_sessions.session_ID;
    
    removed = ismember(electrode_list.electrode_ID, removed_electrodes);
    removed = electrode_list(removed, electrode_fields);
    electrode_list(removed_electrodes, :) = [];
    removed.reason_for_exclusion = repelem(reason, height(removed), 1);
    newly_excluded_electrodes = removed;
    excluded_electrodes = [excluded_electrodes; newly_excluded_electrodes];
    
    removed = ismember(session_list.session_ID, removed_sessions);
    removed = session_list(removed, session_fields);
    session_list(removed_electrodes, :) = [];
    removed.reason_for_exclusion = repelem(reason, height(removed), 1);
    newly_excluded_sessions = removed;
    excluded_sessions = [excluded_sessions; newly_excluded_sessions];
    
    potentially_excluded_subjects = unique(newly_excluded_sessions.subject_ID);
    unexcluded_subjects = unique(session_list.subject_ID);
    actually_excluded = ~ismember(potentially_excluded_subjects, unexcluded_subjects);
    excluded_subjects_IDs = potentially_excluded_subjects(actually_excluded);
    
    if ~isempty(excluded_subjects_IDs)
        newly_excluded_subjects = subject_list(ismember(subject_list.subject_ID, excluded_subjects_IDs), subject_fields);
        newly_excluded_subjects.reason_for_exclusion = repelem(reason, height(newly_excluded_subjects), 1);
        excluded_subjects = [excluded_subjects; newly_excluded_subjects];       
    end
    
end

save(electrode_file, 'excluded_electrodes');
save(session_file, 'excluded_sessions');
save(subject_file, 'excluded_subjects');

end