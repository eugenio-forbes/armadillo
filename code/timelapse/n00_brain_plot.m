function n00_brain_plot(brain_view, electrode_table, plot_parameters)

root_directory = plot_parameters.root_directory;
resources_directory = fullfile(root_directory, 'resources');

color_map = plot_parameters.color_map;

if ~ismember('marker_size', fieldnames(plot_parameters))
    marker_size = 5;
else
    marker_size = plot_parameters.marker_size;
end

font_size = plot_parameters.font_size;

colors = arrayfun(@(x) color_map(x, :), electrode_table.value, 'UniformOutput', false);
colors = vertcat(colors{:})/255;

marker_sizes = repmat(marker_size, height(electrode_table), 1);

view_parameters = get_brain_view_parameters(brain_view);

face_alpha         = view_parameters.face_alpha;
azimuth            = view_parameters.azimuth;
elevation          = view_parameters.elevation;
camlight_azimuth   = view_parameters.camlight_azimuth;
camlight_elevation = view_parameters.camlight_elevation;
plot_title         = view_parameters.title;
title_coord        = view_parameters.title_coord;
label1             = view_parameters.label1;
label1_coord       = view_parameters.label1_coord;
label2             = view_parameters.label2;
label2_coord       = view_parameters.label2_coord;

%%% Load necessary files to make 3D brain
load(fullfile(resources_directory, 'EC.mat'), 'EC');
load(fullfile(resources_directory, 'SURF.mat'), 'surf');

coordinates = vertcat(electrode_table.coordinates{:});
coordinates = transform_coordinates(brain_view, coordinates, view_parameters);

%%% 3D plot of a sample brain
hold on

axes_brain = trisurf(surf.tri, surf.coord(1, :), surf.coord(2, :), surf.coord(3, :), 'EdgeColor', 'none');

whitebg(gcf, EC.bak.color);

set(gcf, 'Color', EC.bak.color, 'InvertHardcopy', 'off');

eval(['material ', EC.glb.material, ';']);

eval(['shading ', EC.glb.shading, ';']);

set(axes_brain, 'FaceColor', [0.95, 0.95, 0.95]);
set(axes_brain, 'FaceAlpha', face_alpha);

daspect([1 1 1])

hold off

%%% 3D scatter plot of electrodes with colors corresponding to values
hold on

rotate3d on
axis tight 
axis vis3d off

lighting gouraud

view(azimuth, elevation)

camlight(camlight_azimuth, camlight_elevation);

if ~isempty(coordinates)
    scatter3(coordinates(:, 1), coordinates(:, 2), coordinates(:, 3), marker_sizes, colors, 'filled', 'Marker', 'o')
end

%%% Add labels
text(title_coord(1), title_coord(2), title_coord(3), plot_title, 'FontSize', font_size, 'HorizontalAlignment', 'center');
text(label1_coord(1), label1_coord(2), label1_coord(3), label1, 'FontSize', font_size, 'HorizontalAlignment', 'center');
text(label2_coord(1), label2_coord(2), label2_coord(3), label2, 'FontSize', font_size, 'HorizontalAlignment', 'center');

ax = gca;
xlim(ax, view_parameters.xlim);
ylim(ax, view_parameters.ylim);
zlim(ax, view_parameters.zlim);

hold off

end


function view_parameters = get_brain_view_parameters(brain_view)

view_parameters = struct;

switch brain_view
    case 'inferior'
        face_alpha = 0.8;
        azimuth = 180;
        elevation = -90;
        camlight_azimuth = 90;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-140, 75];
        z_limits = [-45, 80];
        title_coord = [0, -110, 0];
        label1 = 'R';
        label1_coord = [65, 60, 0];
        label2 = 'L';
        label2_coord = [-65, 60, 0];
        
    case 'superior'
        face_alpha = 0.8;
        azimuth = 0;
        elevation = 90;
        camlight_azimuth = 90;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-140, 75];
        z_limits = [-45, 80];
        title_coord = [0, -110, 0];
        label1 = 'L';
        label1_coord = [-65, 60, 0];
        label2 = 'R';
        label2_coord = [65, 60, 0];
        
    case 'lateral-left'
        face_alpha = 0.8;
        azimuth = -90;
        elevation = 0;
        camlight_azimuth = 90;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-105, 75];
        z_limits = [-75, 90];
        title_coord = [0, -15, -60];
        label1 = 'A';
        label1_coord = [0, 60, 80];
        label2 = 'P';
        label2_coord = [0, -90, 80];
        
    case 'lateral-right'
        face_alpha = 0.8;
        azimuth = 90;
        elevation = 0;
        camlight_azimuth = -90;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-105, 75];
        z_limits = [-75, 90];
        title_coord = [0, -15, -60];
        label1 = 'P';
        label1_coord = [0, -90, 80];
        label2 = 'A';
        label2_coord = [0, 60, 80];
        
    case 'medial-left'
        face_alpha = 0.8;
        azimuth = -90;
        elevation = 0;
        camlight_azimuth = 180;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-105, 75];
        z_limits = [-75, 90];
        title_coord = [0, -15, -60];
        label1 = 'A';
        label1_coord = [0, 60, 80];
        label2 = 'P';
        label2_coord = [0, -90, 80];
        
    case 'medial-right'
        face_alpha = 0.8;
        azimuth = 90;
        elevation = 0;
        camlight_azimuth = 180;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-105, 75];
        z_limits = [-75, 90];
        title_coord = [0, -15, -60];
        label1 = 'P';
        label1_coord = [0, -90, 80];
        label2 = 'A';
        label2_coord = [0, 60, 80];
        
    case 'deep-left'
        face_alpha = 0.15;
        azimuth = -90;
        elevation = 0;
        camlight_azimuth = 0;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-105, 75];
        z_limits = [-75, 90];
        title_coord = [0, -15, -60];
        label1 = 'A';
        label1_coord = [0, 60, 80];
        label2 = 'P';
        label2_coord = [0, -90, 80];
        
    case 'deep-right'
        face_alpha = 0.15;
        azimuth = 90;
        elevation = 0;
        camlight_azimuth = 0;
        camlight_elevation = 0;
        x_limits = [-70, 70];
        y_limits = [-105, 75];
        z_limits = [-75, 90];
        title_coord = [0, -15, -60];
        label1 = 'P';
        label1_coord = [0, -90, 80];
        label2 = 'A';
        label2_coord = [0, 60, 80];
        
end

plot_title = strrep(brain_view, '-', ' ');

view_parameters.face_alpha         = face_alpha;
view_parameters.azimuth            = azimuth;
view_parameters.elevation          = elevation;
view_parameters.camlight_azimuth   = camlight_azimuth;
view_parameters.camlight_elevation = camlight_elevation;
view_parameters.xlim               = x_limits;
view_parameters.ylim               = y_limits;
view_parameters.zlim               = z_limits;
view_parameters.title              = plot_title;
view_parameters.title_coord        = title_coord;
view_parameters.label1             = label1;
view_parameters.label2             = label2;
view_parameters.label1_coord       = label1_coord;
view_parameters.label2_coord       = label2_coord;

end


function coordinates = transform_coordinates(brain_view, coordinates, view_parameters)

coordinates = coordinates * .91;
n_coordinates = size(coordinates, 1);

% switch brain_view
%     case 'superior'
%         coordinates(:, 3) = coordinates(:, 3) + 100;
%     case 'inferior'
%         coordinates(:, 3) = coordinates(:, 3) - 100;
%     case 'lateral-left'
%         coordinates(:, 1) = coordinates(:, 1) - 100;
%     case 'lateral-right'
%         coordinates(:, 1) = coordinates(:, 1) + 100;
%     case 'medial-left'
%         coordinates(:, 1) = coordinates(:, 1) - 100;
%     case 'medial-right'
%         coordinates(:, 1) = coordinates(:, 1) + 100;
%     case 'deep-left'
%         coordinates(:, 1) = coordinates(:, 1) - 100;
%     case 'deep-right'
%         coordinates(:, 1) = coordinates(:, 1) + 100;
% end

x_limits = view_parameters.xlim;
z_limits = view_parameters.zlim;

switch brain_view
    case 'superior'
        coordinates(:, 3) = repmat(z_limits(2) - 1, n_coordinates, 1);
    case 'inferior'
        coordinates(:, 3) = repmat(z_limits(1) + 1, n_coordinates, 1);
    case 'lateral-left'
        coordinates(:, 1) = repmat(x_limits(1) + 1, n_coordinates, 1);
    case 'lateral-right'
        coordinates(:, 1) = repmat(x_limits(2) - 1, n_coordinates, 1);
    case 'medial-left'
        coordinates(:, 1) = repmat(x_limits(1) + 1, n_coordinates, 1);
    case 'medial-right'
        coordinates(:, 1) = repmat(x_limits(2) - 1, n_coordinates, 1);
    case 'deep-left'
        coordinates(:, 1) = repmat(x_limits(1) + 1, n_coordinates, 1);
    case 'deep-right'
        coordinates(:, 1) = repmat(x_limits(2) - 1, n_coordinates, 1);
end

end