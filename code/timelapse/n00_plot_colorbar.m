%%% This function plots a color bar given input plot parameters and color map index

function n00_plot_colorbar(plot_parameters, idx)

axes_parameters = plot_parameters.axes_parameters;

colorbar_parameters = axes_parameters.colorbar_parameters;

colorbar_position = colorbar_parameters.positions{idx};
colorbar_width = colorbar_position(3);

colorbar_struct = plot_parameters.colorbar_struct;

colorbar_title = strrep(colorbar_struct.colorbar_titles{idx}, '_', ' ');

font_size = plot_parameters.font_size;
caxis_limits = colorbar_struct.caxis_limits{idx};

colorbar_start = 60;
colorbar_end = colorbar_width - 5;

color_map = colorbar_struct.color_maps{idx};

n_colors = size(color_map, 1);
colorbar_series = 1:n_colors;

hold on

imagesc([colorbar_start + 2, colorbar_end - 2], [0.2, 0.8], colorbar_series)
ax = gca;
colormap(ax, color_map);

plot([colorbar_start, colorbar_start, colorbar_end, colorbar_end, colorbar_start], [0, 1, 1, 0, 0], '-k', 'Linewidth', 1)

xlim(ax, [0, colorbar_width]);
ylim(ax, [0, 1]);

text(5, 0.5, colorbar_title, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
text(colorbar_start, 0.5, num2str(caxis_limits(1)), 'Color', [1 1 1], 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
text(colorbar_end, 0.5, num2str(caxis_limits(2)), 'Color', [1 1 1], 'FontSize', font_size, 'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle');

ax = gca;
ax.Visible = 'off';

hold off

end