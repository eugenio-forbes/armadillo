function n03_align_PS_events_with_clinical(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/aramdillo/parent_directory';
    subject = 'SC000';
    task = 'PS_clinical';
    session = 0;         %%% integer
    date = '2020-01-01'; %%% 'yyyy-mm-dd' format
    alignment_mode = 'clinical';  %%% blackrock, elemem, or clinical
    default_replacement = false;
else
    root_directory = varargin{1};
    subject = varargin{2};
    task = varargin{3};
    session = varargin{4};
    date = varargin{5};
    time = varargin{6};
    alignment_mode = varargin{7};
    default_replacement = false;
end

%%% Currently only intended for macros sampled at 1000Hz in BR.
formatted_date = datestr(datetime(date), 'ddmmmyy');

%%% List directories and file names
subject_directory  = fullfile(root_directory, 'subject_files', subject);
behavioral_folder  = fullfile(subject_directory, 'behavioral', task, sprintf('session_%d', session));
events_mat         = fullfile(behavioral_folder, 'events.mat');
events_old         = fullfile(behavioral_folder, 'events.mat.old');
pulses_file        = fullfile(behavioral_folder, 'pulses.txt');
communications_mat = fullfile(behavioral_folder, 'communications.mat');
elemem_log_mat     = fullfile(behavioral_folder, 'elemem_log.mat');
noreref_folder     = fullfile(subject_directory, 'eeg.noreref');
clinical_filestem  = fullfile(noreref_folder, sprintf('%s_%s_%d_%s', subject, task, session, formatted_date));
blackrock_filestem = fullfile(noreref_folder, sprintf('%s_%s_%d_%s', subject, task, session, formatted_date));
elemem_filestem    = fullfile(noreref_folder, sprintf('%s_%s_%d_%s_%s', subject, task, session, formatted_date));

clinical_sync = [clinical_filestem, '.259'];
blackrock_sync = [blackrock_filestem, '.257'];

switch alignment_mode
    case 'clinical'
        alignment_files = {events_mat, pulses_file, clinical_filestem, clinical_sync};
    
    case 'blackrock'
        alignment_files = {events_mat, pulses_file, blackrock_filestem, blackrock_sync};
    
    case 'elemem'
        alignment_files = {events_mat, elemem_log_mat, communications_mat, elemem_filestem};
end

if isfile(events_old)

    if ~default_replacement
        response = input('SMILE events have previously been aligned. Delete and realign?(y/n)\n', 's');
    else
        response = 'y';
    end
    
    if strcmp(response, 'y')
    
        if isfile(events_mat)
            delete(events_mat)
        end
        
        movefile(events_old, events_mat)
        
    else
        fprintf('Keeping previous files and not realigning %s.\n', events_mat);
        return
    end
    
end

[missing, missing_files] = check_missing_files(alignment_files);

if any(missing)

    n_missing = sum(missing);
    fprintf('Could not align SMILE events using %s mode. %d missing files:\n', alignment_mode, n_missing);

    for idx = 1:n_missing
        fprintf('%d.- %s', missing_files{idx});
    end

else

    switch alignment_mode
        case 'clinical'
            align_to_clinical(alignment_files, events_old, pulses_file, clinical_filestem);

        case 'blackrock'
            align_to_blackrock(alignment_files, events_old);

        case 'elemem'
            align_to_elemem(events_mat, events_old, elemem_log_mat, communications_mat, elemem_filestem);
    end

end

end


function [missing, missing_files] = check_missing_files(alignment_files)

n_files = length(alignment_files);
missing = false(n_files, 1);

for idx = 1:n_files

    check_directory = dir([alignment_files{idx}, '*']);

    if ~isempty(check_directory)

        check_files = fullfile({check_directory.folder}, {check_directory.name});
        check_files(contains(check_files, {'~', '._'})) = [];

        if isempty(check_files)
            missing(idx) = true;
        end

    else
        missing(idx) = true;
    end

end

missing_files = alignment_files(missing);

end


function align_to_clinical(events_mat, events_old, pulses_file, clinical_filestem)

load(events_mat, 'events');
if isstruct(events)
    events = struct2table(events);
end

events(events.mstime < 0, :) = [];
n_events = height(events);

events.eegfile = repelem({clinical_filestem}, n_events, 1);
event_times = events.mstime;
eegoffset = zeros(n_events, 1);

for idx = 1:n_events
    closest_preceding_communication = find(computer_times < event_times(idx), 1, 'last');
    this_discrepancy = discrepancy(closest_preceding_communication);
    eegoffset(idx) = event_times(idx) + this_discrepancy;
end

events.mstime = ceil(eegoffset);
events.eegoffset = ceil(eegoffset);
events = table2struct(events);

movefile(events_mat, SMILE_events_old);
save(events_mat, 'events');

end