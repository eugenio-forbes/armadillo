%%% This function will loop through a subject's respective sessions,
%%% and count number of sync pulses in Nihon Kohden and/or Blackrock
%%% recordings if available. Session list is updated with this information.

function n00_check_sync_pulses(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end


%%% Declare directories
list_directory = fullfile(analysis_directory, 'lists');

%%% Load session list and determine indices of sessions corresponding to subject
session_list_file = fullfile(list_directory, 'session_list.mat');
load(session_list_file, 'session_list');

list_indices = find(strcmp(session_list.subject, subject));

%%% Loop through sessions and detect sync pulses in Nihon Kohden and/or Blackrock recordings
n_sessions = length(list_indices);

for idx = 1:n_sessions

    list_index = list_indices(idx);
    this_session = session_list(list_index, :);
    
    has_nihon_kohden = this_session.has_nihon_kohden;
    has_nihon_kohden_sync = this_session.has_nihon_kohden_sync{:};
    n_pulses_nihon_kohden = this_session.n_pulses_nihon_kohden{:};

    if has_nihon_kohden && any(has_nihon_kohden_sync) && isempty(n_pulses_nihon_kohden)
        this_session = detect_sync_pulses(analysis_directory, this_session, 'nihon_kohden');
    end
    
    has_blackrock = this_session.has_blackrock;
    has_blackrock_sync = this_session.has_blackrock_sync{:};
    n_pulses_blackrock = this_session.n_pulses_blackrock{:};

    if has_blackrock && any(has_blackrock_sync) && isempty(n_pulses_blackrock)
        this_session = detect_sync_pulses(analysis_directory, this_session, 'blackrock');
    end

    session_list(list_index, :) = this_session;
    
end

%%% Save updated session list
save(session_list_file, 'session_list');

end