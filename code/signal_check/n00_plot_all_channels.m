%%% This function will generate plots for sample signal
%%% and power spectral density for every channel.
%%% Based on number of channels and signals, plot parameters are generated.
%%% There are three different plots:
%%% - A plot with PSD of all channels' raw, referenced and clean signals (different color for each)
%%% - A plot with sample signal for every channel separately (different colors for raw, referenced and clean signals)
%%% - A plot with 2D subplots showing color coded amplitude for all channels
%%% Plots include appropriate colorbars or legends. 

function n00_plot_all_channels(plot_info, channel_signals, reference_signals)

%%% Get plot information
channel_numbers = plot_info.channel_numbers;
n_active = length(channel_numbers);

plot_info.channel_signals   = channel_signals; clear channel_signals
plot_info.reference_signals = reference_signals; clear reference_signals

sample_size = plot_info.sample_size;  
sampling_rate = 1000;

%%% PSD parameters
frequency_resolution = sampling_rate / sample_size;           %%% Actual frequency resolution
min_frequency = frequency_resolution;                         %%% Minimum frequency for power spectrum plot
max_frequency = (sampling_rate / 2) - frequency_resolution;   %%% Maximum frequency for power spectrum plot
frequencies = 0:frequency_resolution:(sampling_rate / 2);     %%% The frequencies corresponding to fft result, 0 to nyquist freq
min_idx = find(frequencies >= min_frequency, 1, 'first');     %%% Indices to use to only store fft results of interest
max_idx = find(frequencies <= max_frequency, 1, 'last');

%%% Information for plot parameters
plot_info.frequencies          = frequencies(min_idx:max_idx);
plot_info.frequency_resolution = frequency_resolution;

is_referenced = ~strcmp(plot_info.referencing_method, 'none');
is_clean = ~strcmp(plot_info.cleaning_method, 'none');

n_signals = 1 + 2 * is_referenced + is_clean;

max_absolute_signal = NaN(n_signals, 1);
max_absolute_signal(1) = 2 * (median(abs(double(plot_info.channel_signals)), 'all') / 0.6745); %%% 4 standard deviations

%%% Generate PSDs for raw signal
plot_info.channel_PSDs = 10 * log10(n00_generate_PSD(plot_info.channel_signals, sampling_rate, min_idx, max_idx));
min_PSD = min(plot_info.channel_PSDs, [], 'all');
max_PSD = max(plot_info.channel_PSDs, [], 'all');

%%% If there is a reference, calculate referenced signal and get PSDs for reference and referenced signal.
if is_referenced
    
    max_absolute_signal(2) = 2 * (median(abs(double(plot_info.reference_signals)), 'all') / 0.6745);
    
    plot_info.reference_PSDs = 10 * log10(n00_generate_PSD(plot_info.reference_signals, sampling_rate, min_idx, max_idx));
    
    temp_min_PSD = min(plot_info.reference_PSDs, [], 'all');
    min_PSD = min(min_PSD, temp_min_PSD);
    
    temp_max_PSD = max(plot_info.reference_PSDs, [], 'all');
    max_PSD = max(max_PSD, temp_max_PSD);
    
    plot_info.referenced_signals = plot_info.channel_signals - plot_info.reference_signals;
    max_absolute_signal(3) = 2 * (median(abs(double(plot_info.referenced_signals)), 'all') / 0.6745);

    plot_info.referenced_PSDs = 10 * log10(n00_generate_PSD(plot_info.referenced_signals, sampling_rate, min_idx, max_idx));
    
    temp_min_PSD = min(plot_info.referenced_PSDs, [], 'all');
    min_PSD = min(min_PSD, temp_min_PSD);
    
    temp_max_PSD = max(plot_info.referenced_PSDs, [], 'all');
    max_PSD = max(max_PSD, temp_max_PSD);
    
end

%%% Develop clean_signal method

% if ~strcmp(plot_info.cleaning_method, 'none')
% 
%     plot_info.clean_signals = n00_clean_signal(plot_info.referenced_signals, plot_info.cleaning_method);
%     
%     plot_info.clean_PSDs = 10 * log10(n00_generate_PSD(plot_info.clean_signals, sampling_rate, min_idx, max_idx));
%     
%     temp_min_PSD = min(plot_info.clean_PSDs, [], 'all');
%     min_PSD = min(min_PSD, temp_min_PSD);
%     
%     temp_max_PSD = max(plot_info.clean_PSDs, [], 'all');
%     max_PSD = max(max_PSD, temp_max_PSD);
%     
%     if is_referenced
%         clean_idx = 4;
%     else
%         clean_idx = 2;
%     end
%     
%     max_absolute_signal(clean_idx) = 2*(median(abs(double(plot_info.clean_signals)), 'all')/0.6745);
%     
% end

plot_info.max_absolute_signal = round(max_absolute_signal);
plot_info.min_PSD             = round(min_PSD);
plot_info.max_PSD             = round(max_PSD);

%%% Based on plot information get plot parameters
plot_parameters = n00_get_channel_plot_parameters(plot_info);

plot_title        = plot_parameters.title;
title_position    = plot_parameters.title_position;
colorbar_position = plot_parameters.colorbar_position;
figure_width      = plot_parameters.figure_width;
figure_height     = plot_parameters.figure_height;
font_size         = plot_parameters.font_size;
PSD_parameters    = plot_parameters.PSD_parameters;

file_name = sprintf(plot_parameters.file_name, 'PSDs');

%%% Plot power spectral densities for all channels adding color legend for each signal type
if ~isfile([file_name, '.png'])

    n_axes = PSD_parameters.n_axes;
    positions = PSD_parameters.positions;
    axes_handles = zeros(n_axes, 1);
    
    figure_handle = figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off');
    
    axes_handles(1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', title_position, 'Visible', 'off');
    
    text(0.5, 0.5, plot_title, 'FontSize', font_size, 'HorizontalAlignment', 'center');
    
    for idx = 1:n_active
    
        position = positions(idx, :);
        axes_handles(idx + 1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', position);
        
        n00_plot_PSD(plot_info, plot_parameters, idx);
        
    end
    
    axes_handles(n_axes) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', colorbar_position, 'Visible', 'off');
    
    n00_plot_signal_colors(plot_parameters);
    
    print(file_name, '-dpng');
    
    close all
    
end

%%% Plot signals for each channel separately. Add color legend for each signal type.
signal_parameters = plot_parameters.signal_parameters;

file_name = sprintf(plot_parameters.file_name, 'signals_separate');

if ~isfile([file_name, '.png'])

    n_axes = signal_parameters.n_axes;
    positions = signal_parameters.positions;
    axes_handles = zeros(n_axes, 1);
    
    figure_handle = figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off');
    
    axes_handles(1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', title_position, 'Visible', 'off');
    
    text(0.5, 0.5, plot_title, 'FontSize', font_size, 'HorizontalAlignment', 'center');
    
    for idx = 1:n_active
    
        position = positions(idx, :);
        axes_handles(idx + 1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', position);
        
        n00_plot_signals_separate(plot_info, plot_parameters, idx);
    end
    
    axes_handles(n_axes) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', colorbar_position, 'Visible', 'off');
    
    n00_plot_signal_colors(plot_parameters);
    
    print(file_name, '-dpng');
    
    close all
    
end

%%% Make 2D plots for each signal type with color coded signal from every channel. Add color bars indicating signal amplitude.
colorbar_positions = plot_parameters.axes_parameters.colorbar_parameters.positions;
n_colorbars = length(colorbar_positions);
file_name = sprintf(plot_parameters.file_name, 'signals_together');

if ~isfile([file_name, '.png'])

    n_axes = signal_parameters.n_axes_together;
    positions = signal_parameters.positions_together;
    axes_handles = zeros(n_axes, 1);
    
    figure_handle = figure('Units', 'pixels', 'Position', [0 0 figure_width figure_height], 'Visible', 'off');
    
    axes_handles(1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', title_position, 'Visible', 'off');
    
    text(0.5, 0.5, plot_title, 'FontSize', font_size, 'HorizontalAlignment', 'center');
    
    for idx = 1:n_signals
    
        position = positions(idx, :);
        axes_handles(idx+1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', position, 'Visible', 'off');
        
        n00_plot_signals_together(plot_info, plot_parameters, idx);
        
    end
    
    for idx = 1:n_colorbars
    
        axes_handles(idx + n_signals + 1) = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', colorbar_positions{idx}, 'Visible', 'off');
        
        n00_plot_colorbar(plot_parameters, idx);
        
    end
    
    print(file_name, '-dpng');
    
    close all
    
end

end