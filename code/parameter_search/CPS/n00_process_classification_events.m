function events = n00_process_classification_events(elemem_folder, elemem_log)

jacksheet = n00_read_monopolar_jacksheet(elemem_folder);

event_types = elemem_log.type;

zeroed_artifact = elemem_log(strcmp(event_types, 'ZEROED_ARTIFACT'), :);

stim_classify = elemem_log(strcmp(event_types, 'CLASSIFY_STIM_CPS'), :);
stim_times = stim_classify.time;
stim_decision = elemem_log.time(strcmp(event_types, 'STIM_DECISION'), :);

sham_classify = elemem_log(strcmp(event_types, 'CLASSIFY_SHAM_CPS'), :);
sham_times = sham_classify.time;
sham_decision = elemem_log.time(strcmp(event_types, 'SHAM_DECISION'), :);

nostim_classify = elemem_log(strcmp(event_types, 'CLASSIFY_NOSTIM_CPS'), :);
nostim_times = nostim_classify.time;
nostim_decision = elemem_log.time(strcmp(event_types, 'NOSTIM_DECISION'), :);

config_stim = elemem_log(strcmp(event_types, 'CONFIG_STIM'), :);
stimming = elemem_log(strcmp(event_types, 'STIMMING'), :);
update = elemem_log(strcmp(event_types, 'UPDATE'), :);
sham = elemem_log(strcmp(event_types, 'SHAM'), :);
max_update = height(update);

n_events = height(sham_classify) + height(stim_classify);

a = false(n_events, 1);
b = NaN(n_events, 1);
c = repelem({''}, n_events, 1);
d = cell(n_events, 1);

is_stim = a;
is_sham = a;
prestim_time = b;
prestim_event_duration = b;
prestim_solving_duration = b;
prestim_result =  b;
threshold_crossed = F;
stim_delivered = b;
stim_time = b;
stim_duration = b;
sham_time = b;
sham_duration = b;
poststim_time = b;
poststim_duration = b;
poststim_result = b;
poststim_solving_duration = b;
probability_change = b;
lead1 = c;
lead2 = c;
amplitude = b;
frequency = b;
duration = b;
area = b;
burst_faction = b;
burst_frequency = b;
model_index = b;
n_samples = b;
x = b;
kernel_params = d;
first_decision_time = b;
second_decision_time = b;
decision_to_stim_time = b;
stim_to_poststim_time = b;

current_time = 0;
stim_idx = 1;
sham_idx = 1;
nostim_idx = 1;
stimming_idx = 1;
shamming_idx = 1;
update_idx = 0;

for idx = 1:n_events

    config = config_stim.data{stimming_idx}.stim_profile;
    pos = config.electrode_pos;
    neg = config.electrode_neg;
    
    lead1(idx) = jacksheet.Label(jacksheet.Lead == pos);
    lead2(idx) = jacksheet.Label(jacksheet.Lead == neg);
    amplitude(idx) = config.amplitude/1000;
    frequency(idx) = config.frequency;
    duration(idx) = config.duration/1000;
    area(idx) = config.area;
    burst_faction(idx) = config.burst_frac;
    burst_frequency(idx) = config.burst_slow_freq;
    
    stim_event_time = stim_times(find(stim_times>current_time, 1, 'first'));
    
    if isempty(stim_event_time)
        stim_event_time = Inf;
    end
    
    sham_event_time = sham_times(find(sham_times>current_time, 1, 'first'));
    
    if isempty(sham_event_time)
        sham_event_time = Inf;
    end
    
    if stim_event_time < sham_event_time
        is_stim(idx) = true;
        event = stim_classify(stim_idx, :);
        first_decision_time(idx) = stim_decision(stim_idx, :);
        stim_idx = stim_idx + 1;
    else
        is_sham(idx) = true;
        event = sham_classify(sham_idx, :);
        first_decision_time(idx) = sham_decision(sham_idx, :);
        sham_idx = sham_idx + 1;
    end
    
    event_time = event.time;
    event = event.data{:};
    
    prestim_time(idx) = event_time;
    prestim_event_duration(idx) = event.duration;
    prestim_solving_duration(idx) = first_decision_time(idx)-event_time-event.duration;
    prestim_result(idx) = event.result;
    threshold_crossed(idx) = event.decision;
    
    if threshold_crossed(idx)
        
        if is_stim(idx)
            
            stim_delivered(idx) = true;
            stim_time(idx) = stimming.time(stimming_idx);
            stim_duration(idx) = stimming.data{stimming_idx}.duration;
            stimming_idx = stimming_idx + 1;
            
            decision_to_stim_time(idx) = stim_time(idx)-first_decision_time(idx);
            
            if update_idx < max_update
                update_idx = update_idx + 1;
                this_update = update.data{update_idx};
                model_index(idx) = this_update.model_index;
                n_samples(idx) = []; %%% this_update.num_samples;
                x(idx) = this_update.x;
                length_scale = [];   %%% this_update.kernel__matern32_0__lengthScale;
                variance1 = [];      %%% this_update.kernel__matern32_0__variance;
                variance2 = [];      %%% this_update.kernel__white_1__variance;
                kernel_params{idx} = []; %%% [length_scale, variance1, variance2];
            end
            
        else
        
            sham_time(idx) = sham.time(shamming_idx);
            sham_duration(idx) = sham.data{shamming_idx}.duration;
            shamming_idx = shamming_idx + 1;
            decision_to_stim_time(idx) = sham_time(idx)-first_decision_time(idx);
            
        end
        
        if idx < n_events
        
            event = nostim_classify(nostim_idx, :);
            second_decision_time(idx) = nostim_decision(nostim_idx);
            nostim_idx = nostim_idx + 1;
            
            event_time = event.time;
            event = event.data{:};
        
            poststim_time(idx) = event_time;
            poststim_duration(idx) = event.duration;
            poststim_solving_duration(idx) = second_decision_time(idx)-event_time-event.duration;
            poststim_result(idx) = event.result;
            probability_change(idx) = poststim_result(idx)-prestim_result(idx);
            
            if is_stim(idx)
                stim_to_poststim_time(idx) = poststim_time(idx) - stim_time(idx) - stim_duration(idx);
            else
                stim_to_poststim_time(idx) = poststim_time(idx) - sham_time(idx) - sham_duration(idx);
            end
            
        else
            threshold_crossed(idx) = false;
        end
        
    end
    
    current_time = prestim_time(idx);
    
end

events = table(is_stim, is_sham, prestim_time, prestim_event_duration, ...
    prestim_solving_duration, prestim_result, threshold_crossed, ...
    stim_delivered, stim_time, stim_duration, sham_time, sham_duration, ...
    poststim_time, poststim_duration, poststim_result, ...
    poststim_solving_duration, probability_change, lead1, lead2, amplitude, ...
    frequency, duration, area, burst_faction, burst_frequency, model_index, ...
    n_samples, x, kernel_params, first_decision_time, second_decision_time, ...
    decision_to_stim_time, stim_to_poststim_time);
    
end