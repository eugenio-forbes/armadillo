function check_no_coords()

rootDir = 'path/to/armadillo/parent_directory';
codeDir = fullfile(rootDir, 'username/armadillo/code');
coordDir = fullfile(rootDir, 'shared/lega_ansir/iEEGxfMRI/Pipeline'

load(fullfile(codeDir, 'no_coords.mat'), 'no_coords');

n_no_coords = height(no_coords);
unique_subjects = unique(no_coords.subject);

for idx = 1

end

end