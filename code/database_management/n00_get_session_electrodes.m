%%% This function generates an electrode list given a session information table row.
%%% For the respective subject files with neurologist localization, MNI RAS standardized
%%% coordinates, and automatic localization are used to gather information for each electrode.
%%% Bipolar, laplacian, and white matter references for each channel are also determined.
%%% Outputs a table with electrode information associated to input session information.
%%% Also outputs struct with certain findings about localization to indicate whether
%%% previously added electrodes should have localization information added.

function [session_electrodes, findings] = n00_get_session_electrodes(varargin)
if isempty(varargin)                                                      %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo';                            %%% (character vector) Armadillo folder
    subject = 'SC000';                                                    %%% (character vector) Subject code
    task = 'PS';                                                          %%% (character vector) Task name
    session = '2020-01-01_12-00-00';                                      %%% (character vector) Session date in 'yyyy-mm-dd_hh-mm-ss' format
    subject_ID = 1;                                                       %%% Do not edit
    session_ID = 1;                                                       %%% Do not edit
    session_info = table(subject, task, session, subject_ID, session_ID); %%% Do not edit
else                                                                      %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    session_info = varargin{2};
end

subject = session_info.subject{:};

%%% Initialize output
session_electrodes = [];
locations_determined = false;
has_auto = false;
has_glasser = false;
has_coordinates = false;

%%% Declare directories
base_directory         = '/path/to/base_directory';                                %%% Separate directory with imaging file processing
localization_directory = fullfile(base_directory, 'iEEGxfMRI/Pipeline/5crossref');
coordinates_directory  = fullfile(base_directory, 'iEEGxfMRI/Pipeline/6finalize');
subject_directory      = fullfile(analysis_directory, 'subject_files', subject);

%%% Options to read MNI coordinates .csv file
coordinate_options = delimitedTextImportOptions("NumVariables", 5);
coordinate_options.DataLines = [2, Inf];
coordinate_options.Delimiter = ",";
coordinate_options.VariableNames = ["ElecNumber", "X", "Y", "Z", "Regions"];
coordinate_options.VariableTypes = ["double", "double", "double", "double", "char"];
coordinate_options.ExtraColumnsRule = "ignore";
coordinate_options.EmptyLineRule = "read";
coordinate_options = setvaropts(coordinate_options, "Regions", "EmptyFieldRule", "auto");

%%% Load this subject's depth electrode information (neurologist localization) and local atlas information (automatic).
jacksheet_file = fullfile(subject_directory, 'docs/jacksheet.txt');
depth_electrode_information_file = fullfile(localization_directory, sprintf('sub-%s/%s_depth_el_info.mat', subject, subject));
local_atlas_information_file = fullfile(localization_directory, sprintf('sub-%s/%s_local_atlas_info.mat', subject, subject));

locations_determined = false;

%%% Try to get neurologist electrode localization from depth electrode information file
if isfile(depth_electrode_information_file)
    
    load(depth_electrode_information_file, 'depth_el_info')
    
    %%% Get channel numbers, labels and locations
    %%% Some saved as cell matrix, and some saved as struct
    if isstruct(depth_el_info)
    
        depth_el_info = struct2table(depth_el_info);
        depth_channel_numbers = depth_el_info.elec;
        depth_labels = depth_el_info.contact;
        depth_locations = depth_el_info.recon_label;
        
    elseif iscell(depth_el_info)
    
        depth_channel_numbers = [depth_el_info{:, 1}]';
        depth_labels = depth_el_info(:, 2);
        depth_locations = depth_el_info(:, 3);
        
    end

    locations_determined = ~all(cellfun(@isempty, depth_locations));
    
end

%%% If depth electrode information not present in imaging pipeline, try the one found in docs folder, or use jacksheet and leave neurologist localization empty
if ~locations_determined
    
    depth_electrode_information_file = dir(fullfile(subject_directory, subject, 'docs/*el_inf*.txt'));
    
    depth_file_name = {depth_electrode_information_file.name};
    
    depth_electrode_information_file = depth_electrode_information_file(~contains(depth_file_name, {'._', '~'})); %%% MacOS acces makes these annoying copy files that start with ._
    depth_electrode_information_file = fullfile({depth_electrode_information_file.folder}, {depth_electrode_information_file.name});
    
    if ~isempty(depth_electrode_information_file) && isfile(depth_electrode_information_file{1})
    
        depth_electrode_information_file = depth_electrode_information_file{1};
        
        file_opts = detectImportOptions(depth_electrode_information_file, 'Delimiter', ' ');
        file_opts.DataLines = [1, Inf]; %%% Just to ensure that every line is read
        
        depth_el_info = readtable(depth_electrode_information_file, file_opts);
        
        depth_locations = arrayfun(@(x) strjoin(depth_el_info{x, 3:end}), (1:height(depth_el_info))', 'UniformOutput', false); %%% Labels in this case will be merged because file is space delimited
        
        locations_determined = ~all(cellfun(@isempty, depth_locations));
    
    else
    
        file_opts = detectImportOptions(jacksheet_file, 'Delimiter', ' ');
        file_opts.DataLines = [1, Inf];
                
        depth_el_info = readtable(jacksheet_file, file_opts);
        
        n_locations = height(depth_el_info);
        
        depth_locations = repelem({'<undetermined>'}, n_locations, 1);
    
    end
    
    depth_channel_numbers = depth_el_info{:, 1};
    depth_labels = depth_el_info{:, 2};

end

%%% Standardize neurologist localization if information is found
if locations_determined
    depth_locations = n00_correct_electrode_labels(depth_locations);
end

hits = ~contains(depth_labels, {'ECG', 'EKG', 'DC', 'BP', 'OUT'});

%%% Use automatic localization information for initial matches
%%% Missing for a few subjects
if isfile(local_atlas_information_file)

    load(local_atlas_information_file, 'local_atlas_info');
    
    local_atlas_info = struct2table(local_atlas_info);

    automatic_channel_numbers = local_atlas_info.elec;
    automatic_locations = local_atlas_info.AAL_label;
    glasser_locations = local_atlas_info.Glasser_label;
    
    location_indices = arrayfun(@(x) find(automatic_channel_numbers == x), depth_channel_numbers(hits));
    automatic_location = automatic_locations(location_indices);
    glasser_location = glasser_locations(location_indices);
    
    has_auto = true;
    has_glasser = true;

else

    automatic_location = repelem({'<undetermined>'}, sum(hits), 1);
    glasser_location = repelem({'<undetermined>'}, sum(hits), 1);
    
end

%%% Filter channel numbers, labels, and locations
channel_number = depth_channel_numbers(hits);
label = depth_labels(hits);
neurologist_location = depth_locations(hits);

%%% If there were matches, add information about longitudinal location, hemisphere, reference channel number and type, and MNI coordinates

if ~isempty(channel_number)

    n_channel_numbers = length(channel_number);
    
    cell_array = cell(n_channel_numbers, 1);
    zero_array = zeros(n_channel_numbers, 1);
    false_array = false(n_channel_numbers, 1);
    
    hemisphere                   = cell_array;
    bipolar_reference_channels   = zero_array;
    laplacian_reference_channels = cell_array;
    WM_reference_channels        = cell_array;
    has_WM_reference             = false_array;
    has_somewhat_WM_reference    = false_array;
    has_bipolar_reference        = false_array;
    has_laplacian_reference      = false_array;
    coordinates                  = cell_array;
    
    %%% Get 3D coordinates from MNI RAS coordinates file
    MNI_coordinates_file = fullfile(coordinates_directory, sprintf('sub-%s/sub-%s_MNIRAS.csv', subject, subject));
    if isfile(MNI_coordinates_file)
        MNI_coordinates_table = readtable(MNI_coordinates_file, coordinate_options);
        MNI_channel_numbers = MNI_coordinates_table.ElecNumber;
        MNI_coordinates = [MNI_coordinates_table.X, MNI_coordinates_table.Y, MNI_coordinates_table.Z];
        has_coordinates = true;
    end
    
    %%% Loop through channels to get information specific for each
    for jdx = 1:n_channel_numbers
        
        this_label = label{jdx};
        label_stem = regexprep(this_label, '\d*', '');
        this_label_number = str2double(strrep(this_label, label_stem, ''));
        this_location = neurologist_location{jdx};
        this_channel_number = channel_number(jdx);
        
        if contains(this_location, {'LEFT', 'RIGHT'})
        
            if contains(this_location, 'LEFT')
                
                hemisphere{jdx} = 'left';
                
                this_location = regexprep(this_location, '(\w{3, })\s?LEFT', '$1');
                this_location = regexprep(this_location, 'LEFT\s?(\w{3, })', '$1');
                this_location = regexprep(this_location, 'LEFT\s?WM', 'WM');
                
                neurologist_location{jdx} = this_location;
            
            else
                
                hemisphere{jdx} = 'right';
                
                this_location = regexprep(this_location, '(\w{3, })\s?RIGHT', '$1');
                this_location = regexprep(this_location, 'RIGHT\s?(\w{3, })', '$1');
                this_location = regexprep(this_location, 'RIGHT\s?WM', 'WM');
                
                neurologist_location{jdx} = this_location;
            
            end
            
        else
        
            if strcmp(this_label(1), 'L')
                hemisphere{jdx} = 'left';
            elseif strcmp(this_label(1), 'R')
                hemisphere{jdx} = 'right';
            else
                hemisphere{jdx} = 'check';
            end
            
        end
        
        %%% Get indices of depth electrode info file of channels that have the same label stem as this channel.
        same_depth_electrode_indices = find(contains(depth_labels, label_stem));
        
        if ~isempty(same_depth_electrode_indices)
            
            same_depth_channel_numbers = depth_channel_numbers(same_depth_electrode_indices);
            
            same_depth_locations = depth_locations(same_depth_electrode_indices);
            same_depth_locations = strrep(same_depth_locations, ' ', '');
            
            same_depth_labels = depth_labels(same_depth_electrode_indices);
            
            same_depth_label_numbers = strrep(same_depth_labels, label_stem, '');
            same_depth_label_numbers = cellfun(@str2double, same_depth_label_numbers);
            
            max_label_number = max(same_depth_label_numbers);
            min_label_number = min(same_depth_label_numbers);
            
            if this_label_number == min_label_number %%% Meaning it is the innermost channel
            
                next_adjacent_idx = find(same_depth_label_numbers == this_label_number + 1);
                
                if ~isempty(next_adjacent_idx)
                    bipolar_reference_channels(jdx) = same_depth_channel_numbers(next_adjacent_idx);
                    has_bipolar_reference(jdx) = true;
                    laplacian_reference_channels{jdx} = same_depth_channel_numbers(next_adjacent_idx);
                    has_laplacian_reference(jdx) = true;
                end
                
            elseif this_label_number > min_label_number && this_label_number < max_label_number
            
                next_adjacent_idx = find(same_depth_label_numbers == this_label_number + 1);
                previous_adjacent_idx = find(same_depth_label_numbers == this_label_number - 1);
                
                if ~isempty(next_adjacent_idx)
                    bipolar_reference_channels(jdx) = same_depth_channel_numbers(next_adjacent_idx);
                    has_bipolar_reference(jdx) = true;
                end
                
                if ~isempty(next_adjacent_idx) && ~isempty(previous_adjacent_idx)
                    laplacian_reference_channels{jdx} = [same_depth_channel_numbers(previous_adjacent_idx);same_depth_channel_numbers(next_adjacent_idx)];
                    has_laplacian_reference(jdx) = true;
                elseif ~isempty(next_adjacent_idx)
                    laplacian_reference_channels{jdx} = same_depth_channel_numbers(next_adjacent_idx);
                    has_laplacian_reference(jdx) = true;
                elseif ~isempty(previous_adjacent_idx)
                    laplacian_reference_channels{jdx} = same_depth_channel_numbers(previous_adjacent_idx);
                    has_laplacian_reference(jdx) = true;  
                end
                
            elseif this_label_number == max_label_number
            
                previous_adjacent_idx = find(same_depth_label_numbers == this_label_number - 1);
                
                if ~isempty(next_adjacent_idx) && ~isempty(previous_adjacent_idx)
                    laplacian_reference_channels{jdx} = same_depth_channel_numbers(previous_adjacent_idx);
                    has_laplacian_reference(jdx) = true;
                end 
            
            end
            
            if any(strcmp(same_depth_locations, 'WM')) %%% Get channel number of deepest WM contact of same depth electrode if available
                has_WM_reference(jdx) = true;
                white_matter_indices = strcmp(same_depth_locations, 'WM');
                WM_reference_channels{jdx} = same_depth_channel_numbers(white_matter_indices);
            elseif any(contains(same_depth_locations, 'WM'))
                has_somewhat_WM_reference(jdx) = true;
                white_matter_indices = contains(same_depth_locations, 'WM');
                WM_reference_channels{jdx} = same_depth_channel_numbers(white_matter_indices);
            else
                WM_reference_channels{jdx} = laplacian_reference_channels{jdx};
            end
            
            clear same_depth_channel_numbers same_depth_locations same_depth_labels
        
        end
        
        %%% Get coordinates
        if isfile(MNI_coordinates_file)
            this_MNI_idx = MNI_channel_numbers == this_channel_number;
            coordinates{jdx} = MNI_coordinates(this_MNI_idx, :);
        end
        
    end
        
    %%% Make table based on session information and add electrode information
    session_electrodes = repmat(session_info, n_channel_numbers, 1);
    
    session_electrodes.channel_number            = channel_number;
    session_electrodes.label                     = label;
    session_electrodes.neurologist_location      = neurologist_location;
    session_electrodes.automatic_location        = automatic_location;
    session_electrodes.glasser_location          = glasser_location;
    session_electrodes.hemisphere                = hemisphere;
    session_electrodes.bipolar_reference         = bipolar_reference_channels;
    session_electrodes.has_bipolar_reference     = has_bipolar_reference;
    session_electrodes.laplacian_reference       = laplacian_reference_channels;
    session_electrodes.has_laplacian_reference   = has_laplacian_reference;
    session_electrodes.WM_reference              = WM_reference_channels;
    session_electrodes.has_WM_reference          = has_WM_reference;
    session_electrodes.has_somewhat_WM_reference = has_somewhat_WM_reference;
    session_electrodes.coordinates               = coordinates;
    session_electrodes.electrode_ID              = NaN(n_channel_numbers, 1);

    findings = struct;
    findings.locations_determined = locations_determined;
    findings.has_auto             = has_auto;
    findings.has_glasser          = has_glasser;
    findings.has_coordinates      = has_coordinates;
    
end