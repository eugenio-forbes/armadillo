function n02_process_event_files(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo';
    subject = 'SC000';
    task = 'AR_elemem';
    session = 1;         %%% integer
    date = '2020-01-01'; %%% 'yyyy-mm-dd' format
    time = '12-00-00';   %%% 'hh-mm-ss' format
    default_replacement = true;
else
    root_directory = varargin{1};
    subject = varargin{2};
    task = varargin{3};
    session = varargin{4};
    date = varargin{5};
    time = varargin{6};
    default_replacement = false;
end

%%% Currently only intended for macros sampled at 1000Hz in BR.

%%% List directories and file names
subject_directory  = fullfile(root_directory, 'subject_files', subject);
elemem_folder      = fullfile(subject_directory, 'raw', sprintf('%s_%s_%d_%s_%s', subject, task, session, date, time));
behavioral_folder  = fullfile(subject_directory, 'behavioral', task, sprintf('session_%d', session));
SMILE_events_csv   = fullfile(behavioral_folder, 'events.csv');
SMILE_events_mat   = fullfile(behavioral_folder, 'events.mat');
SMILE_events_old   = fullfile(behavioral_folder, 'events.mat.old');
communications_csv = fullfile(behavioral_folder, 'communications.csv');
communications_mat = fullfile(behavioral_folder, 'communications.mat');
elemem_events_file = fullfile(elemem_folder, 'event.log');
elemem_events_save = fullfile(behavioral_folder, 'elemem_log.mat');

if isfile(SMILE_events_old) || isfile(SMILE_events_mat)

    if ~default_replacement
        response = input('SMILE events for this session have previously been processed. Do you want to keep these files?(y/n)\n', 's');
    else
        response = 'n';
    end
    
    if strcmp(response, 'y')
        fprintf('Keeping previous files and not processing SMILE events in %s\n', behavioral_folder);
        delete_previous = false;
        process_SMILE_events = false;
    else
        delete_previous = true;
        process_SMILE_events = true;
    end
    
else
    delete_previous = false;
    process_SMILE_events = true;
end

if delete_previous

    if ~isfile(SMILE_events_csv)
        fprintf('Did not delete processed SMILE events in %s\n', behavioral_folder);
    else
    
        if isfile(SMILE_events_mat)
            delete(SMILE_events_mat);
        end
        
        if isfile(SMILE_events_old)
            delete(SMILE_events_old);
        end
        
    end
    
end

if process_SMILE_events

    if ~isfile(SMILE_events_csv)
        fprintf('Could not process SMILE events for %s %s %s because no .csv was found.\n', subject, task, session);
    else
        SMILE_CreateEvents(subject, task, session);
        fprintf('Processed SMILE events in %s\n', behavioral_folder);
        
        opts = delimitedTextImportOptions("NumVariables", 5);
        opts.DataLines        = [1, Inf];
        opts.Delimiter        = ", ";
        opts.VariableNames    = ["type", "data", "id", "time", "time_stamp"];
        opts.VariableTypes    = ["char", "char", "double", "double", "double"];
        opts.ExtraColumnsRule = "ignore";
        opts.EmptyLineRule    = "read";
        opts                  = setvaropts(opts, ["type", "data"], "EmptyFieldRule", "auto");
        
        communications = readtable(communications_csv);
        save(communications_mat, 'communications');
    end
    
end

if isfile(elemem_events_save)

    if ~default_replacement
        response = input('Elemem events for this session have previously been processed. Do you want to keep these files?(y/n)\n');
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
        event_indices = 1:newline_positions(idx) - 1;
    else
        event_indices = newline_positions(idx - 1) + 1:newline_positions(idx) - 1;
    end
    
    event_holder{idx} = jsondecode(log_text(event_indices));
    
    event_fields = fields(event_holder{idx});
    
    if ~ismember('data', event_fields)
        event_holder{idx}.data = {};
    end
    
    if ~ismember('id', event_fields)
        event_holder{idx}.id = NaN;
    end
    
    if ~ismember('time', event_fields)
        event_holder{idx}.time = NaN;
    end
    
    if ~ismember('time_stamp', event_fields)
        event_holder{idx}.time_stamp = NaN;
    end
    
    if ~ismember('time', event_fields)
        event_holder{idx}.type = 'UNDETERMINED';
    end
    
end

elemem_log = vertcat(event_holder{:});
elemem_log = struct2table(elemem_log);
save(mat_file, 'elemem_log')

end


function opts = get_communication_opts()

opts = delimitedTextImportOptions("NumVariables", 5);
opts.DataLines        = [2, Inf];
opts.Delimiter        = ", ";
opts.VariableNames    = ["type", "data", "id", "time", "time_stamp"];
opts.VariableTypes    = ["char", "char", "double", "double", "double"];
opts.ImportErrorRule  = "error";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule    = "read";
opts                  = setvaropts(opts, ["type", "data"], "EmptyFieldRule", "auto");

end