%%% This function uses client-server communications to estimate
%%% the time elapsed from the moment that stimulation is commanded by client
%%% to the moment that stimulation is actually delivered by server.
%%% With this, stimulation event times are adjusted to accurately reflect stimulation onset.
%%% Function returns stimulation events table.

function stimulation_events = adjust_stimulation_times(stimulation_events, communications, parameters_used_file)

n_events = height(stimulation_events);
event_times = stimulation_events.mstime;
adjusted_event_times = zeros(n_events, 1);

keywords = {'STIMULATION_CONFIGURATION', 'DELIVERING_STIMULUS', 'SHAM', 'SHAMMING'};

communications(~ismember(communications.message_type, keywords), :) = [];

client_times = communications.client_time * 1000; %%% Because it is originally in seconds
server_times = communications.server_time / 10;   %%% Because it is originally in tenths of milliseconds

client_sends = strcmp(communications.sender, 'client');
server_sends = strcmp(communications.sender, 'server');

server_indices = find(server_sends);

is_stimulation_communication = contains(communications.message_type, 'STIM');

if isfile(parameters_used_file)
    load(parameters_used_file, 'parameters_used');
    server_times(client_sends & is_stimulation_communication) = parameters_used.Var8 / 10;
end

is_stimulation_event = contains(stimulation_events.event_type, 'STIM');

for idx = 1:n_events

    if is_stimulation_event

        event_time = event_times(idx);
        within_range = client_times > (event_times - 500) & client_times < (event_times + 500);
        client_index = find(client_sends & within_range);

        if ~isempty(client_index) && ismember(client_index + 1, server_indices)
        
            server_index = client_index + 1;
            delta_client = client_times(server_index) - client_times(client_index);
            time_to_deliver_message = 0;
            
            if server_time(client_index) > 0
                delta_server = server_times(server_index) - server_times(client_index);
                time_to_deliver_message = (delta_client - delta_server);
            end
            
            adjusted_event_times(idx) = event_time + delta_client - (time_to_deliver_message / 2);
            
        end

    end

end

end