%%% This function generates a jacksheet based on information extracted from
%%% most recent .21E and .EEG files corresponding to a Nihon Kohden EEG recording.
%%% Saves jacksheet.txt file in /docs folder corresponding to input subject.

function update_jacksheet_from_nihon_kohden(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories
subject_directory = fullfile(analysis_directory, 'subject_files', subject);
raw_folder        = fullfile(subject_directory, 'raw/nihon_kohden');
docs_folder       = fullfile(subject_directory, 'docs');
if ~isfolder(docs_folder)
    mkdir(docs_folder);
end
if ~isfolder(raw_folder)
    error('%s EEG folder not found.', raw_folder);
end

%%% So supposedly, for whatever reason, the below numbers are the rows (zero-indexed) in the .21E that correspond to channels 1:256,
%%% in addition to channels DC09 and DC10 (50 and 51).
channel_order = [0:9, 22:23, 10:18, 20:21, 24:36, 74, 75, 100:253, 256:320, 50, 51];

%%% Search for most recent .21E and .EEG files in raw recording folder
EEG_files = dir(fullfile(raw_folder, '*/*.EEG'));
bad_files = contains({EEG_files.name}, {'._', '~'});
EEG_files(bad_files) = [];

if isempty(EEG_files)
    error('No .EEG files were found within %s.', raw_folder);
end

[~, latest] = max([EEG_files.datenum]);
EEG_files = fullfile({EEG_files.folder}, {EEG_files.name});
latest_EEG_file = EEG_files{latest};

label_file = strrep(latest_EEG, '.EEG', '.21E');

if ~isfile(label_file)
    error('No .21E for latest EEG: %s.', latest_EEG);
end

%%% Navigation through .EEG file based on Nihon Kohden code to arrive to number of recorded channels.
file_id = fopen(latest_EEG_file);

fseek(file_id, 146, 'bof');
block_address = fread(file_id, 1, '*int32');

fseek(file_id, block_address+18, 'bof');
waveform_block_address = fread(file_id, 1, '*int32');

fseek(file_id, waveform_block_address+19, 'bof');
waveform_event_flag = fread(file_id, 1, '*uint8');

fseek(file_id, 6, 'cof');
coded_sampling_rate = fread(file_id, 1, '*uint16');

switch(coded_sampling_rate)
    case hex2dec('C064')
        sampling_rate = 100;

    case hex2dec('C068')
        sampling_rate= 200;

    case hex2dec('C1F4')
        sampling_rate = 500;

    case hex2dec('C3E8')
        sampling_rate = 1000;

    case hex2dec('C7D0')
        sampling_rate = 2000;

    case hex2dec('D388')
        sampling_rate = 5000;

    case hex2dec('E710')
        sampling_rate = 10000;
end

fseek(file_id, 6, 'cof');
waveform_block_old_format = 39 + 10 + (2 * sampling_rate) + (double(waveform_event_flag) * sampling_rate);
control_block_EEG1_new = 1072;
EEG2_block_address = waveform_block_address + waveform_block_old_format + control_block_EEG1_new;

fseek(file_id, EEG2_block_address + 20, 'bof');
new_waveform_block_address = fread(file_id, 1, '*int64');

fseek(file_id, new_waveform_block_address + 60, 'bof');
reserve_length = fread(file_id, 1, '*uint16');

fseek(file_id, reserve_length, 'cof');
n_recorded_channels = fread(file_id, 1, '*uint32');

%%% Read table from .21E file containing .EEG recording data row numbers and channel labels.
label_table = readtable(label_file, 'Delimiter', '=', 'ReadVariableNames', false, 'FileType', 'text');
row_numbers = label_table.Var1;
labels = label_table.Var2;

%%% Find row numbers with valid channel labels corresponding to channel order data ID numbers
last_row = find(row_numbers == max(channel_order), 1, 'first');

row_numbers = row_numbers(1:last_row); %%% First row is header as well
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

jacksheet_numbers = 1:length(channel_order);
jacksheet_numbers = jacksheet_numbers';

not_on_recording = ~ismember(channel_order, row_numbers);

jacksheet_numbers(not_on_recording) = [];
channel_order(not_on_recording) = [];

jacksheet_labels = labels(arrayfun(@(x) find(row_numbers == x), channel_order));

%%% Verify that presumed channels are present in recording using data ID numbers in .EEG file
data_ID_numbers = zeros(n_recorded_channels, 1);
for idx = 1:n_recorded_channels

    data_ID_numbers(idx) = fread(file_id, 1, '*int16');
    fseek(file_id, 8, 'cof');

end
fclose(file_id)

missing = ~ismember(channel_order, data_ID_numbers);
jacksheet_labels(missing) = [];
jacksheet_numbers(missing) = [];

pause(.5);

%%% Jacksheet consists of rows with channel numbers and labels separated by space.
jacksheet_numbers = arrayfun(@num2str, jacksheet_numbers, 'UniformOutput', false);
jacksheet = strcat(jacksheet_numbers, {' '}, jacksheet_labels);

%%% Save jacksheet in .txt file
jacksheet_file = fullfile(docs_folder, 'jacksheet.txt');
writecell(jacksheet, jacksheet_file);

end