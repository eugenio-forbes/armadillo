min_sample = 7 * 60 * 1000;
max_sample = 36 * 60 * 1000;

root_directory = '/path/to/armadillo/subject_files';
subject = 'SC000';

noreref_directory = fullfile(root_directory, subject, 'eeg.noreref');
eegfilestem = 'SC000_ICatFR1_0_clinical_01Jan20_1200';

file_template = fullfile(noreref_directory, [eegfilestem, '.*']);

eeg_files = dir(file_template);
eeg_files(contains({eeg_files.name}, {'._', '~', 'params', 'jacksheet'})) = [];

file_size = eeg_files(1).bytes / 2;

eeg_files = fullfile({eeg_files.folder}, {eeg_files.name});

n_files = length(eeg_files);

for idx = 1:n_files
    
    this_file = eeg_files{idx};
    
    file_id = fopen(this_file, 'rb');
    data = fread(file_id, file_size, 'int16');
    fclose(file_id);
    
    data = data(min_sample:max_sample);

    file_id = fopen(this_file, 'wb');
    fwrite(file_id, data, 'int16');
    fclose(file_id);

end