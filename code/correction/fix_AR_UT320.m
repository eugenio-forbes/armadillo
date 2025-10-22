%%% Explanation:
%%% New AR control keyboard to key pressed translation:
%%% -A is T for top
%%% -S is B for bottom
%%% -D is empty
%%% -F is N for new
%%% -G is S for same
%%% -H is R for rearranged
%%% Issue: After test interruption, events file is generated.
%%% When generating the file the key presses are translated in the pressed column.
%%% If the testing session was interrupted and restarted from checkpoint,
%%% once the new session ends the events were concatenated and everything
%%% would be reevaluated. 
%%% Early after the control was switched from previous, reevaluation would
%%% cause retrieval events prior to interrupton to have S presses
%%% translated to B for bottom and all other events in encoding and
%%% retrieval would not be recognized as valid responses, then generating a
%%% -999 value in response and inaccurate correct columns.
%%% This was noted, corrected, and fixed.
%%% Fix: B key presses in retrieval are switched back to S and the response
%%% values and correct values are switched to corresponding press.

clc; clearvars; close all; warning off;

subject_directory = '/path/to/armadillo/subject_files';
subject = 'UT320';
task = 'AR';
session = 'session_0';

events_path = fullfile(subjects_directory, subject, 'behavioral', task, session, 'events.mat');
load(events_path, 'events')

events = struct2table(events);

response    = events.response;
pressed     = events.pressed;
correct_ans = events.correct_ans;
correct     = events.correct;
event       = events.event;

is_top = contains(event, 'ENCODING') & strcmp(pressed, 'T');
response(is_top)= ones(sum(is_top), 1);
correct(is_top) = response(is_top) == correct_ans(is_top);

is_bottom = contains(event, 'ENCODING') & strcmp(pressed, 'B');
response(is_bottom)= repmat(2, sum(is_bottom), 1);
correct(is_bottom) = response(is_bottom) == correct_ans(is_bottom);

is_new = contains(event, 'RETRIEVAL') & strcmp(pressed, 'N');
response(is_new)= repmat(3, sum(is_new), 1);
correct(is_new) = response(is_new) == correct_ans(is_new);

is_rearranged = contains(event, 'RETRIEVAL') & strcmp(pressed, 'R');
response(is_rearranged)= repmat(2, sum(is_rearranged), 1);
correct(is_rearranged) = response(is_rearranged) == correct_ans(is_rearranged);

is_same = contains(event, 'RETRIEVAL') & strcmp(pressed, 'B');
response(is_same)= ones(sum(is_same), 1);
correct(is_same) = response(is_same) == correct_ans(is_same);
pressed(is_same) = repelem({'S'}, sum(is_same), 1);

events.pressed  = pressed;
events.response = response;
events.correct  = correct;

events = table2struct(events);

save(events_path, 'events')