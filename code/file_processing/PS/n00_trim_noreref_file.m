min_sample = 7 * 60 * 1000;
max_sample = 36 * 60 * 1000;

root_directory = '/path/to/armadillo/subject_files';
subject = 'SC000';

noreref_directory = fullfile(root_directory, subject, 'eeg.noreref');
eegfilestem = 'SC000_ICatFR1_1_clinical_01Jan20_1200';

file_template = fullfile(noreref_directory, [eegfilestem, '.*']);

eeg_files = dir(file_template);
eeg_files(contains({eeg_files.name}, {'._', '~', 'params', 'jacksheet'})) = [];

file_size = eeg_files(1).bytes / 2;

eeg_files = fullfile({eeg_files.folder}, {eeg_files.name});
n_files = length(eeg_files);

for idx = 1:n_files

    this_file = eeg_files{idx};
    
    fid = fopen(this_file, 'rb');
    data = fread(fid, file_size, 'int16');
    fclose(fid);
    
    data = data(min_sample:max_sample);
    
    fid = fopen(this_file, 'wb');
    fwrite(fid, data, 'int16');
    fclose(fid);

end