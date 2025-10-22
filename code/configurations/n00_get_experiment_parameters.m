function experiment_parameters = n00_get_experiment_parameters(configurations_directory)

experiment_parameters_file = fullfile(configurations_directory, 'experiment_parameters.json');

experiment_parameters = jsondecode(fileread(experiment_parameters_file));

end