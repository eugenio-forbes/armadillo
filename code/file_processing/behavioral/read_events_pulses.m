%%% Function to read pulses.csv file from stimulation parameter search experiment session.
%%% Output as table.

function events_sync_pulses = read_events_pulses(events_sync_pulses_file)

%%% Text import options
sync_pulses_options                  = delimitedTextImportOptions("NumVariables", 4);
sync_pulses_options.DataLines        = [2, Inf];
sync_pulses_options.Delimiter        = ",";
sync_pulses_options.VariableNames    = ["subject", "session", "time", "pulse_id"];
sync_pulses_options.VariableTypes    = ["char", "char", "double", "double"];
sync_pulses_options.ExtraColumnsRule = "ignore";
sync_pulses_options.EmptyLineRule    = "read";
sync_pulses_options                  = setvaropts(sync_pulses_options, ["subject", "session"], "WhitespaceRule", "preserve");
sync_pulses_options                  = setvaropts(sync_pulses_options, ["subject", "session"], "EmptyFieldRule", "auto");

%%% Reading table
events_sync_pulses = readtable(events_sync_pulses_file, sync_pulses_options);

end