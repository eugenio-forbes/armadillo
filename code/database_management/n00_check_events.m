function n00_check_events(analysis_directory, subject)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories
list_directory = fullfile(analysis_directory, 'lists');

%%% Load session information table, get rows corresponding to subject, get session IDs for sessions with injections
session_list_file = fullfile(list_directory, 'session_list.mat');
load(session_list_file, 'session_list');

list_indices = find(strcmp(session_list.subject, subject));
session_IDs = session_list.session_ID(list_indices);
injection_IDs = session_IDs(session_list.has_injection(list_indices));

%%% Loop through sessions, process unified events files with adjusted computer times
%%% based on alignment results and client-server communications.

n_sessions = length(list_indices);

for idx = 1:n_sessions

    list_index = list_indices(idx);
    this_session = session_list(list_index, :);
    
    if this_session.nihon_kohden_aligned
        n00_process_events(analysis_directory, this_session, 'nihon_kohden', injection_IDs);
    end
    
    if this_session.blackrock_aligned
        n00_process_events(analysis_directory, this_session, 'blackrock', injection_IDs);
    end
    
end

%%% Save updated session list
save(session_list_file, 'session_list');

end