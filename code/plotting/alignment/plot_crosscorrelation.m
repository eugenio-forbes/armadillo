function plot_crosscorrelation(plot_file, crosscorrelations)

n_unmatched = length(crosscorrelations);

figure('Units', 'pixels', 'Position', [0 0 1920 1080], 'Visible', 'off')

for idx = 1:n_unmatched

    crosscorrelation = crosscorrelations{idx};
    difference       = length(crosscorrelation.R_squareds)-1;
    best_index       = find(crosscorrelation.R_squareds == max(crosscorrelation.R_squareds));
    line_x           = best_index-1;
    min_R            = min(crosscorrelation.R_squareds);
    max_R            = max(crosscorrelation.R_squareds);
    min_slope        = min(crosscorrelation.slopes);
    max_slope        = max(crosscorrelation.slopes);
    min_intercept    = min(crosscorrelation.intercepts);
    max_intercept    = max(crosscorrelation.intercepts);
    
    subplot(n_unmatched, 3, ((idx - 1) * 3) + 1)
    hold on
    scatter(0:difference, crosscorrelation.R_squareds);
    plot([line_x, line_x], [min_R, max_R]);
    hold off
    xlim([-1, difference + 1]);
    ylim([min_R, max_R]);
    
    subplot(n_unmatched, 3, ((idx - 1) * 3) + 2)
    hold on
    scatter(0:difference, crosscorrelation.slopes);
    plot([line_x, line_x], [min_slope, max_slope]);
    hold off
    xlim([-1, difference + 1]);
    ylim([min_slope, max_slope]);
    
    subplot(n_unmatched, 3, ((idx - 1) * 3) + 3)
    hold on
    scatter(0:difference, crosscorrelation.intercepts);
    plot([line_x, line_x], [min_intercept, max_intercept]);
    hold off
    xlim([-1, difference + 1]);
    ylim([min_intercept, max_intercept]);

end

print(plot_file, '-dpng')

close all

end