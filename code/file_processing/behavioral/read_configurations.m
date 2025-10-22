%%% Function to read configurations.json file from stimulation parameter search experiment session.
%%% Output as struct.

function configurations = read_configurations(configurations_file)

configurations = jsondecode(fileread(configurations_file));

end