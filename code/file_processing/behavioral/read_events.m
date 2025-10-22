%%% Function to read events.csv file from stimulation parameter search experiment session.
%%% Output as table.

function events = read_events(events_file)

%%% Text import options
events_options                  = delimitedTextImportOptions("NumVariables", 12);
events_options.DataLines        = [2, Inf];
events_options.Delimiter        = ",";
events_options.VariableNames    = ["subject", "session", "event_type", "label", "anode", "cathode", "amplitude", "frequency", "pulse_width", "duration", "time", "trial_idx"];
events_options.VariableTypes    = ["char", "char", "char", "char", "double", "double", "double", "double", "double", "double", "double", "double"];
events_options.ExtraColumnsRule = "ignore";
events_options.EmptyLineRule    = "read";
events_options                  = setvaropts(events_options, ["subject", "session", "event_type", "label"], "WhitespaceRule", "preserve");
events_options                  = setvaropts(events_options, ["subject", "session", "event_type", "label"], "EmptyFieldRule", "auto");

%%% Reading table
events = readtable(events_file, events_options);

end