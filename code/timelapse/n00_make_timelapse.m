function n00_make_timelapse(electrode_table, time_series, plot_parameters)

timelapse_parameters = plot_parameters.timelapse_parameters;

timelapse_duration = time_lapse_parameters.timelapse_duration;
n_time_points      = time_lapse_parameters.n_time_points;
start_mode         = timelapse_parameters.start_mode;
start_duration     = timelapse_parameters.start_duration;
timeline_info      = time_lapse_parameters.timeline_info;

plot_filename = plot_parameters.plot_filename;
figure_width  = plot_parameters.figure_width;
figure_height = plot_parameters.figure_height;
data_type     = plot_parameters.data_type;

frame_delay_time = n_time_points / timelapse_duration;

figure_handle = figure('Units', 'pixels', 'Visible', 'off');

figure_handle.Position(3) = figure_width;
figure_handle.Position(4) = figure_height;

plot_parameters.figure_handle = figure_handle;

no_start_frame = strcmp(start_mode, 'none');

if ~no_start_frame

    plot_parameters.timeline_mode = 'skip';
    plot_parameters.colorbar_mode = 'include';
    
    switch start_mode
        case 'region_colors'
            [plot_parameters.color_map, plot_parameters.colorbar_struct] = n00_get_color_map('brain_region');
            n00_plot_all_electrodes_by_region(electrode_table, plot_parameters, timeline_info);
    end
    
    [imind, cm] = rgb2ind(frame2im(getframe(figure_handle)), 256);
    imwrite(imind, cm, plot_filename, 'gif', 'Loopcount', inf, 'DelayTime', start_duration);
    
end

[plot_parameters.color_map, plot_parameters.colorbar_struct] = n00_get_color_map(data_type);

plot_parameters.timeline_mode = 'include';
plot_parameters.colorbar_mode = 'include';

for tdx = 1:n_time_points
    
    timeline_info.tdx = tdx;
    plot_parameters.timeline_info = timeline_info;
    electrode_table.value = time_series(:, tdx);
    
    n00_plot_frame(electrode_table, plot_parameters);
    
    [imind, cm] = rgb2ind(frame2im(getframe(figure_handle)), 256);
    
    %%% Write to the GIF File
    if tdx == 1 && ~start_with_region_colors
        imwrite(imind, cm, plot_filename, 'gif', 'Loopcount', inf, 'DelayTime', frame_delay_time);
    else
        imwrite(imind, cm, plot_filename, 'gif', 'WriteMode', 'append', 'DelayTime', frame_delay_time);
    end
    
end

end