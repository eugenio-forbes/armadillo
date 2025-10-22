%%% Function to read clinician_positive_scale.csv file from stimulation parameter search experiment session.
%%% Output as table.

function clinician_positive_scale = read_clinician_positive_scale(clinician_positive_scale_file)

%%% Text import options
clinician_positive_scale_options                  = delimitedTextImportOptions("NumVariables", 6);
clinician_positive_scale_options.DataLines        = [2, Inf];
clinician_positive_scale_options.Delimiter        = ",";
clinician_positive_scale_options.VariableNames    = ["post_0m", "post_10m", "post_20m", "post_30m", "post_45m", "post_60m"];
clinician_positive_scale_options.VariableTypes    = ["double", "double", "double", "double", "double", "double"];
clinician_positive_scale_options.ExtraColumnsRule = "ignore";
clinician_positive_scale_options.EmptyLineRule    = "read";

%%% Reading table
clinician_positive_scale = readtable(clinician_positive_scale_file, clinician_positive_scale_options);

end