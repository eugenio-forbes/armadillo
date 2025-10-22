%%% This function extracts raw channel and reference signals from saved
%%% channel binary int16 files based on sample index and sample size.
%%% Returns these signals.

function [channel_signal, reference_signal] = n00_get_sample_signal(events_file, channel_number, reference, referencing_method, sample_idx, sample_size)

%%% Get EEG file stems from events file
load(events_file, 'events')

eeg_file_stem = unique(events.eegfile);
bad_file = strcmp(eeg_file_stem, '');
eeg_file_stem(bad_file) = [];
eeg_file_stem = eeg_file_stem{1};

%%% Get channel signal from file
eeg_file = [eeg_file_stem sprintf('.%03d', channel_number)];

file_id = fopen(eeg_file, 'rb');
fseek(file_id, (sample_idx - 1) * 2, 'bof'); %%% 2 bytes per sample
channel_signal = int16(fread(file_id, sample_size, 'int16')');
fclose(file_id);

%%% Subtract signal mean
channel_signal = int16(double(channel_signal) - mean(double(channel_signal), 2));

%%% Get reference signal. DEV: Currently only for bipolar reference
if ~ismember(referencing_method, {'none', 'CAR'})

    n_reference_channels = length(reference);
    reference_signals = int16(zeros(n_reference_channels, sample_size));
    
    for idx = 1:n_reference_channels
        
        eeg_file = [eeg_file_stem sprintf('.%03d', reference(idx))];
        
        file_id = fopen(eeg_file, 'rb');
        fseek(file_id, (sample_idx - 1) * 2, 'bof');
        temp_reference_signal = fread(file_id, sample_size, 'int16')';
        reference_signals(idx, :) = int16(double(temp_reference_signal) - mean(double(temp_reference_signal), 2));
        fclose(file_id);
    
    end
    
    reference_signal = int16(mean(double(reference_signals), 1));
    
else

    reference_signal = int16(zeros(1, sample_size));
    
end

end
