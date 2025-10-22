%%% This function will process Blackrock Neurotech .ns2 files present in a subject's
%%% raw recording folder for a given experimental session. Recording data will be
%%% split and saved in individual int16 binary files for each channel recorded. All relevant
%%% recording information present in file will be output in table rows.

function blackrock_rows = split_blackrock_EEG(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
    session = '20200101-120000';               %%% (character vector) Session date in 'yyyymmdd-hhmmss'format
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
    session = varargin{3};
end

%%% Declare directories
subject_directory = fullfile(analysis_directory, 'subject_files', subject);
raw_folder        = fullfile(subject_directory, 'raw/blackrock', session);
split_folder      = strrep(raw_folder, '/raw/', '/split/');
if ~isfolder(split_folder)
    mkdir(split_folder);
end

%%% Verify existence of .ns2 files in specified folder
NS2_files = dir(fullfile(raw_folder, '*.ns2'));
bad_files = contains({NS2_files.name}, {'._', '~'});
NS2_files(bad_files) = [];

if isempty(NS2_files)
    error('No .ns2 files were found within %s EEG folder.', raw_folder);
end

NS2_folder = {NS2_files.folder};
NS2_files = {NS2_files.name};
NS2_files = sort(NS2_files);
NS2_file_stems = strrep(NS2_files, '.ns2', '');
NS2_files = fullfile(NS2_folder, NS2_files);
n_NS2_files = length(NS2_files);

%%% Sync pulse data could have been stored in .ns6 (sampling rate of 30kHz)
NS6_files = dir(fullfile(raw_folder, '*.ns6'));
bad_files = contains({NS6_files.name}, {'._', '~'});
NS6_files(bad_files) = [];

has_NS6 = ~isempty(NS6_files);

%%% Initialize column vectors for making a table with information from .ns2 files
nan_array = NaN(n_NS2_files, 1);
cell_array = cell(n_NS2_files, 1);
false_array = false(n_NS2_files, 1);

highpass_frequency   = nan_array;
highpass_order       = nan_array;
lowpass_frequency    = nan_array;
lowpass_order        = nan_array;
jacksheet_numbers    = cell_array;
jacksheet_labels     = cell_array;
n_recorded_channels  = nan_array;
start_time           = cell_array;
n_samples            = nan_array;
has_sync             = false_array;
sync_channel_numbers = cell_array;
sync_labels          = cell_array;
sampling_rate        = nan_array;
sync_sampling_rate   = nan_array;
n_syncs              = nan_array;
file_name            = cell_array;

%%% Processing of .ns2 files
for idx = 1:n_NS2_files

    %%% Open file using Blackrock code
    NS2_file = NS2_files{idx};
    NS2_file_stem = NS2_file_stems{idx};

    NS6_file = strrep(NS2_file, '.ns2', '.ns6');

    NS2 = openNSx(NS2_file, 'read', 'p:short');
    
    %%% Gather recording data
    electrode_info = struct2table(NS2.ElectrodesInfo);
    channel_numbers = double(electrode_info.ElectrodeID);
    
    jacksheet_numbers{idx} = channel_numbers;
    
    channel_labels = electrode_info.Label;
    channel_labels = regexprep(channel_labels, '\0', '0');
    
    jacksheet_labels{idx} = regexprep(channel_labels, '(\w{2})0(\d).*', '$1$2');
    
    highpass_frequency(idx) = electrode_info.HighFreqCorner(1);
    highpass_order(idx)     = electrode_info.HighFreqOrder(1);
    lowpass_frequency(idx)  = electrode_info.LowFreqCorner(1);
    lowpass_order(idx)      = electrode_info.LowFreqOrder(1);
    
    meta_tags = NS2.MetaTags;
    n_recorded_channels(idx) = meta_tags.ChannelCount;
    sampling_rate(idx)       = meta_tags.SamplingFreq;
    file_name{idx}           = meta_tags.Filename;
    n_samples(idx)           = meta_tags.DataPoints;
    
    start_time_temp = file_name{idx}(1:end-4);
    start_time{idx} = datetime(start_time_temp, 'Format', 'yyyyMMdd-HHmmSS');
    
    data = NS2.Data;
    
    %%% Verify presence of sync pulse data in recording (saved in analog input channel)
    %%% Save sync pulse data
    
    is_sync = channel_numbers > 256 | contains(channel_labels, 'ainp');
    has_sync(idx) = any(is_sync);
    n_syncs(idx) = sum(is_sync);

    if has_sync(idx)
    
        sync_numbers = channel_numbers(is_sync);
        sync_channel_numbers{idx} = sync_numbers;
        sync_labels{idx} = channel_labels(is_sync);
        sync_sampling_rate(idx) = sampling_rate(idx);
        sync_data = data(is_sync, :);
        
        for jdx = 1:n_syncs(idx)
        
            channel_number = sync_numbers(jdx);
            this_file = fullfile(split_folder, [NS2_file_stem, sprintf('.%03d', channel_number)]);
            
            file_id = fopen(this_file, 'wb');
            fwrite(file_id, sync_data(jdx, :), 'int16');
            fclose(file_id);
            
        end
        
    elseif has_NS6 && isfile(NS6_files)
    
        NS6 = openNSx(NS6_file, 'read', 'p:short');
        raw_electrode_info = struct2table(NS6.ElectrodesInfo);
        raw_meta_tags = NS6.MetaTags;
        raw_sampling_rate = raw_meta_tags.SamplingFreq;
        raw_channel_numbers = double(raw_electrode_info.ElectrodeID);
        raw_channel_labels = raw_electrode_info.Label;
        raw_channel_labels = regexprep(raw_channel_labels, '(\w{2})0(\d).*', '$1$2');
        
        is_raw_sync = raw_channel_numbers > 256 || contains(raw_channel_labels, 'ainp');
        has_sync(idx) = any(is_raw_sync);
        n_syncs(idx) = sum(is_raw_sync);
        
        if has_sync(idx)
        
            sync_sampling_rate(idx) = raw_sampling_rate;
            raw_data = NS6.Data;
            sync_numbers = raw_channel_numbers(is_sync);
            sync_channel_numbers{idx} = sync_numbers;
            sync_labels{idx} = raw_channel_labels(is_sync);
            sync_sampling_rate(idx) = sampling_rate(idx);
            sync_data = raw_data(is_sync, :);
        
            for jdx = 1:n_syncs(idx)
        
                channel_number = sync_numbers(jdx);
                this_file = fullfile(split_folder, [NS2_file_stem, sprintf('.%03d', channel_number)]);
        
                file_id = fopen(this_file, 'wb');
                fwrite(file_id, sync_data(jdx, :), 'int16');
                fclose(file_id);
        
            end
        
        end
        
    end

    data(is_sync, :) = [];
    channel_numbers(is_sync, :) = [];
    
    %%% Write the EEG data to individual int16 binary files for each recorded channel
    for jdx = 1:sum(~is_sync)
    
        channel_number = channel_numbers(jdx);
        this_file = fullfile(split_folder, [NS2_file_stem, sprintf('.%03d', channel_number)]);
        
        file_id = fopen(this_file, 'wb');
        fwrite(file_id, data(jdx, :), 'int16');
        fclose(file_id);
        
    end

    pause(.5);
    
    %%% Save jacksheet to folder containing split data
    jacksheet_file = sprintf('%s.jacksheet.txt', NS2_file_stem);
    jacksheet_file = fullfile(split_folder, jacksheet_file);
    jacksheet_strings = arrayfun(@num2str, jacksheet_numbers{idx}, 'UniformOutput', false);
    jacksheet = strcat(jacksheet_strings, {' '}, jacksheet_labels{idx});
    writecell(jacksheet, jacksheet_file);

    pause(.5);
    
    %%% Save parameters to folder containing split data
    params_file_name = sprintf('%s.params.txt', NS2_file_stem);
    params_file = fullfile(split_folder, params_file_name);
    
    file_id = fopen(params_file, 'w', 'l');
    fprintf(file_id, 'samplerate %d\n', sampling_rate(idx));
    fprintf(file_id, 'dataformat ''int16''\n');
    fprintf(file_id, 'gain %d\n', 4);
    fclose(file_id);
    
end

%%% Build information table rows with gathered data 

subject = repelem({subject}, n_NS2_files, 1);
session = repelem({session}, n_NS2_files, 1);

blackrock_rows = table( ...
    subject, session, file_name, highpass_frequency, highpass_order, lowpass_frequency, lowpass_order, ...
    jacksheet_numbers, jacksheet_labels, n_recorded_channels, start_time, n_samples, ...
    has_sync, sync_channel_numbers, sync_labels, sampling_rate, sync_sampling_rate, n_syncs);

end