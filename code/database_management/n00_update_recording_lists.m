%%% This function will list all Nihon Kohden and Blackrock Neurotech raw recording files
%%% present in a subject's directory. Based on a saved recording list it will determine
%%% which files have not been processed (split into individual files for each recorded channel).
%%% Unsplit recordings will be split and in the process, recording information 
%%% (such as recording length and sampling rate) will be gathered to add to the recording lists.

function n00_update_recording_lists(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories
list_directory         = fullfile(analysis_directory, 'lists');
subject_directory      = fullfile(analysis_directory, 'subject_files', subject);
nihon_kohden_directory = fullfile(subject_directory, 'raw/nihon_kohden');
blackrock_directory    = fullfile(subject_directory, 'raw/blackrock');
nihon_kohden_list_file = fullfile(list_directory, 'nihon_kohden_list.mat');
blackrock_list_file    = fullfile(list_directory, 'blackrock_list.mat');

%%% Macs generate trash files adding these strings to good file names. To remove in a search.
bad_file_patterns = {'._', '~'};

%%% Make a list of all .EEG Nihon Kohden files present in subject's raw recording directory
nihon_kohden_files = dir(fullfile(nihon_kohden_directory, '*/*.EEG'));
bad_files = contains({nihon_kohden_files.name}, bad_file_patterns);
nihon_kohden_files(bad_files) = [];

[nihon_kohden_folders, unique_indices, ~] = unique({nihon_kohden_files.folder});
nihon_kohden_folders = strrep(nihon_kohden_folders, nihon_kohden_directory, '');
nihon_kohden_files = {nihon_kohden_files.name};
nihon_kohden_files = nihon_kohden_files(unique_indices);

%%% From saved recording list, check which .EEG files have not been split
%%% Split unsplit recordings and add recording information to list

if ~isempty(nihon_kohden_files)

    nihon_kohden_stems = strrep(nihon_kohden_files, '.EEG', '');
    
    if isfile(nihon_kohden_list_file)
        
        load(nihon_kohden_list_file, 'nihon_kohden_list');
        
        split_recordings = nihon_kohden_list.file_name;
        unsplit = ~ismember(nihon_kohden_stems, split_recordings);
        unsplit_folders = nihon_kohden_folders(unsplit);
        
        n_unsplit = sum(unsplit);
        max_recording_ID = max(nihon_kohden_list.recording_ID);
        
    else
    
        nihon_kohden_list = [];
        n_unsplit = length(nihon_kohden_stems);
        unsplit_folders = nihon_kohden_folders;
        
        max_recording_ID = 0;
        
    end
    
    nihon_kohden_rows = cell(n_unsplit, 1);
    
    for idx = 1:n_unsplit
    
        this_folder = unsplit_folders{idx};
        delimiter = strfind(this_folder, '_');
        task = this_folder(1:delimiter(1) - 1);
        session = this_folder(delimiter(1) + 1:end);
        
        nihon_kohden_rows{idx} = split_nihon_kohden_EEG(analysis_directory, subject, task, session);
        
        if ~isempty(nihon_kohden_rows{idx})
            
            n_rows = height(nihon_kohden_rows{idx});
            new_IDs = (max_recording_ID + 1):(max_recording_ID + n_rows);
            
            nihon_kohden_rows{idx}.recording_ID = new_IDs';
            max_recording_ID = max_recording_ID + n_rows;
            
        end
        
    end

    nihon_kohden_rows = vertcat(nihon_kohden_rows{:});
    
    nihon_kohden_list = [nihon_kohden_list; nihon_kohden_rows];
    
    save(nihon_kohden_list_file, 'nihon_kohden_list');
    
end

%%% Make a list of all .ns2 Blackrock Neurotech files present in subject's raw recording directory
blackrock_files = dir(fullfile(blackrock_directory, '**/*.ns2'));
bad_files = contains({blackrock_files.name}, bad_file_patterns);
blackrock_files(bad_files) = [];

[blackrock_folders, unique_indices, ~] = unique({blackrock_files.folder});
blackrock_folders = strrep(blackrock_folders, blackrock_directory, '');

blackrock_files = {blackrock_files.name};
blackrock_files = blackrock_files(unique_indices);

%%% From saved recording list, check which .ns2 files have not been split
%%% Split unsplit recordings and add recording information to list

if ~isempty(blackrock_files)

    blackrock_stems = strrep(blackrock_files, '.ns2', '');
    
    if isfile(blackrock_list_file)
        
        load(blackrock_list_file, 'blackrock_list');
        
        split_recordings = blackrock_list.file_name;
        unsplit = ~ismember(blackrock_stems, split_recordings);
        unsplit_folders = blackrock_folders(unsplit);
        
        n_unsplit = sum(unsplit);
        
        max_recording_ID = max(blackrock_list.recording_ID);
    
    else
    
        blackrock_list = [];
        n_unsplit = length(blackrock_stems);
        unsplit_folders = blackrock_folders;
        
        max_recording_ID = 0;
    
    end
    
    blackrock_rows = cell(n_unsplit, 1);
    
    for idx = 1:n_unsplit
    
        this_folder = unsplit_folders{idx};
        delim = strfind(this_folder, '/');
        session = this_folder(delim(1)+1:end);
        
        blackrock_rows{idx} = split_blackrock_EEG(analysis_directory, subject, session);
        
        if ~isempty(blackrock_rows{idx})
        
            n_rows = height(blackrock_rows{idx});
            new_IDs = (max_recording_ID + 1):(max_recording_ID + n_rows);
            
            blackrock_rows{idx}.recording_ID = new_IDs';
            
            max_recording_ID = max_recording_ID + n_rows;
            
        end
        
    end
    
    blackrock_rows = vertcat(blackrock_rows{:});
    
    blackrock_list = [blackrock_list; blackrock_rows];
    
    save(blackrock_list_file, 'blackrock_list');
    
end

end