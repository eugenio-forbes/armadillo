function all_events = n00_get_all_events(data_directory, events_info)

n_sessions = height(events_info);

subject = events_info.subject;
task    = events_info.task;
session = events_info.session;

all_events = cell(n_sessions, 1);

max_block_ID = 0;
max_event_ID = 0;

for idx = 1:n_sessions
    
    events_file = fullfile(data_directory, subject{idx}, task{idx}, session{idx}, 'events.mat');
    load(events_file, 'events')
    
    events.block_ID = events.block_ID + max_block_ID;
    events.event_ID = events.event_ID + max_event_ID;
    
    max_block_ID = max(events.block_ID);
    max_event_ID = max(events.event_ID);
    
    all_events{idx} = events;
    
end

all_events = vertcat(all_events{:});

end