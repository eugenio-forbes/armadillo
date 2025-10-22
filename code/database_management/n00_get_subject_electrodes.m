function subject_electrodes = n00_get_subject_electrodes(session)

%%% INPUT
%%% Session should be a single row table with at the very least one column named
%%% 'subject' that contains the subject code 'UT###' for which you want to
%%% retrieve all electrode data from. This information will be repeated so
%%% that it is associated to each individual electrode.

subject = session.subject{:};

%%% Initialize output
subject_electrodes = [];

%%% List directories
root_directory = '/path/to/armadillo/parent_directory';
localization_directory = fullfile(root_directory, 'iEEGxfMRI/Pipeline/5crossref');
coordinates_directory = fullfile(root_directory, 'iEEGxfMRI/Pipeline/6finalize');
subject_directory = fullfile(root_directory, 'subject_files');

%%% Option to read MNI coordinates .csv file
coordinate_opts = delimitedTextImportOptions("NumVariables", 5);
coordinate_opts.DataLines = [2, Inf];
coordinate_opts.Delimiter = ", ";
coordinate_opts.VariableNames = ["ElecNumber", "X", "Y", "Z", "Regions"];
coordinate_opts.VariableTypes = ["double", "double", "double", "double", "categorical"];
coordinate_opts.ExtraColumnsRule = "ignore";
coordinate_opts.EmptyLineRule = "read";
coordinate_opts = setvaropts(coordinate_opts, "Regions", "EmptyFieldRule", "auto");


%%% Load this subjects depth electrode information (neurologist
%%% localization) and local atlas information (automatic).
depth_electrode_information_file = fullfile(localization_directory, sprintf('sub-%s/%s_depth_el_info.mat', subject, subject));
local_atlas_information_file = fullfile(localization_directory, sprintf('sub-%s/%s_local_atlas_info.mat', subject, subject));

if isfile(depth_electrode_information_file)
    
    load(depth_electrode_information_file, 'depth_el_info')
    
    %%% Get channel numbers, labels and locations
    if isstruct(depth_el_info) %%% Some save as cell matrix, and some saved as struct
    
        depth_el_info = struct2table(depth_el_info);
        depth_channel_numbers = depth_el_info.elec;
        depth_labels = depth_el_info.contact;
        depth_locations = depth_el_info.recon_label;
        
    elseif iscell(depth_el_info)
    
        depth_channel_numbers = [depth_el_info{:, 1}]';
        depth_labels = depth_el_info(:, 2);
        depth_locations = depth_el_info(:, 3);
        
    end
    
else %%% Only one case were neither file was present in localization dir, so only getting neurologist localization
    
    %%% Would find text file version in subject directory
    depth_electrode_information_file = dir(fullfile(subject_directory, subject, 'docs/*el_inf*.txt'));
    
    if ~isempty(depth_electrode_information_file)
        %%% Search for file given variable naming
        depth_file_name = {depth_electrode_information_file.name};
        depth_electrode_information_file = depth_electrode_information_file(~contains(depth_file_name, '._')); %%% MacOS acces makes these annoying copy files that start with ._
        
        if ~isempty(depth_electrode_information_file)
        
            depth_electrode_information_file = fullfile({depth_electrode_information_file.folder}, {depth_electrode_information_file.name});
            depth_electrode_information_file = depth_electrode_information_file{1};
            
            %%% Read text file as table
            opts = detectImportOptions(depth_electrode_information_file, 'Delimiter', ' ');
            opts.DataLines = [1, Inf]; %%% just to ensure that every line is read
            
            depth_el_info = readtable(depth_electrode_information_file, opts);
            
            depth_channel_numbers = depth_el_info{:, 1};
            depth_labels = depth_el_info{:, 2};
            depth_locations = arrayfun(@(x) strjoin(depth_el_info{x, 3:end}), (1:height(depth_el_info))', 'UniformOutput', false); %%% Labels in this case will be merged because file is file is space delimited
        
        end
    
    end
    
end

clear depth_electrode_information_file

depth_locations = n00_correct_electrode_labels(depth_locations);

%%% Find location matches for hippocampus
hits = ~contains(depth_labels, {'ECG', 'EKG', 'DC', 'BP', 'OUT'});

%%% Use automatic location for initial matches
if isfile(local_atlas_information_file) %Missing for a few subjects

    load(local_atlas_information_file, 'local_atlas_info');
    
    local_atlas_info = struct2table(local_atlas_info);
    
    if strcmp(subject, 'UT165')
        automatic_channel_numbers = 1:height(local_atlas_info);
    else
        automatic_channel_numbers = local_atlas_info.elec;
    end
    
    if strcmp(subject, 'UT128')
        depth_channel_numbers = automatic_channel_numbers;
    end
    
    if strcmp(subject, 'UT269')
        depth_channel_numbers(167:176) = depth_channel_numbers(177:186);
    end
    
    automatic_locations = local_atlas_info.AAL_label;
    glasser_locations = local_atlas_info.Glasser_label;
    
    location_indices = arrayfun(@(x) find(automatic_channel_numbers == x), depth_channel_numbers(hits));
    automatic_location = automatic_locations(location_indices);
    glasser_location = glasser_locations(location_indices);

else
    automatic_location = repelem({'empty'}, sum(hits), 1);
    glasser_location = repelem({'empty'}, sum(hits), 1);
end

clear local_atlas_information_file

%%% Filter channel numbers, labels, and locations
channel_number = depth_channel_numbers(hits);
label = depth_labels(hits);
neurologist_location = depth_locations(hits);

%%% If there were matches, add information about longitudinal location,
%%% hemisphere, reference channel number and type, and MNI coordinates

if ~isempty(channel_number)

    n_channel_numbers = length(channel_number);
    cell_array = cell(n_channel_numbers, 1);
    false_array = false(n_channel_numbers, 1);
    
    hemisphere                   = cell_array;
    bipolar_reference_channels   = cell_array;
    laplacian_reference_channels = cell_array;
    WM_reference_channels        = cell_array;
    has_WM_reference             = false_array;
    has_somewhat_WM_reference    = false_array;
    has_bipolar_reference        = false_array;
    has_laplacian_reference      = false_array;
    coordinates                  = cell_array;
    
    %%% MNI RAS coordinates file
    MNI_coordinates_file = fullfile(coordinates_directory, sprintf('sub-%s/sub-%s_MNIRAS.csv', subject, subject));
    if isfile(MNI_coordinates_file)
        MNI_coordinates_table = readtable(MNI_coordinates_file, coordinate_opts);
        MNI_channel_numbers = MNI_coordinates_table.ElecNumber;
        MNI_coordinates = [MNI_coordinates_table.X, MNI_coordinates_table.Y, MNI_coordinates_table.Z];
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
        
        %%% Get indices of depth electrode info file of channels that
        %%% have the same label stem as this channel.
        
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
            
            n_channels_depth_electrode = length(same_depth_labels);
            within_depth_electrode_idx = find(strcmp(same_depth_labels, this_label));
            
            if this_label_number == min_label_number %Meaning it is the innermost channel
            
                next_adjacent_idx = find(same_depth_label_numbers == this_label_number + 1);
                
                if ~isempty(next_adjacent_idx)
                    bipolar_reference_channels{jdx} = same_depth_channel_numbers(next_adjacent_idx);
                    has_bipolar_reference(jdx) = true;
                    laplacian_reference_channels{jdx} = same_depth_channel_numbers(next_adjacent_idx);
                    has_laplacian_reference(jdx) = true;
                end
                
            elseif this_label_number > min_label_number && this_label_number < max_label_number
            
                next_adjacent_idx = find(same_depth_label_numbers == this_label_number + 1);
                previous_adjacent_idx = find(same_depth_label_numbers == this_label_number - 1);
                
                if ~isempty(next_adjacent_idx)
                    bipolar_reference_channels{jdx} = same_depth_channel_numbers(next_adjacent_idx);
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
    
    clear MNI_coordinates_file depth_channel_numbers depth_locations depth_labels
    
    %%% Make table based on session information and add information
    subject_electrodes = repmat(session, length(channel_number), 1);
    
    subject_electrodes.channel_number            = channel_number;
    subject_electrodes.label                     = label;
    subject_electrodes.neurologist_location      = neurologist_location;
    subject_electrodes.automatic_location        = automatic_location;
    subject_electrodes.glasser_location          = glasser_location;
    subject_electrodes.hemisphere                = hemisphere;
    subject_electrodes.bipolar_reference         = bipolar_reference_channels;
    subject_electrodes.has_bipolar_reference     = has_bipolar_reference;
    subject_electrodes.laplacian_reference       = laplacian_reference_channels;
    subject_electrodes.has_laplacian_reference   = has_laplacian_reference;
    subject_electrodes.WM_reference              = WM_reference_channels;
    subject_electrodes.has_WM_reference          = has_WM_reference;
    subject_electrodes.has_somewhat_WM_reference = has_somewhat_WM_reference;
    subject_electrodes.coordinates               = coordinates;
    
end