function adjust_SR_events(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder_name = 'armadillo';
    subject = 'SC000';
    task = 'SR1';
    session = 'session_0';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder_name = varargin{3};
    subject = varargin{4};
    task = varargin{5};
    session = varargin{6};
end

%%% List directories
analysis_directory = fullfile(root_directory, username, analysis_folder_name);
%data_directory = fullfile(analysis_directory, 'data');
data_directory = fullfile(analysis_directory, 'configurations');

events_file = fullfile(data_directory, subject, 'behavioral', task, session, 'events.mat');
load(events_file, 'events');
events = struct2table(events);

unaligned_events = arrayfun(@isempty, events.eegoffset) | strcmp(events.eegfile, '');
events(unaligned_events, :) = [];

last_completed = find(strcmp(events.type, 'REC_STOP'), 1, 'last');
last_list = events.list(last_completed);
exceeding = events.list > last_list;
events(exceeding, :) = [];

lists = unique(events.list);
n_lists = length(lists);

event_types = events.type;
is_encoding = strcmp(event_types, 'WORD');
events.type(is_encoding) = repelem({'ENCODING'}, sum(is_encoding), 1);

events.block = arrayfun(@(x) floor(x / 3), events.list);

is_retrieval_start = strcmp(event_types, 'REC_START');
is_retrieval_end = strcmp(event_types, 'REC_STOP');
starts = unique(events.eegoffset(is_retrieval_start));
ends = unique(events.eegoffset(is_retrieval_end));

for idx = 1:n_lists

    is_list = events.list == lists(idx);
    
    targets = is_list & is_retrieval_start;
    n_targets = sum(targets);
    
    start_time = starts(idx);
    end_time = ends(idx);
    
    new_offsets = floor(linspace(start_time, end_time, n_targets+1));
    new_offsets = new_offsets(1:n_targets);
    
    events.eegoffset(targets) = new_offsets;

end

events.type(is_retrieval_start) = repelem({'RETRIEVAL'}, sum(is_retrieval_start), 1);
events(is_retrieval_end, :) = [];

events = table2struct(events);
save(events_file, 'events');

end