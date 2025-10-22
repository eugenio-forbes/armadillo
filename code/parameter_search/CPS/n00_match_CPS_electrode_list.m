function electrode_list = n00_match_CPS_electrode_list(electrode_list, elemem_folder)

monopolar_jacksheet = n00_read_monopolar_jacksheet(elemem_folder);

elemem_labels = monopolar_jacksheet.Label;
match = ismember(electrode_list.label, elemem_labels);

electrode_list(~match, :) = [];

end