%%% This function takes an array of pulse times to identify breaks in pulses
%%% (interpulse intervals much longer than expected).
%%% Returns logical array the size of input pulses and break information.

function [diff_break, n_breaks, break_starts, break_ends] = find_sync_pulse_breaks(pulses)

differential = [0; diff(pulses)];
diff_break = differential > 7500; %%% 30 seconds of missing pulses to raise flags?

isolated_burst_pulses = find(diff(diff(diff_break)) == -2);

if ~isempty(isolated_burst_pulses)
    indices = isolated_burst_pulses + 1;
    diff_break(indices) = false(length(indices), 1);
end

break_starts = find(diff(diff_break) == 1);
break_ends = find(diff(diff_break) == -1);

diff_break(break_starts) = true;

if length(break_starts) > length(break_ends)
    break_starts = break_starts(1:end - 1);
end

for idx = 1:length(break_starts)
    diff_break(break_starts(idx):break_ends(idx)) = true;
end

n_breaks = length(break_starts);

end