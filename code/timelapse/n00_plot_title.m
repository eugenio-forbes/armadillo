function n00_plot_title(axes_handle, plot_parameters)

plot_title = plot_parameters.title;
font_size  = plot_parameters.font_size;

xlim(axes_handle, [0, 1]);
ylim(axes_handle, [0, 1]);

text(0.4, 0.5, plot_title, 'FontSize', font_size);

ax = gca;
ax.Visible = 'off';

end