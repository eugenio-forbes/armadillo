%%% This function will gather lists of electrodes for every session,
%%% based on saved session list, to update and save electrode list.
%%% Localization information for any subject may be updated at any time,
%%% so looping through every session.

function n00_update_electrode_list(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
end


%%% Declare directories
list_directory = fullfile(analysis_directory, 'lists');
session_list_file = fullfile(list_directory, 'session_list.mat');
electrode_list_file = fullfile(list_directory, 'electrode_list.mat');


%%% Load saved session and electrode lists
load(session_list_file, 'session_list');

n_sessions = height(session_list);

if isfile(electrode_list_file)
    load(electrode_list_file, 'electrode_list');
    session_IDs = unique(electrode_list.session_ID);
    not_included = ~ismember(session_list.session_ID, session_IDs);
    max_electrode_ID = max(electrode_list.electrode_ID);
else
    electrode_list = [];
    session_IDs = [];
    not_included = true(n_sessions, 1);
    max_electrode_ID = 0;
end

session_list = session_list(:, {'subject', 'task', 'session', 'subject_ID', 'session_ID'});

electrode_rows = cell(n_sessions, 1);

for idx = 1:n_sessions
    
    this_session = session_list(idx, :);
    
    [electrode_rows{idx}, findings] = n00_get_session_electrodes(analysis_directory, this_session);
    
    locations_determined = findings.locations_determined;
    has_auto             = findings.has_auto;
    has_glasser          = findings.has_glasser;
    has_coordinates      = findings.has_coordinates;
    
    if not_included(idx)
    
        if ~isempty(electrode_rows{idx})
            n_electrodes = height(electrode_rows{idx});
            new_IDs = (max_electrode_ID + 1):(max_electrode_ID + n_electrodes);
            max_electrode_ID = max_electrode_ID + n_electrodes;
            electrode_rows{idx}.electrode_ID = new_IDs';
        end
        
    else
    
        has_session_ID = session_IDs == this_session.session_ID;
        list_indices = find(has_session_ID);
        
        if locations_determined
            electrode_list.neurologist_location(list_indices) = electrode_rows{idx}.neurologist_location;
        end
        
        if has_auto
            electrode_list.automatic_location(list_indices) = electrode_rows{idx}.automatic_location;
        end
        
        if has_glasser
            electrode_list.glasser_location(list_indices) = electrode_rows{idx}.glasser_location;
        end
        
        if has_coordinates
            electrode_list.coordinates(list_indices) = electrode_rows{idx}.coordinates;
        end
        
    end
    
end

electrode_rows = vertcat(electrode_rows{not_included});

electrode_list = [electrode_list; electrode_rows];

save(electrode_list_file, 'electrode_list');

end