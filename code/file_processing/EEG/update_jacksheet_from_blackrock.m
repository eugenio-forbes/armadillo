%%% This function generates a jacksheet based on information extracted from
%%% most recent .ns2 file corresponding to a Blackrock Neurotech EEG recording.
%%% Saves jacksheet.txt file in /docs folder corresponding to input subject.

function blackrock_has_labels = update_jacksheet_from_blackrock(varargin)
if isempty(varargin)                           %%% May run code from editor editing parameters below:
    analysis_directory = '/path/to/armadillo'; %%% (character vector) Armadillo folder
    subject = 'SC000';                         %%% (character vector) Subject code
else                                           %%% Otherwise function expects arguments in this order:
    analysis_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories
subject_directory = fullfile(analysis_directory, 'subject_files', subject);
raw_folder        = fullfile(subject_directory, 'raw/blackrock');
docs_folder       = fullfile(subject_directory, 'docs');
if ~isfolder(docs_folder)
    mkdir(docs_folder);
end

%%% Search for most recent .ns2 file in raw recording folder
NS2_files = dir(fullfile(raw_folder, '*/*.ns2'));
bad_files = contains({NS2_files.name}, {'._', '~'});
NS2_files(bad_files) = [];

if isempty(NS2_files)
    error('No .ns2 files were found within %s.', raw_folder);
end

[~, latest] = max([NS2_files.datenum]);
NS2_files = fullfile({NS2_files.folder}, {NS2_files.name});
latest_NS2 = NS2_files{latest};

%%% Extract information from .ns2 file and make sure channel labels are valid
NS2 = openNSx(latest_NS2);
    
electrode_info = struct2table(NS2.ElectrodesInfo);
channel_numbers = double(electrode_info.ElectrodeID);
jacksheet_numbers = channel_numbers;
matched_labels = electrode_info.Label;
jacksheet_labels = regexprep(matched_labels, '(\w{2})0(\d).*', '$1$2');
jacksheet_labels = regexprep(jacksheet_labels, '\0', '');
matched_labels = regexp(labels, '^[LR]\w\d{1, 2}', 'match');
matched_labels = vertcat(matched_labels{:});

blackrock_has_labels = any(~cellfun(@isempty, matched_labels));

if blackrock_has_labels

    pause(.5);

    %%% Jacksheet consists of rows with channel numbers and labels separated by space.
    jacksheet_numbers = arrayfun(@num2str, jacksheet_numbers, 'UniformOutput', false);
    jacksheet = strcat(jacksheet_numbers, {' '}, jacksheet_labels);

    %%% Save jacksheet in .txt file
    jacksheet_file = fullfile(docs_folder, 'jacksheet.txt');
    writecell(jacksheet, jacksheet_file);
    
end

end