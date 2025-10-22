function plot_behavioral_analysis(plots_directory, analysis_parameters, results, analysis_idx)

%%% Get plot parameters based on analysis information
plot_parameters = get_behavioral_plot_parameters(analysis_parameters);
figure_width    = plot_parameters.figure_width;
figure_height   = plot_parameters.figure_height;
axes_positions  = plot_parameters.axes_positions;

%%% Get outcome names and count
outcomes       = analysis_parameters.outcomes;
outcome_labels = analysis_parameters.outcome_labels;
n_outcomes     = analysis_parameters.n_outcomes;

%%% Get different result cell arrays
distributions              = results.distributions;
effect_grids               = results.effect_grids;
behavior_correlation_grids = results.behavior_correlation_grids;
time_correlation_grids     = results.time_correlatiton_grids;

%%% Specify specific analysis in plot filename with analysis index
plot_filename = fullfile(plots_directory, sprintf('behavioral_analysis_%d', analysis_idx));

%%% Distributions, effects, and correlations plotted in a grid of axes
axes_handles = cell(n_outcomes, 4);

figure_handle = figure('Units', 'pixels', 'Position', [0, 0, figure_width, figure_height], 'Visible', 'off');

for idx = 1:n_outcomes
    
    %%% Plot behavioral outcome distributions for each group with a violin plot
    axes_handles{idx, 1} = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_position{idx, 1}, 'Visible', 'off');
    plot_behavior_distributions(analysis_parameters, plot_parameters, outcome_labels{idx}, distributions(idx, :));
    
    %%% Plot a grid with colors indicating grade of group effect, fixed effect, or interaction on behavioral outcome
    axes_handles{idx, 2} = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_position{idx, 2}, 'Visible', 'off');
    plot_behavioral_grid(analysis_parameters, plot_parameters, effect_grids{idx}, 'effects');
    
    %%% Plot a grid with colors indicating correlation of behavioral outcomes between groups
    axes_handles{idx, 3} = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_position{idx, 3}, 'Visible', 'off');
    plot_behavioral_grid(analysis_parameters, plot_parameters, behavior_correlation_grids{idx}, 'behavior_correlation');
    
    %%% Plot a grid with colors indicating correlation of behavioral outcomes with response time
    %%% If outcome is response time, which would be the last outcome analyzed in every case, plot analysis description and color maps
    axes_handles{idx, 4} = axes('Parent', figure_handle, 'Units', 'pixels', 'Position', axes_position{idx, 4}, 'Visible', 'off');
    if idx == n_outcomes
        plot_analysis_description(analysis_parameters, plot_parameters);
    else
        plot_behavioral_grid(analysis_parameters, plot_parameters, time_correlation_grids{idx}, 'time_correlation');
    end

end

print(plot_filename, '-dpng');
print(plot_filename, '-dsvg');

close all

end