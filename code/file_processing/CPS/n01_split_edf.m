function n01_split_edf(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    subject = 'SC000';
    task = 'AR_elemem';
    session = 0;         %%% integer
    date = '2020-01-01'; %%% 'yyyy-mm-dd' format
    time = '12-00-00';   %%% 'hh-mm-ss' format
else
    root_directory = varargin{1};
    subject = varargin{2};
    task = varargin{3};
    session = varargin{4};
    date = varargin{5};
    time = varargin{6};
end

%%% Currently only intended for macros sampled at 1000Hz using Blackrock. Use Matlab 2020b or later

version_info = version;
version_year = str2double(regexp(version_info, '(?<=R20)\d{2}', 'match'));
version_letter = regexp(version_info, '(?<=R20\d{2})\w', 'match');

if version_year < 20 || (version_year == 20 && ~strcmp(version_letter, 'b'))
    error('n01_split_edf.m is only compatible with Matlab versions 2020b and later.')
end

%%% List directories and file names
subject_directory = fullfile(root_directory, 'shared/lega_ansir/subjFiles', subject);
elemem_folder     = fullfile(subject_directory, 'raw', sprintf('%s_%s_%d_%s_%s', subject, task, session, date, time));
reref_directory   = fullfile(subject_directory, 'eeg.reref');
noreref_directory = fullfile(subject_directory, 'eeg.noreref');
if ~isfolder(reref_directory)
    mkdir(reref_directory);
end
if ~isfolder(noreref_directory)
    mkdir(noreref_directory);
end

edf_file = fullfile(elemem_folder, 'eeg_data.edf');
jacksheet_file = dir(fullfile(subject_directory, 'docs/*jacksheet*.txt'));


%%% Convert date from yyyy-mm-dd for database consistency
formatted_date = datestr(datetime(date), 'ddmmmyy');
formatted_time = time([1, 2, 4, 5]);

%%% Get EEG file stem and check if the recording has been previously split
eeg_file_stem = sprintf('%s_%s_%d_%s_%s_elemem', subject, task, session, formatted_date, formatted_time);
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

%%% Verify that jacksheet file exists so that labels can be associated to
%%% channel number in clinical system
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

%%% Get file info
info = edfinfo(edf_file);

n_channels            = info.NumSignals;
file_length_sec       = info.NumDataRecords;
sampling_rate         = info.NumSamples;
least_significant_bit = info.PhysicalDimensions;
edf_labels            = info.SignalLabels;

has_micros = any(sampling_rate == 30000);
edf_labels = cellfun(@char, edf_labels, 'UniformOutput', false);
   
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