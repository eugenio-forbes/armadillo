n_sessions = height(alignment_table);

figure

hold on

max_error = 0;

for idx = 1:n_sessions

    offset_error = alignment_table.offset_error{idx};

    this_max = max(abs(offset_error));

    if this_max > max_error
        max_error = this_max;
    end

    n_offsets = length(offset_error);
    x = repmat(idx, n_offsets, 1) + (0.05 * randn(n_offsets, 1));

    scatter(x, abs(offset_error))

end

hold off

xlim([0, n_sessions + 1])
ylim([0, max_error])
yticks([1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000])

set(gca,'YScale','log');