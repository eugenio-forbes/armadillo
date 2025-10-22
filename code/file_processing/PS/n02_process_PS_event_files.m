function n02_process_PS_event_files(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo';
    subject = 'SC000';
    task = 'PS_clinical';
    session = 0;         %%% integer
    date = '2020-01-01'; %%% 'yyyy-mm-dd' format
    default_replacement = true;
else
    root_directory = varargin{1};
    subject = varargin{2};
    task = varargin{3};
    session = varargin{4};
    date = varargin{5};
    default_replacement = false;
end

%%% Currently only intended for macros sampled at 1000Hz in BR.

%%% List directories and file names
subject_directory = fullfile(root_directory, 'shared/lega_ansir/subjFiles', subject);

elemem_folder = fullfile(subject_directory, 'raw', sprintf('%s_%s_%d_%s', subject, task, session, date));
elemem_events_file = fullfile(elemem_folder, 'event.log');
elemem_events_save = fullfile(elemem_folder, 'elemem_log.mat');

if isfile(elemem_events_save)

    if ~default_replacement
        response = input('Elemem events for this session have previously been processed. Do you want to keep these files?(y/n)\n', 's');
    else
        response = 'n';
    end
    
    if strcmp(response, 'y')
        fprintf('Keeping previous files and not processing elemem events in %s\n', behavioral_folder);
        delete_previous = false;
        process_elemem_events = false;
    else
        delete_previous = true;
        process_elemem_events = true;
    end
    
else
    delete_previous = false;
    process_elemem_events = true;
end

if delete_previous

    if ~isfile(elemem_events_file)
        fprintf('Did not delete processed elemem events in %s\n', behavioral_folder);
    else
    
        if isfile(elemem_events_save)
            delete(elemem_events_save);
        end
        
    end
    
end

if process_elemem_events

    if ~isfile(elemem_events_file)
        fprintf('Could not process elemem events because no .log was found in %s\n', elemem_folder);
    else
        extract_elemem_events(elemem_events_file, elemem_events_save);
        fprintf('Processed elemem events in %s\n', elemem_folder);
    end
    
end

end


function extract_elemem_events(elemem_file, mat_file)

log_text = fileread(elemem_file);

newline_positions = strfind(log_text, newline);
n_lines = length(newline_positions);
event_holder = cell(n_lines, 1);

for idx = 1:n_lines

    if idx == 1
        event_indices = 1:newline_positions(idx)-1;
    else
        event_indices = newline_positions(idx-1)+1:newline_positions(idx)-1;
    end
    
    event_holder{idx} = jsondecode(log_text(event_indices));
    
    event_fields = fields(event_holder{idx});
    
    if ismember('id', event_fields)
        event_holder{idx} = rmfield(event_holder{idx}, 'id');
    end
    
    if ismember('loaded', event_fields)
        event_holder{idx} = rmfield(event_holder{idx}, 'loaded');
    end
    
end

elemem_log = vertcat(event_holder{:});
elemem_log = struct2table(elemem_log);

eeg_start_index = strcmp(elemem_log.type, 'EEGSTART');
n_starts = sum(eeg_start_index);

if n_starts == 0
    error('%s does not include EEG start time. Could not align. Did not save processed events.', elemem_file);
elseif n_starts > 1
    error('%s has more than one EEG start time. Need to develop code for such a case.', elemem_file);
end

eeg_start_time = elemem_log.time(eeg_start_index);
elemem_log.time = elemem_log.time - eeg_start_time;

save(mat_file, 'elemem_log')

end