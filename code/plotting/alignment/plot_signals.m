function plot_signals(subplot_title, signals, color1, color2, color3)

ratio = (1 + sqrt(5))/2;

n5_min = 300000;
t5_min = 1:n5_min;

n_points = size(signals, 2);
n_lines = ceil(n_points / n5_min);

x_limits = [-5000, 305000];
y_limits = [0, ratio * (n_lines + 2)];

hold on

for idx = 1:n_lines

    chunk = t5_min + (n5_min * (idx - 1));
    offset = ratio * (n_lines - idx + 1);
    
    plot(t5_min, signals(3, chunk) + offset, 'Color', color3, 'LineWidth', 0.5)
    plot(t5_min, signals(2, chunk) + offset, 'Color', color2, 'LineWidth', 0.5)
    plot(t5_min, signals(1, chunk) + offset, 'Color', color1, 'LineWidth', 0.5)

end

text(150000, y_limits(2), subplot_title, 'FontSize', 12, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'top');

hold off

xlim(x_limits);xticks([]);xticklabels([]);
ylim(y_limits);yticks([]);yticklabels([]);

end