function bipolar_jacksheet = n00_read_bipolar_jacksheet(elemem_folder)

bipolar_jacksheet_file = dir(fullfile(elemem_folder, '*_bi_*.csv'));

if ~isempty(bipolar_jacksheet_file)
    bipolar_jacksheet_file = bipolar_jacksheet_file(~contains({bipolar_jacksheet_file.name}, {'~', '._'}));
end

if ~isempty(bipolar_jacksheet_file)
    bipolar_jacksheet_file = fullfile({bipolar_jacksheet_file.folder}, {bipolar_jacksheet_file.name});
    bipolar_jacksheet_file = bipolar_jacksheet_file{1};
else
    error('No bipolar jackseet was found in %s.\n', elemem_folder);
end

opts = delimitedTextImportOptions("NumVariables", 4);
opts.DataLines = [2, Inf];
opts.Delimiter = ", ";
opts.VariableNames = ["Label", "Lead1", "Lead2", "SurfaceArea"];
opts.VariableTypes = ["char", "double", "double", "double"];
opts = setvaropts(opts, "Label", "WhitespaceRule", "preserve");
opts = setvaropts(opts, "Label", "EmptyFieldRule", "auto");

bipolar_jacksheet = readtable(bipolar_jacksheet_file, opts);

end