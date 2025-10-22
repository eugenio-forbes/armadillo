function n02_plot_CPS_results(plot_file_name, CPS_results)

plot_file_name = [plot_file_name, '_CPS_results'];

%%%Plot parameters
figure_width = 1920;
figure_height = 1080;

subplot_width = figure_width / 3;
subplot_height = figure_height / 3;

axes_x = linspace(0, figure_width - subplot_width, 3);
axes_x = repmat(axes_x', 3, 1);

axes_y = linspace(figure_height-subplot_height, 0, 3);
axes_y = repmat(axes_y, 3, 1);
axes_y = axes_y(:);

axes_positions = [axes_x, axes_y, repmat(subplot_width, 9, 1), repmat(subplot_height, 9, 1)];

%%% Subplot_parameters
subplot_parameters = get_CPS_general_subplot_parameters(CPS_results);

axes_handles = zeros(9, 1);

%%% Figure
figure_handle = figure('Units', 'pixels', 'Position', [0, 0, figure_width, figure_height], 'Visible', 'off');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(1, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.pre_stim, 'classifier_results');
plot_CPS_image(subplot_parameters, CPS_results.pre_stim, 'Results pre-stim');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(2, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.post_stim, 'classifier_results');
plot_CPS_image(subplot_parameters, CPS_results.post_stim, 'Results post-stim');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(3, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.change_stim, 'classifier_results_change');
plot_CPS_image(subplot_parameters, CPS_results.change_stim, 'Results change (stim)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(4, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.pre_sham, 'classifier_results');
plot_CPS_image(subplot_parameters, CPS_results.pre_sham, 'Results pre-sham');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(5, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.post_sham, 'classifier_results');
plot_CPS_image(subplot_parameters, CPS_results.post_sham, 'Results post-sham');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(6, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.change_sham, 'classifier_results_change');
plot_CPS_image(subplot_parameters, CPS_results.change_sham, 'Results change (sham)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(7, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.pre_tstats, 'tstats');
plot_CPS_image(subplot_parameters, CPS_results.pre_tstats, 'T-statistics (stim-sham)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(8, :), 'Visible', 'off');
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.post_tstats, 'tstats');
plot_CPS_image(subplot_parameters, CPS_results.post_tstats, 'T-statistics (stim-sham)');

axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_positions(9, :), 'Visible', 'off')
subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, CPS_results.change_tstats, 'tstats');
plot_CPS_image(subplot_parameters, CPS_results.change_tstats, 'T-statistics (stim-sham)');

print(plot_file_name, '-dpng')

close all

end

function subplot_parameters = get_CPS_general_subplot_parameters(CPS_results)

subplot_parameters = struct;

amplitudes = CPS_results.amplitudes;
amplitudes = arrayfun(@(x) num2str(x), amplitudes, 'UniformOutput', false);

locations = CPS_results.locations;
n_amplitudes = length(amplitudes);
n_locations = length(locations);

subplot_parameters.amplitudes     = amplitudes;
subplot_parameters.locations      = locations;
subplot_parameters.n_amplitudes   = n_amplitudes;
subplot_parameters.n_locations    = n_locations;
subplot_parameters.xlim           = [0, n_locations + 2.3];
subplot_parameters.ylim           = [0, n_amplitudes + 1];
subplot_parameters.xticks         = 1:n_locations;
subplot_parameters.xticklabels    = locations;
subplot_parameters.yticks         = 1:n_amplitudes;
subplot_parameters.yticklabels    = amplitudes;
subplot_parameters.box_x          = [0.5, 0.5, repmat(n_locations + 0.5, 1, 2), 0.5];
subplot_parameters.box_y          = [0.5, repmat(n_amplitudes + 0.5, 1, 2), 0.5, 0.5];
subplot_parameters.colorbar_xs    = [n_locations + 1.5, n_locations + 1.5];
subplot_parameters.colorbar_ys    = [0.5, n_amplitudes + 0.5];
subplot_parameters.colorbar_box_x = [1, 1, 2, 2, 1] + repmat(n_locations, 1, 5);

end


function subplot_parameters = get_CPS_image_subplot_parameters(subplot_parameters, results, type)

switch type
    case 'classifier_results'
        max_abs = max(abs(results(:) - 0.5));
        subplot_parameters.caxis = [0.5 - max_abs, 0.5 + max_abs];
        subplot_parameters.colormap = makecolormap_EF('uniform3');
        
    case 'classifier_results_change'
        max_abs = max(abs(results(:)));
        subplot_parameters.caxis = max_abs * [-1, 1];
        subplot_parameters.colormap = flipud(makecolormap_EF('uniform2'));
        
    case 'tstats'
        subplot_parameters.caxis = [-3, 3];
        subplot_parameters.colormap = makecolormap_EF('sigmoid3');
end

end


function plot_CPS_image(subplot_parameters, results, subplot_title)

locations = subplot_parameters.locations;
amplitudes = subplot_parameters.amplitudes;

hold on

imagesc(subplot_parameters.xticks, subplot_parameters.yticks, results)

plot(subplot_parameters.box_x, subplot_parameters.box_y, '-k', 'LineWidth', 1)

imagesc(subplot_parameters.colorbar_xs, subplot_parameters.colorbar_ys, linspace(subplot_parameters.caxis(1), subplot_parameters.caxis(2), 6000)');

plot(subplot_parameters.colorbar_box_x, subplot_parameters.box_y, '-k', 'LineWidth', 1)

colormap(gca, subplot_parameters.colormap);

caxis(gca, subplot_parameters.caxis);

xticks([]);xticklabels([]);yticks([]);yticklabels([]);

xlim(gca, subplot_parameters.xlim);
ylim(gca, subplot_parameters.ylim)

for idx = subplot_parameters.xticks
    text(idx, 0.4, locations{idx}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
end

for idx = subplot_parameters.yticks
    text(0.4, idx, amplitudes{idx}, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');
end

text(subplot_parameters.n_locations + 2, 0.5, sprintf('%.2f', subplot_parameters.caxis(1)), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', 'Rotation', 90);
text(subplot_parameters.n_locations + 2, subplot_parameters.n_amplitudes + 0.5, sprintf('%.2f', subplot_parameters.caxis(2)), 'HorizontalAlignment', 'right', 'VerticalAlignment', 'top', 'Rotation', 90);
text(mean([1, subplot_parameters.n_locations]), subplot_parameters.n_amplitudes + 0.5, subplot_title, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

hold off

end