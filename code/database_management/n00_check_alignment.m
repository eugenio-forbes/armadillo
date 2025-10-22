%%% This function get's session information from saved session list for a given subject.
%%% Based on whether the session has associated Nihon Kohden or Blackrock recordings,
%%% whether the recordings contain sync pulse data, and success of previous alignment
%%% attempts; it will attempt alignment of behavioral data to each recording system
%%% using available sync pulses. Alignment results are saved for eventual file processing.
%%% Session list is updated and saved with alignment information.

function n00_check_alignment(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end


%%% Declare directories
list_directory = fullfile(analysis_directory, 'lists');

%%% Load session list and get session information corresponding to subject
session_list_file = fullfile(list_directory, 'session_list.mat');
load(session_list_file, 'session_list');
list_indices = find(strcmp(session_list.subject, subject));

%%% Loop through sessions; align behavioral data to corresponding recordings using sync pulse data

n_sessions = length(list_indices);

for idx = 1:n_sessions
    
    list_index = list_indices(idx);
    this_session = session_list(list_index, :);
    
    has_nihon_kohden      = this_session.has_nihon_kohden;
    nihon_kohden_aligned  = this_session.nihon_kohden_aligned;
    n_pulses_nihon_kohden = sum(this_session.n_pulses_nihon_kohden{:});
    
    alignment_successful  = false;
    
    if has_nihon_kohden && ~nihon_kohden_aligned && n_pulses_nihon_kohden > 0
        
        [alignment_successful, alignment_info] = n00_align_sync_pulses(analysis_directory, this_session, 'nihon_kohden');
        
        if alignment_successful
            
            n_pulses_match = alignment_info.n_pulses_match;
            R2             = alignment_info.R2;
            
            if n_pulses_match && R2 > 0.99999999
                this_session.nihon_kohden_aligned = true;
            else
                alignment_successful = false;
            end
        
        end
    
    end

    has_blackrock = this_session.has_blackrock;
    blackrock_aligned = this_session.blackrock_aligned;
    n_pulses_blackrock = sum(this_session.n_pulses_blackrock{:});
    
    alignment_successful = false;
    
    if has_blackrock && ~blackrock_aligned && n_pulses_blackrock > 0
    
        [alignment_successful, alignment_info] = n00_align_sync_pulses(analysis_directory, this_session, 'blackrock');
        
        if alignment_successful
            
            n_pulses_match = alignment_info.n_pulses_match;
            R2             = alignment_info.R2;
            
            if n_pulses_match && R2 > 0.99999999
                this_session.blackrock_aligned = true;
            else
                alignment_successful = false;
            end
        
        end
    
    end

    this_session.is_aligned = this_session.blackrock_aligned || this_session.nihon_kohden_aligned;

    session_list(list_index, :) = this_session;
    
end

%%% Save updated session list
save(session_list_file, 'session_list');

end