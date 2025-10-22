n_colors = 21;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(1:21, 2:4) = colors;

n_colors = 7;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(22:28, 2:4) = colors;

n_colors = 15;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(29:43, 2:4) = colors;

n_colors = 17;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(44:60, 2:4) = colors;

n_colors = 9;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(61:69, 2:4) = colors;

n_colors = 16;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(70:85, 2:4) = colors;

n_colors = 6;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(86:91, 2:4) = colors;

n_colors = 11;
colors = round(jet(n_colors+8)*255);
colors([1:6, end-1:end], :) = [];
colors = mat2cell(colors, ones(1, size(colors, 1)), ones(1, size(colors, 2)));
brain_plot_location_colors(92:102, 2:4) = colors;

writetable(brain_plot_location_colors);