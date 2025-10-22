%%% This function takes an electrode list and for every channel
%%% generates labels consisting of a channel and respective bipolar reference labels 

function formatted_labels = n00_get_bipolar_labels(electrode_list)

n_electrodes = height(electrode_list);
formatted_labels = repelem({''}, n_electrodes, 1);

has_bipolar_reference = electrode_list.has_bipolar_reference;
session_IDs           = electrode_list.session_ID;
channel_number        = electrode_list.channel_number;
bipolar_reference     = electrode_list.bipolar_reference;
labels                = electrode_list.label;

for idx = 1:n_electrodes

    if has_bipolar_reference(idx)
        bipolar_label = labels{channel_number == bipolar_reference(idx) & session_IDs == session_IDs(idx)};
        labels{idx} = sprintf('%s_%s', labels{idx}, bipolar_label);
    end

end

end