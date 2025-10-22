%%% Function to read communications.csv file from stimulation parameter search experiment session.
%%% Output as table.

function communications = read_communications(communications_file)

%%% Text import options
communications_options                  = delimitedTextImportOptions("NumVariables", 8);
communications_options.DataLines        = [2, Inf];
communications_options.Delimiter        = ",";
communications_options.VariableNames    = ["subject", "session", "message_type", "data", "sender", "server_time", "client_time", "message_id"];
communications_options.VariableTypes    = ["char", "char", "char", "char", "char", "double", "double", "double"];
communications_options.ExtraColumnsRule = "ignore";
communications_options.EmptyLineRule    = "read";
communications_options                  = setvaropts(communications_options, ["subject", "session", "message_type", "data", "sender"], "WhitespaceRule", "preserve");
communications_options                  = setvaropts(communications_options, ["subject", "session", "message_type", "data", "sender"], "EmptyFieldRule", "auto");
communications_options                  = setvaropts(communications_options, ["server_time", "client_time", "message_id"], "ThousandsSeparator", ",");

%%% Reading table
communications = readtable(communications_file, communications_options);

end