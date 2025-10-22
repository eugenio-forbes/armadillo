function CPS_analysis(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    subject = 'SC000';
    task = 'CPS';
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

%%% List directories and file names
subject_directory = fullfile(root_directory, 'shared/lega_ansir/subjFiles', subject);
elemem_folder = fullfile(subject_directory, 'raw', sprintf('%s_%s_%d_%s_%s', subject, task, session, date, time));
elemem_events_file = fullfile(elemem_folder, 'elemem_log.mat');
plot_file_name = fullfile(elemem_folder, sprintf('%s_%s_%d', subject, task, session));

session_list = table;
session_list.subject = {subject};
session_list.session = {session};
session_list.task    = {task};

electrode_list = n00_get_subject_electrodes(session_list);

electrode_list = n00_match_CPS_electrode_list(electrode_list, elemem_folder);

load(elemem_events_file, 'elemem_log');

events = n00_process_classification_events(elemem_folder, elemem_log);
events(~events.threshold_crossed, :) = [];

CPS_results = n01_get_CPS_results(events);

n02_plot_CPS_results(plot_file_name, CPS_results);

n03_plot_CPS_trajectories(plot_file_name, events);

end