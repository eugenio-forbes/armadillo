%%% This function is the master function for performing the analyses 
%%% of stimulation parameter search.
%%%
%%% After performing stimulation parameter search experiments files 
%%% should be placed in the following folders:
%%%
%%% - Events folders (named with respective date, containing 
%%%   stimulation events, psych ratings/scores, communications)
%%%   should be placed in armadillo/subject_files/(respective subject code)/PS/
%%% - Nihon Kohden recording folders (named with respective task and date) 
%%%   should be placed in armadillo/subject_files/(respective subject code)/raw/nihon_kohden/
%%% - Blackrock recording folders (named with respective date)
%%%   should be placed in armadillo/subject_files/(respective subject code)/raw/blackrock/
%%%
%%% !!! At the very least, subject folder must contain a jacksheet
%%% or a recording before running code so that at least configurations
%%% for experimental sessions can be produced.
%%%
%%% This function will update subject/session/electrode lists,
%%% update configuration files used in experiments, process and
%%% align events files, make plots for assessing signal quality,
%%% create classifiers using all subject data and plot results,
%%% analyse and plot changes to classifier results in response
%%% to combinations of stimulation parameters. 

function update_subject(varargin)
if isempty(varargin)                                        %%% May run code from editor editing parameters below:
    root_directory = '/path/to/armadillo/parent_directory'; %%% (character vector) Parent directory of armadillo folder
    subject = 'SC000';                                      %%% (character vector) Subject code
else                                                        %%% Otherwise function expects arguments in this order:
    root_directory = varargin{1};
    subject = varargin{2};
end

%%% Declare directories
analysis_directory       = fullfile(root_directory, 'armadillo');
list_directory           = fullfile(analysis_directory, 'lists');
subject_files            = fullfile(analysis_directory, 'subject_files');
data_directory           = fullfile(analysis_directory, 'data');
configurations_directory = fullfile(analysis_directory, 'configurations');
imaging_directory        = fullfile(root_directory, 'imaging_pipeline');
parameter_directory      = fullfile(analysis_directory, 'experiment_parameters');

if ~isfolder(list_directory)
    mkdir(list_directory);
end

%%% Check that there is at least a jacksheet or a Nihon Kohden/Blackrock EEG recording in the subject's folder
subject_directory = fullfile(subject_files, subject);
nihon_kohden_folder = fullfile(subject_directory, 'raw/nihon_kohden');
blackrock_folder = strrep(nihon_kohden_folder, 'nihon_kohden', 'blackrock');

if ~isfolder(subject_directory)
    error('There is no folder for subject %s in %s. Verify and try again.', subject, subject_files);
end

%%% Macs save trash files adding these strings to good file names. To be removed from search.
bad_file_patterns = {'._', '~'};

docs_files = dir(fullfile(subject_directory, 'docs/*jacksheet*.txt'));
bad_files = contains({docs_files.name}, bad_file_patterns);
docs_files(bad_files) = [];
jacksheet_file = fullfile({docs_files.folder}, {docs_files.name});
jacksheet_exists = ~isempty(jacksheet_file);

nihon_kohden_files = dir(fullfile(nihon_kohden_folder, '*/*.EEG'));
bad_files = contains({nihon_kohden_files.name}, bad_file_patterns);
nihon_kohden_files(bad_files) = [];
nihon_kohden_file = fullfile({nihon_kohden_files.folder}, {nihon_kohden_files.name});
nihon_kohden_exists = ~isempty(nihon_kohden_file);

blackrock_files = dir(fullfile(blackrock_folder, '*/*.ns*'));
bad_files = contains({blackrock_files.name}, bad_file_patterns);
blackrock_files(bad_files) = [];
blackrock_file = fullfile({blackrock_files.folder}, {blackrock_files.name});
blackrock_exists = ~isempty(blackrock_file);

if jacksheet_exists || nihon_kohden_exists || blackrock_exists
    if ~jacksheet_exists
        if nihon_kohden_exists
            update_jacksheet_from_nihon_kohden(analysis_directory, subject);
        else
            blackrock_has_labels = update_jacksheet_from_blackrock(analysis_directory, subject);
            if ~blackrock_has_labels
                error('%s does not have jacksheet or NK recordings in %s. Could not find labels in Blackrock recordings.', subject, subject_files)
            end
        end
    end
else
    error('%s does not have jacksheet or raw recordings in %s.', subject, subject_files)
end

%%% Recordings for each session must be on respective folder for sessions to be processed/aligned.
if nihon_kohden_exists || blackrock_exists
    
    %%% Split Nihon Kohden and Blackrock EEGs, and update recording lists
    n00_update_recording_lists(analysis_directory, subject);

    %%% Check whether subject has completed behavioral sessions, get events info, matching recordings and update session list
    has_behavioral_sessions = n00_update_session_list(analysis_directory, subject);
    
    if has_behavioral_sessions
        
        %%% Gather subject's electrode information associated to each session and update electrode list.
        n00_update_electrode_list(analysis_directory);

        %%% Check whether recordings have sync pulse data and add sync pulse information to session list.
        n00_check_sync_pulses(analysis_directory, subject);
                
        %%% Use sync pulses to align behavioral data to EEG data and plot alignment results.
        n00_check_alignment(analysis_directory, subject);

        %%% Use events information and alignment results to produced unified events files with adjusted events times.
        n00_check_events(analysis_directory, subject);

        %%% For parallel processing, save a copy of concatenated events for each electrode.
        n00_make_events_copies(analysis_directory, subject);

        %%% Produce plots of sample signal and power spectral density to assess signal quality.
        n00_check_signal_quality(analysis_directory, subject);

        %%% Use all available event data to train classifier and update classifier weigths.
        n00_update_classifiers(analysis_directory, subject);

        %%% Using updated classifier weights and all available stimulation events, update parameter search results.
        n00_update_parameter_search(analysis_directory, subject);

        %%% Update classifier weight brain plots.
        n00_plot_classifier_weights(analysis_directory, subject);

        %%% Update subject list with session information
        n00_update_subject_list(analysis_directory, subject);
    end
end

%%% Update SMILE and Elemem configurations for subject
n00_update_configurations(analysis_directory, subject);

end