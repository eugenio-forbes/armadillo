function raw_list = get_raw_list(subject_directory, resources_directory, session_list)

subjects    = session_list.subject;
tasks       = session_list.task;
sessions    = session_list.session;
session_IDs = session_list.session_ID;

raw_list_file = fullfile(resources_directory, 'raw_list.txt');
raw_list = readtable(raw_list_file);

n_sessions = height(raw_list);
session_ID = NaN(n_sessions, 1);
eeg_dates = cell(n_sessions, 1);

for idx = 1:n_sessions

    subject = raw_list.subject{idx};
    task    = raw_list.task{idx};
    session = raw_list.session{idx};
    
    session_index = strcmp(subjects, subject) & strcmp(tasks, task) & strcmp(sessions, session);
    
    if sum(session_index) == 1
        session_ID(idx) = session_IDs(session_index);
    end
    
    raw_eeg_files = regexp(raw_list.raw_eeg_files{idx}, '<([^<>]+)>', 'tokens');
    raw_eeg_files = [raw_eeg_files{:}];
    
    if ~isempty(raw_eeg_files)
    
        n_files = length(raw_eeg_files);
        dates = cell(n_files, 1);
        
        for jdx = 1:n_files
        
            eeg_file_stem = raw_eeg_files{jdx};
        
            files = dir(fullfile(subject_directory, subject, 'raw', '**', sprintf('%s.EEG', eeg_file_stem)));
        
            if ~isempty(files)
                eeg_file_name = fullfile({files(1).folder}, {files(1).name});
                dates{jdx} = get_EEG_date(eeg_file_name{:});
            end
        
        end
        
        eeg_dates{idx} = dates;
        
    end

end

raw_list.eeg_dates  = eeg_dates;
raw_list.session_ID = session_ID;

end