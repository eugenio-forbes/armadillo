function color_maps = get_behavioral_color_maps()

%%% There are 5 color maps: group effect, condition fixed effect, condition-group interaction, group correlation, time correlation
color_map_type = {'group effect'; 'condition effect'; 'interaction'; 'group correlation'; 'time correlation'};

%%% Corresponding limits of t-stats for effects, interactions, and correlations (R^2).
caxis_limits = {[-3, 3]; [-3, 3]; [-3, 3]; [0, 1]; [0, 1]};

%%% Initialize cell array for 5 color maps and add 5 different color maps
color_map = cell(5,1);
color_map{1} = makecolormap_EF('sigmoid3');
color_map{2} = makecolormap_EF('uniform2');
color_map{3} = makecolormap_EF('uniform3');
color_map{4} = makecolormap_EF('single_gradient2');
color_map{5} = makecolormap_EF('single_gradient3');

%%% Make table with all color map parameters
color_maps = table(color_map_type, caxis_limits, color_map);

end