%%% This function takes a list of events and electrodes,
%%% and based on input parameters, generates normalized power
%%% features in the same manner as Elemem software.
%%% Returns features to be used for classifier training.

function features = n00_get_features(electrode_list, events, sample_size, event_offset, buffer_duration, frequencies, morlet_width, n_normalization_events)

channels = electrode_list.channel_number;
[~, sorting_idx] = sortrows(channels, 'ascend');
electrode_list = electrode_list(sorting_idx, :);

channels = electrode_list.channel_number;
references = electrode_list.reference;
n_electrodes = height(electrode_list);

eegfile = unique(events.eegfile);
eegfile = eegfile(1);
first_offset = buffer_duration * 20;
events = table2struct(events);

normalization_event_length = (2 * buffer_duration) + sample_size;
normalization_offsets = first_offset:normalization_event_length:first_offset + ((n_normalization_events - 1) * normalization_event_length);

normalization_events = table;
normalization_events.eegoffset = normalization_offsets';
normalization_events.eegfile   = repelem(eegfile, n_normalization_events, 1);
normalization_events = table2struct(normalization_events);

normalized_power_values = cell(1, n_electrodes);

parfor idx = 1:n_electrodes
    
    channel = channels(idx);
    reference = references(idx);
    
    normalization_channel_signal = gete(channel, normalization_events, sample_size, event_offset, buffer_duration);
    normalization_reference_signal = gete(reference, normalization_events, sample_size, event_offset, buffer_duration);
    normalization_bipolar_signal = normalization_channel_signal - normalization_reference_signal;
    
    [~, normalization_power] = multiphasevec3(frequencies, normalization_bipolar_signal, 1000, morlet_width);
    bad_power = isnan(normalization_power) | normalization_power == 0;
    normalization_power(bad_power) = 0.0000000000000001 * ones(sum(bad_power(:)), 1);
    normalization_power = squeeze(mean(log10(normalization_power), 3));
    
    normalization_means = mean(normalization_power, 1, 'omitnan');
    normalization_stds = std(normalization_power, [], 1, 'omitnan');
    
    channel_signal = gete(channel, events, sample_size, event_offset, buffer_duration);
    reference_signal = gete(reference, events, sample_size, event_offset, buffer_duration);
    bipolar_signal = channel_signal - reference_signal;
    
    [~, power] = multiphasevec3(frequencies, bipolar_signal, 1000, morlet_width);
    bad_power = isnan(power) | power == 0;
    power(bad_power) = 0.0000000000000001 * ones(sum(bad_power(:)), 1);
    power = squeeze(mean(log10(power), 3));
    
    normalized_power_values{idx} = (power - normalization_means) ./ normalization_stds;
    
end

features = horzcat(normalized_power_values{:});

end