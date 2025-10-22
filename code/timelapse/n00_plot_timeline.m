function n00_plot_timeline(axes_handle, plot_parameters)

axes_parameters = plot_parameters.axes_parameters;

timeline_parameters = axes_parameters.timeline_parameters;

timeline_position = timeline_parameters.position;
timeline_width = timeline_position(3);

timelapse_parameters = plot_parameters.timelapse_parameters;
n_time_points = timelapse_parameters.n_time_points;

timeline_info = plot_parameters.timeline_info;

tdx = timeline_info.tdx;
timeline_title = strrep(timeline_info.title, '_', ' ');

font_size = plot_parameters.font_size;

timeline_limits = timeline_info.limits;

t_start = font_size * 10;
t_end = timeline_width - (font_size * 3);
t_diff = t_end - t_start;
time_step = t_diff / (n_time_points - 1);
current_t = t_start + (time_step*(tdx-1));

if 0 >= timeline_limits(1) && 0 <= timeline_limits(2)
    zero_x = t_start + (((0 - timeline_limits(1)) / diff(timeline_limits)) * (t_end - t_start));
end

title_x = font_size * 4.5;
limit1_x = t_start - (font_size * 1);
limit2_x = t_end + (font_size * 1.5);

timeline_box_x = [t_start, t_start, t_end, t_end, t_start];
timeline_fill_x = [t_start, t_start, current_t, current_t, t_start];
timeline_y = [0.15, 0.85, 0.85, 0.15, 0.15];
fill_color = [90 169 230] / 255;

t_shine_start = t_start + (t_diff * 0.05);
t_shine_end = t_start + (0.95 * time_step * (tdx - 1));
shine_fill_x = [t_shine_start, t_shine_start, t_shine_end, t_shine_end, t_shine_start];
shine_fill_y = [0.65, 0.75, 0.75, 0.65, 0.65];

hold on

patch(timeline_fill_x, timeline_y, fill_color, 'EdgeColor', 'none');

patch(shine_fill_x, shine_fill_y, [1, 1, 1], 'EdgeColor', 'none');

plot(timeline_box_x, timeline_y, '-k', 'Linewidth', 1)

if 0 >= timeline_limits(1) && 0 <= timeline_limits(2)
    plot([zero_x, zero_x], [0.15, 0.85], '-k', 'Linewidth', 1)
end

xlim(axes_handle, [0, timeline_width]);
ylim(axes_handle, [0, 1]);

text(title_x, 0.5, timeline_title, 'FontSize', font_size, 'HorizontalAlignment', 'center');
text(limit1_x, 0.5, num2str(timeline_limits(1)), 'FontSize', font_size, 'HorizontalAlignment', 'center');
text(limit2_x, 0.5, num2str(timeline_limits(2)), 'FontSize', font_size, 'HorizontalAlignment', 'center');

ax = gca;
ax.Visible = 'off';

hold off

end