function monopolar_jacksheet = n00_read_monopolar_jacksheet(elemem_folder)

monopolar_jacksheet_file = dir(fullfile(elemem_folder, '*_mono_*.csv'));

if ~isempty(monopolar_jacksheet_file)
    monopolar_jacksheet_file = monopolar_jacksheet_file(~contains({monopolar_jacksheet_file.name}, {'~', '._'}));
end

if ~isempty(monopolar_jacksheet_file)
    monopolar_jacksheet_file = fullfile({monopolar_jacksheet_file.folder}, {monopolar_jacksheet_file.name});
    monopolar_jacksheet_file = monopolar_jacksheet_file{1};
else
    error('No monopolar jackseet was found in %s.\n', elemem_folder);
end

%%% Import options
opts = delimitedTextImportOptions("NumVariables", 3);
opts.DataLines = [2, Inf];
opts.Delimiter = ", ";
opts.VariableNames = ["Label", "Lead", "SurfaceArea"];
opts.VariableTypes = ["char", "double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, "Label", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Label", "EmptyFieldRule", "auto");

%%% Read jacksheet
monopolar_jacksheet = readtable(monopolar_jacksheet_file, opts);

end