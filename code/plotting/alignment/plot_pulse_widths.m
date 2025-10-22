function plot_pulse_widths(plot_file, pulse_widths)

figure('Units', 'pixels', 'Position', [0 0 1920 1080], 'Visible', 'off')

histogram(pulse_widths, 'BinMethod', 'integers');

print(plot_file, '-dpng');

close all

end