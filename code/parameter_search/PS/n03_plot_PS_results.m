function n03_plot_PS_results(plot_file_name, PS_results)

plot_file_name = [plot_file_name, '_PS_results'];

n_plotted = PS_results.n_plotted;
n_rows = floor(sqrt(n_plotted));
n_columns = ceil(n_plotted/n_rows);

figure_width = 1920;
figure_height = 1080;

subplot_width = figure_width / n_columns;
subplot_height = figure_height / n_rows;

subplot_xs = repmat(linspace(0, figure_width - subplot_width, n_columns), 1, n_rows);
subplot_ys = repmat(linspace(figure_height - subplot_height, 0, n_rows), n_columns, 1);
subplot_ys = subplot_ys(:);

subplot_parameters = get_PS_general_subplot_parameters(PS_results);

figure_handle = figure('Units', 'pixels', 'Position', [0, 0, figure_width, figure_height]);

for idx = 1:n_plotted
    
    subplot_x = subplot_xs(idx);
    subplot_y = subplot_ys(idx);
    
    plot_PS_results_subplot(figure_handle, idx, PS_results, subplot_width, subplot_height, subplot_x, subplot_y, subplot_parameters);

end

print(plot_file_name, '-dpng');

close all

end


function plot_PS_results_subplot(figure_handle, idx, PS_results, subplot_width, subplot_height, subplot_x, subplot_y, subplot_parameters)

n_columns = 3;
n_rows = 2;

n_axes = n_columns * n_rows;

axis_width = subplot_width / n_columns;
axis_height = subplot_height / n_rows;

axis_xs = repmat(linspace(subplot_x, subplot_x+subplot_width-axis_width, n_columns), 1, n_rows)';

axis_ys = repmat(linspace(subplot_y+subplot_height-axis_height, subplot_y, n_rows), n_columns, 1);
axis_ys = axis_ys(:);

axis_positions = [axis_xs, axis_ys, repmat(axis_width, n_axes, 1), repmat(axis_height, n_axes, 1)];

%%% Figure

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axis_positions(1, :), 'Visible', 'off');
subplot_parameters = get_PS_axis_parameters(subplot_parameters, PS_results.pre_stim, idx, 'classifier_results');
plot_PS_axis(subplot_parameters, PS_results.pre_stim, idx, 'Results pre-stim');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axis_positions(2, :), 'Visible', 'off');
subplot_parameters = get_PS_axis_parameters(subplot_parameters, PS_results.post_stim, idx, 'classifier_results');
plot_PS_axis(subplot_parameters, PS_results.post_stim, idx, 'Results post-stim');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axis_positions(3, :), 'Visible', 'off');
subplot_parameters = get_PS_axis_parameters(subplot_parameters, PS_results.change_stim, idx, 'classifier_results_change');
plot_PS_axis(subplot_parameters, PS_results.change_stim, idx, 'Results change (stim)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axis_positions(4, :), 'Visible', 'off');
subplot_parameters = get_PS_axis_parameters(subplot_parameters, PS_results.pre_tstats, idx, 'tstats');
plot_PS_axis(subplot_parameters, PS_results.pre_tstats, idx, 'T-statistics (stim-sham)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axis_positions(5, :), 'Visible', 'off');
subplot_parameters = get_PS_axis_parameters(subplot_parameters, PS_results.post_tstats, idx, 'tstats');
plot_PS_axis(subplot_parameters, PS_results.post_tstats, idx, 'T-statistics (stim-sham)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axis_positions(6, :), 'Visible', 'off')
subplot_parameters = get_PS_axis_parameters(subplot_parameters, PS_results.change_tstats, idx, 'tstats');
plot_PS_axis(subplot_parameters, PS_results.change_tstats, idx, 'T-statistics (stim-sham)');

end

function subplot_parameters = get_PS_general_subplot_parameters(PS_results)

subplot_parameters = struct;

locations = PS_results.locations;
amplitudes = arrayfun(@(x) num2str(x), PS_results.amplitudes, 'UniformOutput', false);
frequencies = arrayfun(@(x) num2str(x), PS_results.frequencies, 'UniformOutput', false);
pulse_widths = arrayfun(@(x) num2str(x), PS_results.pulse_widths, 'UniformOutput', false);

n_locations = length(locations);
n_amplitudes = length(amplitudes);
n_frequencies = length(frequencies);
n_pulse_widths = length(pulse_widths);
n_xs = n_frequencies * n_pulse_widths;

subplot_parameters.locations      = locations;
subplot_parameters.n_locations    = n_locations;
subplot_parameters.amplitudes     = amplitudes;
subplot_parameters.n_amplitudes   = n_amplitudes;
subplot_parameters.n_frequencies  = n_frequencies;
subplot_parameters.n_pulse_widths = n_pulse_widths;

subplot_parameters.xlim           = [0, (n_xs) + 2.3];
subplot_parameters.ylim           = [-1, n_amplitudes + 2];

subplot_parameters.xticks1        = 1:(n_xs);
subplot_parameters.xticklabels1   = repmat(frequencies, 1, n_pulse_widths);

subplot_parameters.xticks2        = 1:n_frequencies:n_xs;
subplot_parameters.xticklabels2   = pulse_widths;

subplot_parameters.yticks         = 1:n_amplitudes;
subplot_parameters.yticklabels    = amplitudes;

subplot_parameters.box_x          = [0.5, 0.5, repmat((n_xs) + 0.5, 1, 2), 0.5];
subplot_parameters.box_y          = [0.5, repmat(n_amplitudes + 0.5, 1, 2), 0.5, 0.5];

subplot_parameters.colorbar_xs    = [n_xs + 1.5, n_xs + 1.5];
subplot_parameters.colorbar_ys    = [0.5, n_amplitudes + 0.5];
subplot_parameters.colorbar_box_x = [1, 1, 2, 2, 1] + repmat(n_xs, 1, 5);

end


function subplot_parameters = get_PS_axis_parameters(subplot_parameters, results, idx, type)

switch type
    case 'classifier_results'
        max_abs = max(abs(results(idx, :, :) - 0.5), [], 'all');
        subplot_parameters.caxis = [0.5 - max_abs, 0.5 + max_abs];
        subplot_parameters.colormap = makecolormap_EF('uniform3');
    
    case 'classifier_results_change'
        max_abs = max(abs(results(idx, :, :)), [], 'all');
        subplot_parameters.caxis = max_abs * [-1, 1];
        subplot_parameters.colormap = flipud(makecolormap_EF('uniform2'));
    
    case 'tstats'
        subplot_parameters.caxis = [-3, 3];
        subplot_parameters.colormap = makecolormap_EF('sigmoid3');
end

end

function plot_PS_axis(subplot_parameters, results, idx, subplot_title)

location       = subplot_parameters.locations{idx};
location = strrep(location, '_', '-');

subplot_title = [subplot_title, ' ', location];

amplitudes     = subplot_parameters.amplitudes;

x_limits       = subplot_parameters.xlim;
x_ticks1       = subplot_parameters.xticks1;
x_ticks2       = subplot_parameters.xticks2;
x_tick_labels1 = subplot_parameters.xticklabels1;
x_tick_labels2 = subplot_parameters.xticklabels2;

n_x1 = length(x_ticks1);
n_x2 = length(x_ticks2);

hold on

imagesc(subplot_parameters.xticks1, subplot_parameters.yticks, squeeze(results(idx, :, :)))

plot(subplot_parameters.box_x, subplot_parameters.box_y, '-k', 'LineWidth', 1)

imagesc(subplot_parameters.colorbar_xs, subplot_parameters.colorbar_ys, linspace(subplot_parameters.caxis(1), subplot_parameters.caxis(2), 6000)');

plot(subplot_parameters.colorbar_box_x, subplot_parameters.box_y, '-k', 'LineWidth', 1)

colormap(gca, subplot_parameters.colormap);
caxis(gca, subplot_parameters.caxis);

xticks([]); xticklabels([]); 
yticks([]); yticklabels([]);

xlim(gca, subplot_parameters.xlim);
ylim(gca, subplot_parameters.ylim)

for jdx = 1:n_x1
    text(x_ticks1(jdx), 0.4, x_tick_labels1{jdx}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
end

for jdx = 1:n_x2
    text(x_ticks2(jdx), -0.6, x_tick_labels2{jdx}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
end

for jdx = subplot_parameters.yticks
    text(0.4, jdx, amplitudes{jdx}, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end

text(n_x1 + 2, 0.5, sprintf('%.2f', subplot_parameters.caxis(1)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Rotation', 90);
text(n_x1 + 2, subplot_parameters.n_amplitudes + 0.5, sprintf('%.2f', subplot_parameters.caxis(2)), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90);
text(mean([x_limits(1), x_limits(2) - 1.5]), subplot_parameters.n_amplitudes + 0.5, subplot_title, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

hold off

end