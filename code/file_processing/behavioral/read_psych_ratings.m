%%% Function to read pych_ratings.csv file from stimulation parameter search experiment session.
%%% Output as table.

function psych_ratings = read_psych_ratings(psych_ratings_file)

%%% Text import options
psych_ratings_options                  = delimitedTextImportOptions("NumVariables", 6);
psych_ratings_options.DataLines        = [2, Inf];
psych_ratings_options.Delimiter        = ",";
psych_ratings_options.VariableNames    = ["subject", "session", "test", "scale", "rating", "time"];
psych_ratings_options.VariableTypes    = ["char", "char", "char", "char", "double", "double"];
psych_ratings_options.ExtraColumnsRule = "ignore";
psych_ratings_options.EmptyLineRule    = "read";
psych_ratings_options                  = setvaropts(psych_ratings_options, ["subject", "session", "test", "scale"], "WhitespaceRule", "preserve");
psych_ratings_options                  = setvaropts(psych_ratings_options, ["subject", "session", "test", "scale"], "EmptyFieldRule", "auto");

%%% Reading table
psych_ratings = readtable(psych_ratings_file, psych_ratings_options);

end