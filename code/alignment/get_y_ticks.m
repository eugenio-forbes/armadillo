function [y_limits, y_ticks, y_tick_labels] = get_y_ticks(values)

min_value = min(values);
max_value = max(values);

range = max_value - min_value;

if range > 0
    y_limits = [min_value - (range * .1), max_value + (range * .1)];
    y_ticks = min_value:(range / 10):max_value;
    y_tick_labels = repelem({''}, length(y_ticks), 1);
    y_tick_labels{1} = num2str(min_value);
    y_tick_labels{end} = num2str(max_value);
else
    y_limits = [min_value - 1, min_value + 1];
    y_ticks = min_value;
    y_tick_labels = {num2str(min_value)};
end

end