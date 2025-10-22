%%% Function to read pych_scores.csv file from stimulation parameter search experiment session.
%%% Output as table.

function psych_scores = read_psych_scores(psych_scores_file)

%%% Text import options
psych_scores_options                  = delimitedTextImportOptions("NumVariables", 5);
psych_scores_options.DataLines        = [2, Inf];
psych_scores_options.Delimiter        = ",";
psych_scores_options.VariableNames    = ["subject", "session", "test", "score", "time"];
psych_scores_options.VariableTypes    = ["char", "char", "char", "double", "double"];
psych_scores_options.ExtraColumnsRule = "ignore";
psych_scores_options.EmptyLineRule    = "read";
psych_scores_options                  = setvaropts(psych_scores_options, ["subject", "session", "test"], "WhitespaceRule", "preserve");
psych_scores_options                  = setvaropts(psych_scores_options, ["subject", "session", "test"], "EmptyFieldRule", "auto");

%%% Reading table
psych_scores = readtable(psych_scores_file, psych_scores_options);

end