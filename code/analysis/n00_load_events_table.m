function events_table = n00_load_events_table(data_directory, subject, task, session)

events_file = fullfile(data_directory, subject, task, session, 'events_table.mat');

load(events_file, 'events_table');

end