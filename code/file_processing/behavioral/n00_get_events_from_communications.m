%%% In case stimulation events are missing in session folder,
%%% this function will generate stimulation events file from
%%% client-server communications file.

function events = n00_get_events_from_communications(subject, session, communications)

is_configuration = strcmp(communications.message_type, 'STIMULATION_CONFIGURATION');
configurations = communications(is_configuration, :);
n_events = sum(is_configuration);

cell_array = cell(n_events, 1);
nan_array = NaN(n_events, 1);

subject     = repelem({subject}, n_events, 1);
session     = repelem({session}, n_events, 1);
label       = cell_array;
anode       = nan_array;
cathode     = nan_array;
amplitude   = nan_array;
frequency   = nan_array;
pulse_width = nan_array;
duration    = nan_array;
mstime      = nan_array;

for idx = 1:n_events

    data = configurations.data{idx};
    
    if contains(data, '''')
        data = strrep(data, '''', '"');
    end
    
    data = jsondecode(data);
    
    label{idx}       = data.label;
    anode(idx)       = str2double(data.anode);
    cathode(idx)     = str2double(data.cathode);
    amplitude(idx)   = data.amplitude;
    frequency(idx)   = data.frequency;
    pulse_width(idx) = data.pulse_width;
    duration(idx)    = data.duration;
    mstime(idx)      = configurations.client_time(idx) * 1000;
    
end

events = table(subject, session, label, anode, cathode, amplitude, frequency, pulse_width, duration, mstime);
events = table2struct(events);
save(events_file, 'events');

end