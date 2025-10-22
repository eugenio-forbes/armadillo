%%% This function will process Nihon Kohden .EEG and .21E files present in a subject's
%%% raw recording folder for a given experimental session. Recording data will be
%%% split and saved in individual int16 binary files for each channel recorded. All relevant
%%% recording information present in file will be output in table rows.

function nihon_kohden_rows = split_nihon_kohden_EEG(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
    task = 'PS';                               %%% (character vector) Task name
    session = '2020-01-01_12-00-00';           %%% (character vector) Date of session in 'yyyy-mm-dd_hh-mm-ss' format
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
    task = varargin{3};
    session = varargin{4};
end

%%% Declare directories
subject_directory = fullfile(analysis_directory, 'subject_files', subject);
raw_folder        = fullfile(subject_directory, 'raw/nihon_kohden', sprintf('%s_%s', task, session));
split_folder      = strrep(raw_folder, '/raw/', '/split/');

%%% Verify existence of .EEG and .21E files in specified folder
if ~isfolder(raw_folder)
    error('%s EEG folder not found.', raw_folder);
end

EEG_files = dir(fullfile(raw_folder, '*.EEG'));
bad_files = contains({EEG_files.name}, {'._', '~'});
EEG_files(bad_files) = [];

if isempty(EEG_files)
    error('No .EEG files were found within %s EEG folder.', raw_folder);
end

EEG_files = strrep({EEG_files.name}, '.EEG', '');
EEG_files = sort(EEG_files);
n_EEG_files = length(EEG_files);

label_files = dir(fullfile(raw_folder, '*.21E'));
bad_files = contains({label_files.name}, {'._', '~'});
label_files(bad_files) = [];

if isempty(label_files)
    error('No .21E files were found within %s EEG folder.', raw_folder);
end

label_files = strrep({label_files.name}, '.21E', '');
label_files = sort(label_files);
n_label_files = length(label_files);

if n_label_files ~= n_EEG_files
    error('Number of .21E and .EEG files in %s does not match.', raw_folder);
end

if any(~ismember(label_files, EEG_files))
    error('There is a file name mismatch between .21Es and .EEGs in %s.', raw_folder);
end

%%% Initialize column vectors for making a table with information from .EEG files
nan_array = NaN(n_EEG_files, 1);
cell_array = cell(n_EEG_files, 1);
zero_array = zeros(n_EEG_files, 1);
false_array = false(n_EEG_files, 1);

file_name                   = cell_array;
device_type                 = cell_array;
start_time                  = cell_array;
junction_box                = cell_array;
block_ID                    = uint8(nan_array);
eeg_system                  = cell_array;
is_new_nk_format            = false_array;
n_blocks                    = uint8(nan_array);
block_address               = int32(nan_array);
block_name                  = cell_array;
block_ID2                   = uint8(nan_array);
data_format                 = cell_array;
n_waveform_blocks           = uint8(nan_array);
waveform_block_address      = int32(nan_array);
waveform_block_name         = cell_array;
waveform_block_ID           = uint8(nan_array);
start_hour_us               = cell_array;
waveform_data_type          = uint8(nan_array);
waveform_byte_length        = uint8(nan_array);
waveform_event_flag         = uint8(nan_array);
start_time_seconds          = cell_array;
sampling_rate               = nan_array;
n_tenths_blocks             = uint32(nan_array);
n_samples_second            = nan_array;
AD_offset                   = int16(nan_array);
AD_value                    = uint16(nan_array);
sample_bit_length           = uint8(nan_array);
compression_flag            = uint8(nan_array);
n_recordings                = uint8(nan_array);
waveform_block_old_format   = nan_array;
control_block_EEG1_new      = nan_array;
EEG2_block_address          = nan_array;
EEG2_block_ID               = uint8(nan_array);
EEG2_data_format            = cell_array;
n_EEG2_blocks               = uint16(nan_array);
reserved                    = cell_array;
new_waveform_block_address  = int64(nan_array);
EEG2_waveform_block_ID      = uint8(nan_array);
EEG2_data_format2           = cell_array;
EEG2_data_type              = uint8(nan_array);
EEG2_byte_length            = uint8(nan_array);
EEG2_event_flag             = uint8(nan_array);
start_time_string           = cell_array;
sampling_rate2              = nan_array;
n_tenths_blocks2            = nan_array;
n_samples                   = nan_array;
AD_offset2                  = int16(nan_array);
AD_value2                   = uint16(nan_array);
sample_bit_length2          = uint16(nan_array);
compression_flag2           = uint16(nan_array);
reserve_length              = uint16(nan_array);
reserve_data                = cell_array;
n_recorded_channels         = uint32(nan_array);
jacksheet_numbers           = cell_array;
jacksheet_labels            = cell_array;    
channel_sensitivities       = cell_array;
channel_units               = cell_array;
channel_gains               = cell_array;
has_sync                    = false_array;
sync_channel_numbers        = cell_array;
sync_labels                 = cell_array;
sync_sampling_rate          = nan_array;
n_syncs                     = zero_array;
recording_ID                = zero_array;


%%% Processing of .EEG and .21E files based on Nihon Kohden code
for idx = 1:n_EEG_files

    %%% So supposedly, for whatever reason, the below numbers are the rows
    %%% (zero-indexed) in the .21E that corresponds to channels 1:256,
    %%% in addition to DC09 and DC10 (50 and 51).
    
    channel_order = [0:9, 22:23, 10:18, 20:21, 24:36, 74, 75, 100:253, 256:320, 50, 51];

    %%% Giving the split files the same name as the original raw file
    EEG_file = fullfile(raw_folder, [EEG_files{idx}, '.EEG']);
    split_file_stem = EEG_files{idx};
    
    file_id = fopen(EEG_file);

    device_type{idx}  = regexprep(fread(file_id, 32, '*char')', '\0', '');
    file_name_temp    = regexprep(fread(file_id, 32, '*char')', '\0', '');
    start_time_temp   = regexprep(fread(file_id, 32, '*char')', '\0', '');
    junction_box{idx} = regexprep(fread(file_id, 32, '*char')', '\0', '');
    
    file_name{idx} = strrep(file_name_temp, '.PNT', '');
    start_time{idx} = datetime(start_time_temp, 'Format', 'yyyyMMddHHmmssSSS');

    %%% Reading EEG1 control Block (contains names and addresses for EEG2 blocks)
    block_ID(idx)   = fread(file_id, 1, '*uint8')';
    eeg_system{idx} = fread(file_id, 16, '*char')';
    
    is_new_nk_format(idx) = contains(eeg_system{idx}, 'EEG-1200A');

    n_blocks(idx)      = fread(file_id, 1, '*uint8'); %%% Should not be more than one.
    block_address(idx) = fread(file_id, 1, '*int32');
    block_name{idx}    = fread(file_id, 16, '*char');

    %%% Reading EEG2m control block (contains names and addresses for waveform blocks)
    fseek(file_id, block_address(idx), 'bof');
    block_ID2(idx)         = fread(file_id, 1, '*uint8');
    data_format{idx}       = fread(file_id, 16, '*char');
    n_waveform_blocks(idx) = fread(file_id, 1, '*uint8'); 
    
    %%% Should not be more than one. Otherwise need to add loop for below.
    waveform_block_address(idx) = fread(file_id, 1, '*int32');
    waveform_block_name{idx}    = fread(file_id, 16, '*char');
    
    %%% Reading waveform block
    fseek(file_id, waveform_block_address(idx), 'bof');
    waveform_block_ID(idx)    = fread(file_id, 1, '*uint8');
    start_hour_us{idx}        = fread(file_id, 16, '*char');
    waveform_data_type(idx)   = fread(file_id, 1, '*uint8');
    waveform_byte_length(idx) = fread(file_id, 1, '*uint8');
    waveform_event_flag(idx)  = fread(file_id, 1, '*uint8');

    %%% Get the start time
    years   = bcdConverter(fread(file_id, 1, '*uint8')) + 2000;
    months  = bcdConverter(fread(file_id, 1, '*uint8'));
    days    = bcdConverter(fread(file_id, 1, '*uint8'));
    hours   = bcdConverter(fread(file_id, 1, '*uint8'));
    minutes = bcdConverter(fread(file_id, 1, '*uint8'));
    seconds = bcdConverter(fread(file_id, 1, '*uint8'));
    
    start_time_seconds{idx} = datetime(years, months, days, hours, minutes, seconds);

    %%% Get the sampling rate
    coded_sampling_rate = fread(file_id, 1, '*uint16');
    
    switch(coded_sampling_rate)
        case hex2dec('C064')
            sampling_rate(idx) = 100;
    
        case hex2dec('C068')
            sampling_rate(idx) = 200;
    
        case hex2dec('C1F4')
            sampling_rate(idx) = 500;
    
        case hex2dec('C3E8')
            sampling_rate(idx) = 1000;
    
        case hex2dec('C7D0')
            sampling_rate(idx) = 2000;
    
        case hex2dec('D388')
            sampling_rate(idx) = 5000;
    
        case hex2dec('E710')
            sampling_rate(idx) = 10000;
    end
    
    sync_sampling_rate(idx) = sampling_rate(idx);

    %%% Get the number of 100 msec block
    n_tenths_blocks(idx)   = fread(file_id, 1, '*uint32');
    n_samples_second(idx)  = sampling_rate(idx) * n_tenths_blocks(idx) / 10;
    AD_offset(idx)         = fread(file_id, 1, '*int16');
    AD_value(idx)          = fread(file_id, 1, '*uint16');
    sample_bit_length(idx) = fread(file_id, 1, '*uint8');
    compression_flag(idx)  = fread(file_id, 1, '*uint8');
    n_recordings(idx)      = fread(file_id, 1, '*uint8'); %%% S
    
    waveform_block_old_format(idx) = 39 + 10 + (2 * sampling_rate(idx)) + (double(waveform_event_flag(idx)) * sampling_rate(idx));
    control_block_EEG1_new(idx) = 1072;
    EEG2_block_address(idx) = waveform_block_address(idx) + waveform_block_old_format(idx) + control_block_EEG1_new(idx);

    %%% - EEG2' format
    fseek(file_id, EEG2_block_address(idx), 'bof');
    EEG2_block_ID(idx)              = fread(file_id, 1, '*uint8');
    EEG2_data_format{idx}           = fread(file_id, 16, '*char');
    n_EEG2_blocks(idx)              = fread(file_id, 1, '*uint16');
    reserved{idx}                   = fread(file_id, 1, '*char');
    new_waveform_block_address(idx) = fread(file_id, 1, '*int64');

    %%% - EEG2' waveform format
    fseek(file_id, new_waveform_block_address(idx), 'bof');          
    EEG2_waveform_block_ID(idx) = fread(file_id, 1, '*uint8');
    EEG2_data_format2{idx}      = fread(file_id, 16, '*char');
    EEG2_data_type(idx)         = fread(file_id, 1, '*uint8');
    EEG2_byte_length(idx)       = fread(file_id, 1, '*uint8');
    EEG2_event_flag(idx)        = fread(file_id, 1, '*uint8');

    %%% - Now things get a little different with the new header
    start_time_string{idx}   = fread(file_id, 20, '*char');
    sampling_rate2(idx)      = double(fread(file_id, 1, '*uint32'));
    n_tenths_blocks2(idx)    = double(fread(file_id, 1, '*uint64'));

    n_samples(idx)           = sampling_rate2(idx) * n_tenths_blocks2(idx) / 10;
    AD_offset2(idx)          = fread(file_id, 1, '*int16');
    AD_value2(idx)           = fread(file_id, 1, '*uint16');
    sample_bit_length2(idx)  = fread(file_id, 1, '*uint16');
    compression_flag2(idx)   = fread(file_id, 1, '*uint16');
    reserve_length(idx)      = fread(file_id, 1, '*uint16');
    reserve_data{idx}        = fread(file_id, reserve_length(idx), '*char');

    n_recorded_channels(idx) = fread(file_id, 1, '*uint32');

    %%% Read table from .21E file containing .EEG recording data row numbers and channel labels.
    label_file = strrep(EEG_file, '.EEG', '.21E');
    label_table = readtable(label_file, 'Delimiter', '=', 'ReadVariableNames', false, 'FileType', 'text');
    
    row_numbers = label_table.Var1;
    labels = label_table.Var2;
    
    %%% Find row numbers with valid channel labels corresponding to channel order data ID numbers
    last_row = find(row_numbers == max(channel_order), 1, 'first');
    
    row_numbers = row_numbers(1:last_row); %first row is header as well
    labels = labels(1:last_row);

    bad_row_numbers = ~ismember(row_numbers, channel_order);
    
    channel_labels = regexp(labels, '^[LR]\w\d{1, 2}', 'match');
    channel_labels = vertcat(channel_labels{:});
    channel_labels(cellfun(@isempty, channel_labels)) = [];
    DC_labels = {'DC09'; 'DC10'};
    
    bad_labels = ~ismember(labels, [channel_labels; DC_labels]);

    excluded_rows = bad_labels | bad_row_numbers;
    
    labels(excluded_rows) = [];
    row_numbers(excluded_rows) = [];

    jacksheet_numbers_temp = 1:length(channel_order);
    jacksheet_numbers_temp = jacksheet_numbers_temp';

    not_on_recording = ~ismember(channel_order, row_numbers);
    
    jacksheet_numbers_temp(not_on_recording) = [];
    channel_order(not_on_recording) = [];
    
    ordered_labels = labels(arrayfun(@(x) find(row_numbers == x), channel_order));

    %%% Gather data from each recorded channel
    data_ID_numbers = zeros(n_recorded_channels(idx), 1);
    sensitivities   = zeros(n_recorded_channels(idx), 1);
    units           = zeros(n_recorded_channels(idx), 1);
    gains           = zeros(n_recorded_channels(idx), 1);

    for jdx = 1:n_recorded_channels(idx)
        
        data_ID_numbers(jdx) = fread(file_id, 1, '*int16');
        
        fseek(file_id, 6, 'cof');
        sensitivities(jdx)  = fread(file_id, 1, '*uint8');
        coded_channel_units = fread(file_id, 1, '*uint8');
        
        switch coded_channel_units
            case 0 
                units(jdx) = 1000; %uV
            
            case 1
                units(jdx) = 2; %uV
            
            case 2
                units(jdx) = 5; %uV
            
            case 3
                units(jdx) = 10; %uV
            
            case 4
                units(jdx) = 20; %uV
            
            case 5
                units(jdx) = 50; %uV
            
            case 6
                units(jdx) = 100; %uV
            
            case 7
                units(jdx) = 200; %uV
            
            case 8
                units(jdx) = 500; %uV
            
            case 9
                units(jdx) = 1000; %uV
        end
        
        gains(jdx) = units(jdx) / double(AD_value2(idx));
    
    end
    
    channel_sensitivities{idx} = sensitivities;
    channel_units{idx} = units;
    channel_gains{idx} = gains;

    %%% Verify that presumed channels are present in recording using data ID numbers in .EEG file
    missing = ~ismember(channel_order, data_ID_numbers);
    
    channel_order(missing) = [];
    ordered_labels(missing) = [];
    jacksheet_numbers_temp(missing) = [];
    
    jacksheet_numbers{idx} = jacksheet_numbers_temp;
    jacksheet_labels{idx} = ordered_labels;

    %%% Check whether sync pulse data was recorded
    is_sync = jacksheet_numbers_temp > 256;
    has_sync(idx) = any(is_sync);
    n_syncs(idx) = sum(is_sync);
    sync_channel_numbers{idx} = jacksheet_numbers_temp(is_sync);
    sync_labels{idx} = jacksheet_labels{idx}(is_sync);
    
    %%% Read EEG data and only include data from channels of interest
    EEG_data = fread(file_id, [double(n_recorded_channels(idx) + 1) n_samples(idx)], '*uint16');
    fclose(file_id);
    
    not_included = [~ismember(data_ID_numbers, channel_order); true];
    EEG_data(not_included, :) = [];

    data_ID_numbers(not_included(1:end - 1)) = [];
    data_to_index = arrayfun(@(x) find(channel_order == x), data_ID_numbers);

    %%% Add analog-to-digital conversion offset and convert to int16
    EEG_data = int16(int32(EEG_data) + int32(AD_offset2(idx)));    
    
    if ~isfolder(split_folder)
        mkdir(split_folder);
    end

    %%% Write the EEG data to individual int16 binary files for each recorded channel
    pause(.5);
    
    template_channel = fullfile(split_folder, [split_file_stem, '.%03i']);
    
    for jdx = 1:size(EEG_data, 1)
    
        channel_file = sprintf(template_channel, jacksheet_numbers_temp(data_to_index(jdx)));
    
        file_id = fopen(channel_file, 'w', 'l');
        fwrite(file_id, EEG_data(jdx, :), 'int16');
        fclose(file_id);
    
    end
    
    pause(.5);
    
    %%% Save jacksheet to folder containing split data
    jacksheet_file = sprintf('%s.jacksheet.txt', split_file_stem);
    jacksheet_file = fullfile(split_folder, jacksheet_file);
    jacksheet_strings = arrayfun(@num2str, jacksheet_numbers{idx}, 'UniformOutput', false);
    jacksheet = strcat(jacksheet_strings, {' '}, jacksheet_labels{idx});
    writecell(jacksheet, jacksheet_file);

    pause(.5);
    
    %%% Save parameters to folder containing split data
    params_file_name = sprintf('%s.params.txt', split_file_stem);
    params_file = fullfile(split_folder, params_file_name);
    
    file_id = fopen(params_file, 'w', 'l');
    fprintf(file_id, 'samplerate %d\n', sampling_rate2(idx));
    fprintf(file_id, 'dataformat ''int16''\n');
    fprintf(file_id, 'gain %d\n', channel_gains{idx}(1));
    fclose(file_id);

end

%%% Build information table rows with gathered data 

subject = repelem({subject}, n_EEG_files, 1);
session = repelem({session}, n_EEG_files, 1);

nihon_kohden_rows = table(...
    subject, session, file_name, device_type, start_time, junction_box, block_ID, eeg_system, ...
    is_new_nk_format, n_blocks, block_address, block_name, block_ID2, ...
    data_format, n_waveform_blocks, waveform_block_address, ...
    waveform_block_name, waveform_block_ID, start_hour_us, ...
    waveform_data_type, waveform_byte_length, waveform_event_flag, start_time_seconds, ...
    sampling_rate, n_tenths_blocks, n_samples_second, AD_offset, AD_value, ...
    sample_bit_length, compression_flag, n_recordings, ...
    waveform_block_old_format, control_block_EEG1_new, EEG2_block_address, ...
    EEG2_block_ID, EEG2_data_format, n_EEG2_blocks, reserved, new_waveform_block_address, ...
    EEG2_waveform_block_ID, EEG2_data_format2, EEG2_data_type, EEG2_byte_length, ...
    EEG2_event_flag, start_time_string, sampling_rate2, n_tenths_blocks2, ...
    n_samples, AD_offset2, AD_value2, sample_bit_length2, ...
    compression_flag2, reserve_length, reserve_data, n_recorded_channels, ...
    jacksheet_numbers, jacksheet_labels, has_sync, sync_channel_numbers, n_syncs, ...
    sync_sampling_rate, channel_sensitivities, channel_units, channel_gains, recording_ID);

end


function out = bcdConverter(bits_in)

  x = dec2bin(bits_in, 8);
  out = 10 * bin2dec(x(1:4)) + bin2dec(x(5:8));

end