%%% This function will take events and recording pulse times
%%% in the case where there is a mismatch in number of pulses.
%%% One set has been determined to be bigger than the other.
%%% Based on normal differential ratios of correctly matched pulses
%%% being within the range of 1.0025 and 0.9975, it attempts to
%%% identify pulses present in one set that are not present in the
%%% other. If not enough pulse pair differential ratios are outside
%%% of this range, it classifies the last exceeding pulses as bad.
%%% Returns a logical array indicating which pulses from the bigger
%%% set should be removed so that sizes match and ratios fall within
%%% range.

function bad_pulses = find_bad_pulses(bigger, smaller)

n_bigger = length(bigger);
n_smaller = length(smaller);

difference = n_bigger - n_smaller;

bad_pulses = false(n_bigger, 1);
bad_count = 0;
bad_ratio_found = true;

diff_smaller = diff([0; smaller]);

while bad_count < difference && bad_ratio_found
    
    temp_bigger = bigger(1:n_smaller + bad_count);
    temp_bigger(bad_pulses(1:n_smaller + bad_count)) = [];
    
    diff_bigger = diff([0; temp_bigger]);
    
    ratio = diff_bigger ./ diff_smaller;
    
    idx = 1;
    
    this_time_found = false;
    
    while idx <= n_smaller - 1 && ~this_time_found
        
        if ratio(idx) > 1.0025 || ratio(idx) < 0.9975
        
            if ratio(idx + 1) > 1.0025 || ratio(idx + 1) < 0.9975
                this_time_found = true;
                bad_pulses(idx + bad_count) = true;
                bad_count = bad_count + 1;
            end
            
        end
        
        idx = idx +1;
    
    end
    
    if ~this_time_found
        bad_ratio_found = false;
    end
    
end

if bad_count < difference 
    bad_pulses(n_smaller + bad_count + 1:end) = true(difference - bad_count, 1);
end

end