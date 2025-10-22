function n03_align_SMILE_with_elemem(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    subject = 'SC000';
    task = 'AR_elemem';
    session = 0;         %%% integer
    date = '2020-01-01'; %%% 'yyyy-mm-dd' format
    time = '12-00-00';   %%% 'hh-mm-ss' format
    alignment_mode = 'elemem';  %%% blackrock, elemem, or clinical
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
formatted_time = time([1, 2, 4, 5]);

%%% List directories and file names
subject_directory  = fullfile(root_directory, 'subject_files', subject);
behavioral_folder  = fullfile(subject_directory, 'behavioral', task, sprintf('session_%d', session));
SMILE_events_mat   = fullfile(behavioral_folder, 'events.mat');
SMILE_events_old   = fullfile(behavioral_folder, 'events.mat.old');
SMILE_pulses       = fullfile(behavioral_folder, 'pulses.txt');
communications_mat = fullfile(behavioral_folder, 'communications.mat');
elemem_log_mat     = fullfile(behavioral_folder, 'elemem_log.mat');
noreref_folder     = fullfile(subject_directory, 'eeg.noreref');
clinical_filestem  = fullfile(noreref_folder, sprintf('%s_%s_%d_%s_%s', subject, task, session, formatted_date, formatted_time));
blackrock_filestem = fullfile(noreref_folder, sprintf('%s_%s_%d_%s_%s_blackrock', subject, task, session, formatted_date, formatted_time));
elemem_filestem    = fullfile(noreref_folder, sprintf('%s_%s_%d_%s_%s_elemem', subject, task, session, formatted_date, formatted_time));

clinical_sync = [clinical_filestem, '.259'];
blackrock_sync = [blackrock_filestem, '.257'];

switch alignment_mode
    case 'clinical'
        alignment_files = {SMILE_events_mat, SMILE_pulses, clinical_filestem, clinical_sync};
    
    case 'blackrock'
        alignment_files = {SMILE_events_mat, SMILE_pulses, blackrock_filestem, blackrock_sync};
    
    case 'elemem'
        alignment_files = {SMILE_events_mat, elemem_log_mat, communications_mat, elemem_filestem};
end

if isfile(SMILE_events_old)

    if ~default_replacement
        response = input('SMILE events have previously been aligned. Delete and realign?(y/n)\n', 's');
    else
        response = 'y';
    end

    if strcmp(response, 'y')

        if isfile(SMILE_events_mat)
            delete(SMILE_events_mat)
        end

        movefile(SMILE_events_old, SMILE_events_mat)

    else
        fprintf('Keeping previous files and not realigning %s.\n', SMILE_events_mat);
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
            align_to_clinical(alignment_files, SMILE_events_old);

        case 'blackrock'
            align_to_blackrock(alignment_files, SMILE_events_old);

        case 'elemem'
            align_to_elemem(SMILE_events_mat, SMILE_events_old, elemem_log_mat, communications_mat, elemem_filestem);
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


function align_to_elemem(SMILE_events_mat, SMILE_events_old, elemem_events_mat, communications_mat, elemem_filestem)

load(SMILE_events_mat, 'events');
load(elemem_events_mat, 'elemem_log');
load(communications_mat, 'communications');

events = struct2table(events);
events(events.mstime < 0, :) = [];
n_events = height(events);

events.eegfile = repelem({elemem_filestem}, n_events, 1);
event_times = events.mstime;
eegoffset = zeros(n_events, 1);

eeg_time_start = elemem_log.time(strcmp(elemem_log.type, 'EEGSTART'));
elemem_log(ismember(elemem_log.type, {'EEGSTART', 'ELEMEM', 'signal_quality'}), :) = [];
communications.time = (elemem_log.time - eeg_time_start);

elemem_times = communications.time;
computer_times = communications.time_stamp * 1000;
event_times = event_times - computer_times(1) + elemem_times(1);
computer_times = computer_times - computer_times(1) + elemem_times(1);
discrepancy = elemem_times - computer_times;

for idx = 1:n_events
    closest_preceding_communication = find(computer_times < event_times(idx), 1, 'last');
    this_discrepancy = discrepancy(closest_preceding_communication);
    eegoffset(idx) = event_times(idx) + this_discrepancy;
end

events.mstime = ceil(eegoffset);
events.eegoffset = ceil(eegoffset);
events = table2struct(events);

movefile(SMILE_events_mat, SMILE_events_old);
save(SMILE_events_mat, 'events');

end