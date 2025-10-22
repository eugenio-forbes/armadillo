function plot_parameters = n00_get_behavioral_plot_parameters(analysis_parameters)

%%% Set values to fit screen
screen_width = 1920;
screen_height = 1080;

%%% Set scale_down value to 1, 2, or 3 to get full, quarter, or ninth of standard screen number of pixels.
scale_down = 1;

%%% Choose font type
font_name = 'Verdana';

%%% Set max figure width and height based on above parameters
max_figure_width  = screen_width / scale_down;
max_figure_height = screen_height / scale_down;

%%% Set font size and axes margins for labels based on screen height
font_size = max_figure_height / 90; %%% Eg. font size 12 for screen of 1080 pixels in height.
x_margin  = font_size * 1.25;
y_margin  = font_size * 1.25;

%%% Get axes sizes and positions based on number of outcomes in analysis, and set figure width and height
n_outcomes = analysis_parameters.n_outcomes(:);

subplot_height      = max_figure_height / 4;  %%% Max 4 number of outcomes: f_response, f_correct, f_response_correct, response_time
subplot_width       = subplot_height;         %%% For effects and correlation 
distribution_height = subplot_height;         %%% For outcome distributions
distribution_width  = max_figure_width - (subplot_width * 3);

figure_height = subplot_height * n_outcomes;
figure_width = max_figure_width;

axes_positions = cell(n_outcomes, 4);

for idx = 1:n_outcomes

    bottom = figure_height - (subplot_height * idx);
    left = arrayfun(@(x) distribution_width + (subplot_width * x), 0:2);
    
    axes_positions{idx, 1} = [0, bottom, distribution_width, distribution_height];
    axes_positions(idx, 2:4) = arrayfun(@(x) [left(x), bottom, subplot_width, subplot_height], 1:3, 'UniformOutput', false);

end

color_maps = get_behavioral_color_maps();

plot_parameters = struct;
plot_parameters.figure_width        = figure_width;
plot_parameters.figure_height       = figure_height;
plot_parameters.subplot_width       = subplot_width;
plot_parameters.subplot_height      = subplot_height;
plot_parameters.distribution_width  = distribution_width;
plot_parameters.distribution_height = distribution_height;
plot_parameters.x_margin            = x_margin;
plot_parameters.y_margin            = y_margin;
plot_parameters.axes_positions      = axes_positions;
plot_parameters.font_size           = font_size;
plot_parameters.font_name           = font_name;
plot_parameters.color_maps          = color_maps;

end