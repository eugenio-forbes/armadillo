function n01_process_nsx(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo';
    subject = 'SC000';
    task = 'PS_blackrock';
    session = 0;         %%% integer
    date = '2020-01-01'; %%% yyyy-mm-dd format
    banks = {'A', 'B'};
else
    root_directory = varargin{1};
    subject = varargin{2};
    task = varargin{3};
    session = varargin{4};
    date = varargin{5};
    banks = varargin{6};
end

%%% List directories and file names
subject_directory = fullfile(root_directory, 'configurations', subject);
raw_folder = fullfile(subject_directory, 'raw', sprintf('%s_%s_%d_%s', subject, task, session, date));

nsx_file = dir(fullfile(raw_folder, '*.ns2'));
nsx_file(contains(nsx_file.name, {'._', '~'})) = [];
if isempty(nsx_file)
    error('Recording for %s %s %s was not found.', subject, task, session);    
end
nsx_file = fullfile({nsx_file.folder}, {nsx_file.name});
nsx_file = nsx_file{1};

jacksheet_file = dir(fullfile(subject_directory, 'docs/*jacksheet*.txt'));

reref_directory = fullfile(subject_directory, 'eeg.reref');
noreref_directory = fullfile(subject_directory, 'eeg.noreref');
if ~isfolder(reref_directory)
    mkdir(reref_directory);
end
if ~isfolder(noreref_directory)
    mkdir(noreref_directory);
end

%%% Convert date from yyyy-mm-dd for database consistency
formatted_date = datestr(datetime(date), 'ddmmmyy');

%%% Get EEG file stem and check if the recording has been previously split
eeg_file_stem = sprintf('%s_%s_%d_%s_blackrock', subject, task, session, formatted_date);
previous_files = dir(fullfile(subject_directory, '*', [eeg_file_stem, '*']));

if ~isempty(previous_files)

    previous_files = fullfile({previous_files.folder}, {previous_files.name});
    
    response = input('This file has previously been split. Would you like to resplit (and delete all previous files)? (y/n)\n', 's');
    
    if strcmp(response, 'y')
    
        n_files = length(previous_files);
        
        for idx = 1:n_files
            delete(previous_files{idx});
        end
        
    else
        return;
    end
    
end

%%% Verify that jacksheet file exists so that channels can be saved based
%%% on order of clinical configuration
if ~isempty(jacksheet_file)

    jacksheet_file = fullfile({jacksheet_file.folder}, {jacksheet_file.name});
    jacksheet_file(contains(jacksheet_file, {'~', '._'})) = [];
    
    if ~isempty(jacksheet_file)
        jacksheet_file = jacksheet_file{1};
    else
        error('No jacksheet found in %s.\nCreate jacksheet before splitting .edf\n', subject_directory);
    end
    
else
    error('No jacksheet found in %s.\nCreate jacksheet before splitting .edf\n', subject_directory);
end

%%% Read jacksheet
jacksheet = readcell(jacksheet_file);
channel_numbers = vertcat(jacksheet{:, 1});
jacksheet_labels = jacksheet(:, 2);

%%% Open .nsx
nsx = openNSx(nsx_file, 'read', 'uV');


%%% Get file info
info = edfinfo(edf_file);

n_channels            = info.NumSignals;
file_length_sec       = info.NumDataRecords;
sampling_rate         = info.NumSamples;
least_significant_bit = info.PhysicalDimensions;
has_micros            = any(sampling_rate == 30000);
edf_labels            = info.SignalLabels;
edf_labels            = cellfun(@char, edf_labels, 'UniformOutput', false);
   
%%% Read .edf (As of 5/7/2024, setting DataRecordOutputType to 'vector'
%%% (default) still returns a timetable type instead of double
data = cell2mat(table2array(edfread(edf_file, 'DataRecordOutputType', 'vector')));

%%% Not removing offset for now because calculation showed offsets less than 0.5
%%% which would make the data the same after rounding.

common_average_reference = mean(data, 2);

for idx = 1:n_channels

    edf_label = edf_labels{idx};
    channel_number = channel_numbers(strcmp(jacksheet_labels, edf_label));
    channel_data = data(:, idx);
    
    channel_file = sprintf('%s.%03d', eeg_file_stem, channel_number);
    noreref_file = fullfile(noreref_directory, channel_file);
    reref_file = fullfile(reref_directory, channel_file);
    
    rereferenced_data = channel_data - common_average_reference;
    
    file_id = fopen(noreref_file, 'wb');
    fwrite(file_id, channel_data, 'int16');
    fclose(file_id);
    
    file_id = fopen(reref_file, 'wb');
    fwrite(file_id, rereferenced_data, 'int16');
    fclose(file_id);
    
end

new_jacksheet = jacksheet(ismember(jacksheet_labels, edf_labels), :);
new_jacksheet_file = fullfile(noreref_directory, [eeg_file_stem, '.jacksheet.txt']);
writecell(new_jacksheet, new_jacksheet_file);

sampling_rate = sampling_rate(1);
gain = 0.25;
data_format = 'int16';

parameter_file = fullfile(noreref_directory, [eeg_file_stem, '.params.txt']);
file_id = fopen(parameter_file, 'w');
fprintf(file_id, 'samplerate %d\n', sampling_rate);
fprintf(file_id, 'dataformat %s\n', data_format);
fprintf(file_id, 'gain %f\n', gain);
fclose(file_id);

end