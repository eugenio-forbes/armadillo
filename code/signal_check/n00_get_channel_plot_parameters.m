%%% This plot uses information such as number of channels,
%%% PSD and sample signas; to determine plot parameters such
%%% as number of axes, subplot widths, heights, and positions.

function plot_parameters = n00_get_channel_plot_parameters(plot_info)

plot_directory = plot_info.directory;
session = num2str(plot_info.session);
subject = plot_info.subject;
task = plot_info.task;

channel_numbers = vertcat(plot_info.channel_numbers);
sample_size = plot_info.sample_size;

referencing_method = plot_info.referencing_method;
cleaning_method = plot_info.cleaning_method;

n_signals = plot_info.n_signals;

frequencies = plot_info.frequencies;

max_absolute_signal = plot_info.max_absolute_signal;
max_max = max(max_absolute_signal);

min_PSD = plot_info.min_PSD;
max_PSD = plot_info.max_PSD;
if isinf(min_PSD)
    min_PSD = -60;
end

%%% Four different colors to track progress of DSP
channel_color = [5, 225, 250] / 255;
reference_color = [250, 5, 225] / 255;
referenced_color = [50, 50, 50] / 255;
clean_color = [25, 250, 25] / 255;

data_type = repelem({'EEG'}, 1, n_signals);
data_type = strjoin(data_type, '-');

plot_parameters = struct;

plot_parameters.file_name = fullfile(plot_directory, [subject, '_', task, '_', session, '_%s']);

%%%Configurable  %%% Set to 1, 2, 3 to get full, quarter, or ninth of standard screen number of pixels.
scale_down = 1;
figure_width = 1920 / scale_down;
figure_height = 1080 / scale_down;

plot_parameters.scale_down = scale_down;
plot_parameters.figure_width = figure_width;
plot_parameters.figure_height = figure_height;

plot_parameters.title = sprintf('%s; %s; #%s; referencing: %s, cleaning: %s ', subject, task, session, referencing_method, cleaning_method);
title_height = 15 * (4 - plot_parameters.scale_down);
plot_parameters.title_height = title_height;
plot_parameters.title_position = [0, figure_height - title_height, figure_width, title_height];

colorbar_height = 15 * (4 - plot_parameters.scale_down);
plot_parameters.colorbar_height = colorbar_height;
plot_parameters.colorbar_position = [0, 0, figure_width, colorbar_height];

plot_parameters.font_size = 20;

[~, colorbar_struct] = n00_get_color_map(data_type);
plot_parameters.colorbar_struct = colorbar_struct;

axes_parameters = struct;
colorbar_parameters = struct;

positions = cell(n_signals, 1);
colorbar_width = figure_width / n_signals;

for idx = 1:n_signals
    positions{idx} = [colorbar_width * (idx - 1), 0, colorbar_width, colorbar_height];
    plot_parameters.colorbar_struct.caxis_limits{idx} = max_absolute_signal(idx) * [-1, 1];
end

colorbar_parameters.positions = positions;
axes_parameters.colorbar_parameters = colorbar_parameters;
plot_parameters.axes_parameters = axes_parameters;

%%% Determine signal colors for PSD plot and separate signal plot
if n_signals == 1
    plot_parameters.signal_colors = referenced_color;
    plot_parameters.signal_types = {'channel_signals'};
elseif n_signals == 2
    plot_parameters.signal_colors = [referenced_color; clean_color];
    plot_parameters.signal_types = {'channel_signals', 'clean_signals'};
elseif n_signals == 3
    plot_parameters.signal_colors = [reference_color; channel_color; referenced_color];
    plot_parameters.signal_types = {'reference_signals', 'channel_signals', 'referenced_signals'};
elseif n_signals == 4
    plot_parameters.signal_colors = [reference_color; channel_color; referenced_color; clean_color];
    plot_parameters.signal_types = {'reference_signals', 'channel_signals', 'referenced_signals', 'clean_signals'};
end

%%% Determine appropriate x and y ticks and tick labels for PSD plots
min_frequency = min(frequencies);
max_frequency = max(frequencies);

PSD_parameters = struct;

x_limits = [min_frequency, max_frequency]; %%% PSDs plotted in decibels (y) and linear freq (x)
x_ticks = [min_frequency, 60:60:max_frequency];
x_tick_labels = repelem({''}, 1, length(x_ticks));
x_tick_labels{x_ticks == 60} = '60Hz';

PSD_parameters.x_limits = x_limits;
PSD_parameters.x_ticks = x_ticks; %% Each frequency tick centered at 60 Hz and harmonics
PSD_parameters.x_tick_labels = x_tick_labels;

y_limits = [min_PSD, max_PSD];
y_limits = [min(y_limits)-(diff(y_limits)*0.05), max(y_limits)+(diff(y_limits)*0.05)];
y_ticks = sort(unique([min_PSD, max_PSD, 0, 0:10:max_PSD, 0:-10:min_PSD]));
y_tick_labels = repelem({''}, 1, length(y_ticks));
y_tick_labels{y_ticks == 0} = '0dB';
if round(max_PSD) > 10
    y_tick_labels{y_ticks == max_PSD} = strcat(num2str(max_PSD), 'dB');
end
if round(min_PSD) < 10 && round(min_PSD) ~= 0
    y_tick_labels{y_ticks == min_PSD} = strcat(num2str(min_PSD), 'dB');
end

PSD_parameters.y_limits = y_limits;
PSD_parameters.y_ticks = y_ticks;
PSD_parameters.y_tick_labels = y_tick_labels;

%%% Determine how many rows and columns in plots
max_channel_number = max(channel_numbers);
if max_channel_number <= 64
    n_columns = 8;
    n_rows = 8;
    n_boxes = 64;
elseif max_channel_number <= 128
    n_columns = 16;
    n_rows = 8;
    n_boxes = 128;
elseif max_channel_number <= 192
    n_columns = 16;
    n_rows = 12;
    n_boxes = 192;
elseif max_channel_number <= 256
    n_columns = 16;
    n_rows = 16;
    n_boxes = 256;
end

%%% Determine subplot widths and heights and subplot positions
subplot_width = figure_width / n_columns;
subplot_height = (figure_height - title_height - colorbar_height) / n_rows;

subplot_xs = (0:subplot_width:figure_width - subplot_width)';
subplot_xs = repmat(subplot_xs, 1, n_rows);
subplot_xs = subplot_xs(:);

subplot_ys = linspace((figure_height - title_height - subplot_height), colorbar_height, n_rows);
subplot_ys = repmat(subplot_ys, n_columns, 1);
subplot_ys = subplot_ys(:);

subplot_positions = [subplot_xs, subplot_ys, repmat(subplot_width, n_boxes, 1), repmat(subplot_height, n_boxes, 1)];
subplot_positions = subplot_positions(channel_numbers, :);

PSD_parameters.positions = subplot_positions;
PSD_parameters.n_axes = length(channel_numbers) + 2;
plot_parameters.PSD_parameters = PSD_parameters;
   
%%% Determine parameters for separate signal plots
signal_parameters = struct;

%%% X and Y ticks and tick labels
x_limits = [0, sample_size];
x_ticks = 0:250:sample_size;
x_tick_labels = repelem({''}, 1, length(x_ticks));
multiples_of_500 = x_ticks == 0 | mod(x_ticks, 500) == 0;
x_tick_labels(multiples_of_500) = arrayfun(@num2str, x_ticks(multiples_of_500), 'UniformOutput', false);

y_limits = [-1, 1] * max_max;
y_ticks = (-1 * max_max):(max_max / 4):max_max;
y_tick_labels = repelem({''}, 1, length(y_ticks));
y_tick_labels{y_ticks == 0} = '0';
y_tick_labels{y_ticks == max_max} = [num2str(max_max), ' uV'];

signal_parameters.x_limits = x_limits;
signal_parameters.x_ticks = x_ticks;
signal_parameters.x_tick_labels = x_tick_labels;

signal_parameters.y_limits = y_limits;
signal_parameters.y_ticks = y_ticks;
signal_parameters.y_tick_labels = y_tick_labels;

%%% Number of rows and columns
if max_channel_number <= 64
    n_columns = 4;
    n_rows = 16;
    n_boxes = 64;
elseif max_channel_number <= 128
    n_columns = 4;
    n_rows = 32;
    n_boxes = 128;
elseif max_channel_number <= 192
    n_columns = 6;
    n_rows = 32;
    n_boxes = 192;
elseif max_channel_number <= 256
    n_columns = 8;
    n_rows = 32;
    n_boxes = 256;
end

%%% Subplot widths, heights, and positions
subplot_width = figure_width / n_columns;
subplot_height = (figure_height - title_height - colorbar_height) / n_rows;

subplot_xs = 0:subplot_width:figure_width - subplot_width;
subplot_xs = repmat(subplot_xs, n_rows, 1);
subplot_xs = subplot_xs(:);

subplot_ys = linspace((figure_height - title_height - subplot_height), colorbar_height, n_rows)';
subplot_ys = repmat(subplot_ys, 1, n_columns);
subplot_ys = subplot_ys(:);

subplot_positions = [subplot_xs, subplot_ys, repmat(subplot_width, n_boxes, 1), repmat(subplot_height, n_boxes, 1)];
subplot_positions = subplot_positions(channel_numbers, :);

signal_parameters.positions = subplot_positions;
signal_parameters.n_axes = length(channel_numbers) + 2;

%%% Determine parameters for signals plotted together
%%% Subplot widths, heights and positions of each 2D plot and colorbar
subplot_positions = zeros(n_signals, 4);
subplot_height = (figure_height - title_height - colorbar_height);

if n_signals > 2

    subplot_positions(1, :) = [0, colorbar_height + subplot_height / 2, figure_width / 2, subplot_height / 2];
    subplot_positions(2, :) = [figure_width / 2, colorbar_height + subplot_height / 2, figure_width / 2, subplot_height / 2];
    subplot_positions(3, :) = [0, colorbar_height, figure_width / 2, subplot_height / 2];
    
    if n_signals == 4
        subplot_positions(4, :) = [figure_width / 2, colorbar_height, figure_width / 2, subplot_height / 2];
    end
    
elseif n_signals == 2

    subplot_positions(1, :) = [0, colorbar_height + subplot_height / 2, figure_width, subplot_height / 2];
    subplot_positions(2, :) = [0, colorbar_height, figure_width, subplot_height / 2];
    
else

    subplot_positions(1, :) = [colorbar_height, 0, figure_width, subplot_height];
    
end

%%% Y ticks with channel numbers by groups of 16
signal_parameters.n_axes_together = n_signals * 2 + 1;
signal_parameters.positions_together = subplot_positions;

y_limits_together = [0.5, double(max_channel_number) + 0.5];
y_ticks_together = 16:16:double(max_channel_number);

signal_parameters.y_limits_together = y_limits_together;
signal_parameters.y_ticks_together = y_ticks_together;
signal_parameters.n_boxes = n_boxes;
signal_parameters.n_signals = n_signals;

plot_parameters.signal_parameters = signal_parameters;

end