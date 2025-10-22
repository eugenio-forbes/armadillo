function plot_behavior_distributions(analysis_parameters, plot_parameters, behavior, distributions)

hold on

subplot_width  = plot_parameters.distribution_width;
subplot_height = plot_parameters.distribution_height;
x_margin       = plot_parameters.x_margin;
y_margin       = plot_parameters.y_margin;
font_name      = plot_parameters.font_name;
font_size      = plot_parameters.font_size;

n_groups      = analysis_parameters.n_groups;
group_labels  = analysis_parameters.group_labels;
has_condition = analysis_parameters.has_condition;

golden_ratio = (1 + sqrt(5)) / 2;

x_space = [x_margin, subplot_width - x_margin];
x_ticks = linspace(x_space(1), x_space(2), 6);

violin_x = linspace(x_space(1), x_space(2), 100);
violin_x = [violin_x(1), violin_x, violin_x(end)];
violin_x = [violin_x, fliplr(violin_x)];

distribution_min = min(cellfun(@min, distributions));
distribution_max = max(cellfun(@max, distributions));

y_space = [y_margin, subplot_height - y_margin];
y_height = diff(y_space) / n_groups;
y_factor = y_height / (golden_ratio * 2);
y_ticks = flipud((y_margin + (y_height / 2):y_height:(subplot_height - y_margin - (y_height / 2)))');

switch behavior
    case {'f_has_response', 'f_is_correct', 'f_response_correct', 'f_responses'}
        x_min = 0;
        x_max = 1;

    case {'n_has_response', 'n_is_correct', 'n_responses'}
        x_min = 0;
        x_max = distribution_max;

    case {'response_time'}
        x_min = distribution_min;
        x_max = distribution_max;
end

x_range = linspace(x_min, x_max, 100);
x_tick_labels = {num2str(x_min), '', '', '', '', num2str(x_max)};

x_label = strrep(behavior, '_', ' ');
x_label_x = subplot_width / 2;
x_label_y = subplot_height - 1;

text(x_label_x, x_label_y, x_label, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

y_label = 'Distribution';
y_label_x = 1;
y_label_y = subplot_height / 2;

text(y_label_x, y_label_y, y_label, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'center', 'Rotation', 90);

for idx = 1:length(x_ticks)

    plot(repmat(x_ticks(idx), 2, 1), [y_space(1), y_space(1) + 2], '-k', 'LineWidth', 0.5);
    
    if ~strcmp(x_tick_labels{idx}, '')
        text(x_ticks(idx), y_space(1), x_tick_labels{idx}, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');
    end
    
end

for idx = 1:n_groups

    plot([x_space(2), x_space(2) - 2], repmat(y_ticks(idx), 2, 1), '-k', 'LineWidth', 0.5);
    
    text(x_space(2), y_ticks(idx), group_labels{idx}, 'FontName', font_name, 'FontSize', font_size, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'center');
    
    %%% If the analysis has a condition, half of violin is distribution for control and other half is distrubution for condition
    if has_condition
        
        violin_y_control   = n00_convert_distribution_to_violin(distributions{(idx * 2) -1}, x_range);
        violin_y_condition = n00_convert_distribution_to_violin(distributions{idx * 2}, x_range);
        violin_y = [violin_y_control, fliplr(-1 * violin_y_condition)];
    
    else
    
        violin_y = n00_convert_distribution_to_violin(distributions{idx}, x_range);
        violin_y = [violin_y, fliplr(-1 * violin_y)];
            
    end
    
    violin_y = (violin_y * y_factor) + y_ticks(idx);

    fill(violin_x, violin_y, 'EdgeColor', 'none', 'FaceColor', [0.75, 0.5, 0.5], 'FaceAlpha', 0.5);
    
    plot([x_space(1), x_space(2)], repmat(y_ticks(idx), 1, 2), '-k')
    
end

xlim(gca, [0, subplot_width]); xticks([]); xticklabels([]);
ylim(gca, [0, subplot_height]); yticks([]); yticklabels([]);

hold off

end


function violin_y = n00_convert_distribution_to_violin(distribution, x_range)

violin_y = zeros(1, 100);

n = length(distribution);

if n > 0

    %%% Rule of thumb calculation of bandwidth
    sigma = std(distribution);
    bandwidth = (4 * (sigma^5) / (3 * n) )^(1/5);

    %%% Calculate kernel-smoothed probability density function
    [violin_y, ~] = ksdensity(observations, x_range, 'Bandwidth', bandwidth);

    %%% Flank probability density function with zeros so that violin fill is complete
    violin_y = [0, violin_y, 0];

    %%% Normalized based on max value so that each violin max width is 1 (to be multiplied by a factor)
    violin_y = (violin_y / max(violin_y)) * 0.5;
    
end

end