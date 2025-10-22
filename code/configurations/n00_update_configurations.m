
function n00_update_configurations(root_directory, subject)

%%% List directories
subject_directory = fullfile(root_directory, 'subject_files', subject);
configurations_directory = fullfile(root_directory, 'configurations');
todays_date = char(datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss'));
elemem_directory = fullfile(subject_directory, 'configurations/elemem', todays_date);
smile_directory = strrep(elemem_directory, 'elemem', 'smile');
if ~isfolder(elemem_directory)
    mkdir(elemem_directory);
end
if ~isfolder(smile_directory)
    mkdir(smile_directory);
end

%%% Get parameters from creating configurations
experiment_parameters = n00_get_experiment_parameters(configurations_directory);

%%% Stimulation parameters obtained from configurations directory 'experiment_parameters.json'
included_banks = experiment_parameters.included_banks;
excluded_from_stimulation = experiment_parameters.excluded_from_stimulation;
optimized_stim_parameters = experiment_parameters.optimized_stim_parameters;

%%% Elemem task information
elemem_experiments = {'OPS', 'CPS', 'AR_elemem', 'AR_closed_loop', 'RepFR1', 'RepFR2', 'RepFR1_sp', ...
    'RepFR2_sp', 'CatFR1', 'ICatFR1', 'EFRCourierReadOnly', 'EFRCourierOpenLoop'};
    
with_task = {'AR', 'AR_closed_loop', 'RepFR1', 'RepFR2', 'RepFR1_sp', 'RepFR2_sp', ...
    'CatFR1', 'ICatFR1', 'EFRCourierReadOnly', 'EFRCourierOpenLoop'};

with_stimulation = {'OPS', 'CPS', 'RepFR2', 'RepFR2_sp', 'EFRCourierOpenLoop', 'AR_closed_loop'};

with_classifier = {'CPS', 'AR_closed_loop'};

%%% Get all of the subjects electrodes
session = table;
session.subject = {subject};
subject_electrodes = n00_get_subject_electrodes(root_directory, session);

%%% Process the electrode_list
[subject_electrodes, bad_electrodes, removed_electrodes] = n03_filter_electrode_list(root_directory, subject_electrodes, 'both', false, 'single');
subject_electrodes = sortrows(subject_electrodes, 'channel_number');

%%% Adjust electrode list based on included banks/number of channels
subject_electrodes = adjust_electrode_list(subject_electrodes, included_banks);

%%% Save these tables
save(fullfile(smile_directory, 'subject_electrodes.mat'), 'subject_electrodes');
save(fullfile(smile_directory, 'bad_electrodes.mat'), 'bad_electrodes');
save(fullfile(smile_directory, 'removed_electrodes.mat'), 'removed_electrodes');

monopolar_file = sprintf('%s_%s_mono_L0M0.csv', subject, todays_date);
bipolar_file = strrep(monopolar_file, 'mono', 'bi');
stimulation_file = [sprintf('%s_%s_stimulation_locations_', subject, todays_date), '%s.csv'];

%%% Print electrode list (monopolar) to .csv, then make bipolar pairs, and print
%%% bipolar list to .csv
monopolar_list = make_monopolar_list(subject_electrodes);
writecell(monopolar_list, fullfile(elemem_directory, monopolar_file));

bipolar_list = make_bipolar_list(subject_electrodes);
writecell(bipolar_list, fullfile(elemem_directory, bipolar_file));

bipolar_list = bipolar_list(2:end, :);

stimulation_labels = subject_electrodes.label(~contains(subject_electrodes.neurologist_location, excluded_from_stimulation));

split_pairs = cellfun(@(x) strsplit(x, '_'), bipolar_list(2:end, 1), 'UniformOutput', false);
split_pairs = vertcat(split_pairs{:});

has_stimulation_label = ismember(split_pairs(:, 1), stimulation_labels) | ismember(split_pairs(:, 2), stimulation_labels);
stimulation_pairs = bipolar_list(has_stimulation_label, 1:3);
n_stimulation_pairs = sum(has_stimulation_label);

has_stimulation_targets = n_stimulation_pairs > 0;

if ~has_stimulation_targets
    elemem_experiments(ismember(elemem_experiments, with_stimulation)) = [];
else
    writecell(stimulation_pairs, fullfile(smile_directory, sprintf(stimulation_file, 'all')));
end

for idx = 1:length(elemem_experiments)

    experiment_name = elemem_experiments{idx};
    
    has_task = ismember(experiment_name, with_task);
    has_stimulation = ismember(experiment_name, with_stimulation);
    has_classifier = ismember(experiment_name, with_classifier);
    
    if has_stimulation && has_classifier
        stim_mode = 'closed';
    elseif has_stimulation
        stim_mode = 'open';
    else
        stim_mode = 'none';
    end
    
    global_settings_file = fullfile(configurations_directory, 'elemem/global_settings.json');
    global_settings = jsondecode(fileread(global_settings_file));
    global_settings.connect_to_task_laptop = has_task;
    
    experiment_specs_file = fullfile(configurations_directory, 'elemem/experiment_specs', sprintf('%s.json', experiment_name));
    
    if isfile(experiment_specs_file)
        experiment_specs = jsondecode(fileread(experiment_specs_file));
    else
        experiment_specs = {};
    end
    
    if has_stimulation
    
        stimulation_configuration_file = fullfile(configurations_directory, 'elemem/stimulation_parameters', sprintf('%s.json', experiment_name));
        stimulation_configuration = jsondecode(fileread(stimulation_configuration_file));
        stimulation_configuration.electrodes = '';
        
        stim_channels = make_stim_channels_struct(stimulation_configuration, stimulation_pairs);
        
    else
        stim_channels = [];
    end
    
    temp_experiment = struct;
    temp_experiment.type = experiment_name;
    temp_experiment.stim_mode = stim_mode;
    temp_experiment.experiment_specs = experiment_specs;
    
    if has_classifier
    
        classifier_parameters_file = fullfile(configurations_directory, 'elemem/classifier_parameters', sprintf('%s.json', experiment_name));
        classifier = jsondecode(fileread(classifier_parameters_file));
        classifier.classifier_file_name = 'filename.json';
        
        temp_experiment.classifier                = classifier;
        temp_experiment.previous_sessions         = 'filename.json';
        temp_experiment.optimized_stim_parameters = optimized_stim_parameters;
        
    end
    
    configuration = struct;
    configuration.bipolar_electrode_config_file = bipolar_file;
    configuration.electrode_config_file         = monopolar_file;
    configuration.exclude_session               = false;
    configuration.experiment                    = temp_experiment;
    configuration.global_settings               = global_settings;
    configuration.subject                       = subject;
    
    if has_stimulation
        template_file_name = fullfile(elemem_directory, sprintf('%s_%s_%s_%s.json', subject, experiment_name, '%s', todays_date));
    else
        configuration_file = fullfile(elemem_directory, sprintf('%s_%s_%s.json', subject, experiment_name, todays_date));
    end
    
    if strcmp(experiment_name, 'OPS')
        save_one_config_per_shank(template_file_name, configuration, temp_experiment, stim_channels, stimulation_pairs);
    elseif has_stimulation
        save_one_config_per_pair(template_file_name, configuration, temp_experiment, stim_channels, stimulation_pairs);
    else
        n00_save_config(configuration_file, configuration);
    end
    
end

end


function bipolar_list = make_bipolar_list(electrode_list)

header_row = {'#Label', '#Lead1', '#Lead2', '#Surface Area'};

is_bipolar_pair = electrode_list.has_bipolar_reference;
n_bipolar_pairs = sum(is_bipolar_pair);

lead1 = electrode_list.channel_number(is_bipolar_pair);
lead2 = electrode_list.bipolar_reference(is_bipolar_pair);

if iscell(lead2)
    lead2 = [lead2{:}]';
end

anode_label = electrode_list.label(is_bipolar_pair);
cathode_label = arrayfun(@(x) electrode_list.label(electrode_list.channel_number==x), lead2, 'UniformOutput', false);

label = strcat(anode_label, '_', cathode_label);
label = cellfun(@(x) strjoin(x, ''), label, 'UniformOutput', false);

lead1 = arrayfun(@num2str, lead1, 'UniformOutput', false);
lead2 = arrayfun(@num2str, lead2, 'UniformOutput', false);

surface_area = repelem({'6.184'}, n_bipolar_pairs, 1);

bipolar_list = [header_row; [label, lead1, lead2, surface_area]];

end


function monopolar_list = make_monopolar_list(electrode_list)

n_electrodes = height(electrode_list);

header_row = {'#Label', '#Lead', '#Surface Area'};

label = electrode_list.label;

lead = electrode_list.channel_number;
lead = arrayfun(@num2str, lead, 'UniformOutput', false);

surface_area = repelem({'6.184'}, n_electrodes, 1);

monopolar_list = [header_row; [label, lead, surface_area]];

end


function adjusted_electrode_list = adjust_electrode_list(electrode_list, included_banks)

n_banks = length(included_banks);

bank_electrodes = cell(n_banks, 1);

for idx = 1:n_banks
    
    bank = included_banks{idx};
    
    switch bank
        case 'A'
            bank_numbers = 1:64;
        
        case 'B'
            bank_numbers = 65:128;
        
        case 'C'
            bank_numbers = 129:192;
        
        case 'D'
            bank_numbers = 193:256;
    end
    
    current_numbers = (1:64) + (64*(idx-1));
    
    corresponding_electrodes = electrode_list(ismember(electrode_list.channel_number, bank_numbers), :);
    has_bipolar_reference = corresponding_electrodes.has_bipolar_reference;
    bipolar_reference = corresponding_electrodes.bipolar_reference;
    
    channel_number = arrayfun(@(x) current_numbers(bank_numbers==x), corresponding_electrodes.channel_number);
    
    bipolar_reference(has_bipolar_reference) = arrayfun(@(x) current_numbers(bank_numbers == x), [bipolar_reference{has_bipolar_reference}], 'UniformOutput', false);
    
    corresponding_electrodes.channel_number = channel_number;
    corresponding_electrodes.bipolar_reference = bipolar_reference;
    
    bank_electrodes{idx} = corresponding_electrodes;
    
end

adjusted_electrode_list = vertcat(bank_electrodes{:});

end


function stim_channels = make_stim_channels_struct(stimulation_configuration, stimulation_pairs)

n_pairs = size(stimulation_pairs, 1);

stim_channels = repmat(stimulation_configuration, n_pairs, 1);

for idx = 1:n_pairs
    stim_channels(idx).electrodes = stimulation_pairs{idx, 1};
end

end


function save_one_config_per_shank(template_file_name, configuration, temp_experiment, stim_channels, stimulation_pairs)

parameters = stim_channels(1);

max_amplitude = max(parameters.amplitude_range_mA);
max_frequency = max(parameters.frequency_range_Hz);
max_duration = max(parameters.duration_range_ms);

labels = cellfun(@(x) x(1:2), stimulation_pairs(:, 1), 'UniformOutput', false);
channel_numbers = cellfun(@str2double, stimulation_pairs(:, 2:3));

if length(labels) > 1
    shanks = unique(labels);
else
    labels = labels{1};
    shanks = labels;
end

n_shanks = length(shanks);

for idx = 1:n_shanks

    is_part_of_shank = contains(labels, shanks{idx});
    
    these_stim_channels = stim_channels(is_part_of_shank);
    these_channel_numbers = channel_numbers(is_part_of_shank, :);
    
    stim_parameters = struct;
    stim_parameters.amplitudes_mA  = max_amplitude;
    stim_parameters.durations_ms   = max_duration;
    stim_parameters.frequencies_Hz = max_frequency;
    stim_parameters.channels       = these_channel_numbers;
    
    experiment = temp_experiment;
    experiment.stim_channels   = these_stim_channels;
    experiment.stim_parameters = stim_parameters;
    
    configuration.experiment = experiment;
    
    configuration_file = sprintf(template_file_name, shanks{idx});
    
    n00_save_config(configuration_file, configuration);

end

end


function save_one_config_per_pair(template_file_name, configuration, temp_experiment, stim_channels, stimulation_pairs)

n_pairs = length(stim_channels);

for idx = 1:n_pairs
    
    label = stimulation_pairs{idx, 1};
    
    configuration_file = sprintf(template_file_name, label);
    
    experiment = temp_experiment;
    experiment.stim_channels = stim_channels(idx);
    
    configuration.experiment = experiment;
    
    n00_save_config(configuration_file, configuration)

end

end