key_file = '/path/to/aramdillo/subject_files/UT155/behavioral/AR/session_0/keyboard_old.keylog';

opts = delimitedTextImportOptions("NumVariables", 4);
opts.DataLines = [1, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["time", "dontknow", "press_type", "key_pressed"];
opts.VariableTypes = ["double", "double", "char", "char"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["press_type", "key_pressed"], "EmptyFieldRule", "auto");

% Import the data

key_table= readtable("/path/to/armadillo/subject_files/UT155/behavioral/AR/session_0/keyboard_old.keylog", opts);
key_table = key_table(ismember(key_table.press_type, {'P'}), :);
key_table = key_table(ismember(key_table.key_pressed, {'H', 'J', 'K', 'M'}), :);

replacement_table = key_table;

events_file = '/path/to/armadillo/subject_files/UT155/behavioral/AR/session_0/events.mat';
load(events_file, 'events');
events = struct2table(events);
n_events = height(events);

for idx = 1:n_events-1
    
    event_type  = events.event{idx};
    start_time  = events.mstime(idx);
    finish_time = events.mstime(idx + 1);
    correct_ans = str2double(events.correct_ans{idx});
    
    if contains(event_type, 'ENCODING')
    
        rows_within_time = key_table.time > start_time & key_table.time < finish_time;
        keylog = key_table(rows_within_time, :);
        
        if ~isempty(keylog)
        
            if sum(rows_within_time) > 1
            
                unique_keys = unique(keylog.key_pressed);
            
                if length(unique_keys) > 1
                    keylog = keylog(end, :);
                else
                    keylog = keylog(1, :);
                end
            
            end
            
            key_pressed = keylog.key_pressed{:};
            press_time = keylog.time;
            events.mstime_toResp(idx) = int64(press_time - start_time);
            
            switch key_pressed
                case 'K'
                    events.response(idx) = int32(1);
                    events.correct(idx) = int32(correct_ans == 1);
            
                case 'M'
                    events.response(idx) = int32(2);
                    events.correct(idx) = int32(correct_ans == 2);
            
                otherwise
                    events.response(idx) = int32(-1);
                    events.correct(idx) = int32(-1);
                    events.mstime_toResp(idx) = int64(-1);
            end
        
        else
            events.response(idx) = int32(-1);
            events.correct(idx) = int32(-1);
            events.mstime_toResp(idx) = int64(-1);
        end
    
    end
    
    if contains(event_type, 'RETRIEVAL')
    
        rows_within_time = key_table.time > start_time & key_table.time < finish_time;
        keylog = key_table(rows_within_time, :);
    
        if ~isempty(keylog)
    
            if sum(rows_within_time) > 1
    
                unique_keys = unique(keylog.key_pressed);
    
                if length(unique_keys) > 1
                    keylog = keylog(end, :);
                else
                    keylog = keylog(1, :);
                end
    
            end
    
            key_pressed = keylog.key_pressed{:};
            press_time = keylog.time;
            events.mstime_toResp(idx) = int64(press_time - start_time);
    
            switch key_pressed
                case 'H'
                    events.response(idx) = int32(3);
                    events.correct(idx) = int32(correct_ans == 3);
    
                case 'J'
                    events.response(idx) = int32(1);
                    events.correct(idx) = int32(correct_ans == 1);
    
                case 'K'
                    events.response(idx) = int32(2);
                    events.correct(idx) = int32(correct_ans == 2);
    
                otherwise
                    events.response(idx) = int32(-1);
                    events.correct(idx) = int32(-1);
                    events.mstime_toResp(idx) = int64(-1);
            end
    
        else
            events.response(idx) = int32(-1);
            events.correct(idx) = int32(-1);
            events.mstime_toResp(idx) = int64(-1);
        end
    
    end
    
end

events = table2struct(events);
save(events_file, 'events');