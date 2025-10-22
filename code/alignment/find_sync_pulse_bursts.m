%%% This function takes an array of pulse times and inter pulse time within a burst
%%% obtained from configurations file, to identify pulses belonging to a burst.
%%% Returns logical array the size of input pulses and burst information.

function [diff_burst, n_bursts, burst_n_pulses, burst_starts, burst_ends] = find_sync_pulse_bursts(pulses, inter_burst_time)

differential = [0; diff(pulses)];
diff_burst = differential < (inter_burst_time + 20) & differential > 2;

isolated_burst_pulses = find(diff(diff(diff_burst)) == -2);

if ~isempty(isolated_burst_pulses)
    indices = isolated_burst_pulses + 1;
    diff_burst(indices) = false(length(indices), 1);
end

burst_starts = find(diff([diff_burst; 0]) == 1);
burst_ends = find(diff([diff_burst; 0]) == -1);

diff_burst(burst_starts) = true;

if length(burst_starts) > length(burst_ends)
    burst_starts = burst_starts(1:end - 1);
end

for idx = 1:length(burst_starts)
    diff_burst(burst_starts(idx):burst_ends(idx)) = true;
end

burst_n_pulses = burst_ends - burst_starts + 1;

n_bursts = length(burst_starts);

end