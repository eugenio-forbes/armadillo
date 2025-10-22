function PS_analysis(varargin)
if isempty(varargin)
    %%% Directory information
    root_directory = '/path/to/armadillo/parent_directory';
    username = 'username';
    analysis_folder = 'armadillo';
    subject = 'SC000';
    EEG_system = 'clinical';
else
    root_directory = varargin{1};
    username = varargin{2};
    analysis_folder = varargin{3};
    subject = varargin{4};
    EEG_system = varargin{5};
end

%%% List directories and file names
analysis_directory = fullfile(root_directory, username, analysis_folder);
subject_directory = fullfile(analysis_directory, 'configurations', subject);
task_directory = fullfile(subject_directory, 'behavioral', sprintf('PS_%s', EEG_system));
plots_directory = fullfile(subject_directory, 'plots');
if ~isfolder(plots_directory)
    mkdir(plots_directory)
end

plot_file_name = fullfile(plots_directory, subject);

load(fullfile(task_directory, 'all_events.mat'), 'all_events')

PS_results = n02_get_PS_results(all_events);

n03_plot_PS_results(plot_file_name, PS_results);

n04_plot_PS_trajectories(plot_file_name, events);

end