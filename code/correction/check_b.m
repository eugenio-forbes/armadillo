data_directory = '/path/to/armadillo/data';

n_sessions = height(session_list);
missing_B = false(n_sessions,1);

for idx = 1:n_events

    subject = session_list.subject{idx};
    task    = session_list.task{idx};
    session = session_list.session{idx};
    
    events_file = fullfile(data_directory,subject,task,session,'events.mat');
    load(events_file,'events');
    
    if isstruct(events)
        events = struct2table(events);
    end
    
    variable_names = events.Properties.VariableNames;
    
    if ismember('pressed',variable_names)
        missing_B(idx) = ~any(strcmp(events.pressed,'B'));
    else
        missing_B(idx) = ~any(contains(events.event,'ENC') & events.response == 2);
    end
    
end

session_list.missing_B = missing_B;