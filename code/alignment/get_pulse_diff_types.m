function [diff_test,diff_break,diff_event,n_pulse_tests,n_breaks,test_n_pulses,...
    test_starts,block_starts,block_ends] = get_pulse_diff_types(pulses)

n_pulses = length(pulses);
differential = diff(pulses)/1000;

diff_test = false(n_pulses,1);
diff_event = false(n_pulses,1);
diff_break = false(n_pulses,1);

diff_test(2:end) = differential < 1.1;
diff_event(2:end) = ~diff_test(2:end) & differential < 100;
diff_break(2:end) = differential >= 100;

isolated_test_pulses = find(diff(diff(diff_test)) == -2);
if ~isempty(isolated_test_pulses)
    indices = isolated_test_pulses + 1;
    diff_test(indices) = false(length(indices),1);
    diff_event(indices) = true(length(indices),1);
end

test_starts = find(diff(diff_test)==1);
test_ends = find(diff(diff_test)==-1);
diff_test(test_starts) = true;
diff_break(test_starts) = false;
if length(test_starts) > length(test_ends)
    test_starts = test_starts(1:end-1);
end

for idx = 1:length(test_starts)
    diff_event(test_starts(idx):test_ends(idx)) = false;
    diff_test(test_starts(idx):test_ends(idx)) = true;
end

first_event = find(diff_event,1,'first');

block_starts = [first_event;find(diff(diff_event)==1)];
block_ends =  [find(diff(diff_event)==-1);n_pulses];
block_starts(block_starts<first_event) = [];
block_ends(block_ends<first_event) = [];

test_n_pulses = test_ends - test_starts + 1;

n_pulse_tests = length(test_starts);
n_breaks = length(block_starts);
end