function [bad_pulses, crosscorrelation] = crosscorrelate_pulses(bigger, smaller)

n_bigger = length(bigger);
n_smaller = length(smaller);

crosscorrelation = struct;
bad_pulses = false(n_bigger, 1);

difference = n_bigger - n_smaller;

slopes = NaN(difference + 1, 1);
intercepts = NaN(difference + 1, 1);
R_squareds = NaN(difference + 1, 1);

for idx = 1:n_smaller + 1

    temp_bigger = bigger;
    temp_bigger(idx:idx + difference - 1) = [];
    
    coefficients = polyfit(temp_bigger, smaller + temp_bigger(1), 1);
    
    slopes(idx) = coefficients(1);
    intercepts(idx) = coefficients(2);
    fitted_pulses = round(polyval(coefficients, temp_bigger));
    
    R = corrcoef(smaller + temp_bigger(1), fitted_pulses);
    R_squareds(idx) = R(1, 2) ^ 2;

end

best_R_squared = max(R_squareds);
best_index = find(R_squareds == best_R_squared, 1, 'first');
bad_pulses(best_index:best_index + difference - 1) = true(difference, 1);
n_bad_pulses = sum(bad_pulses);

crosscorrelation.slopes     = slopes;
crosscorrelation.intercepts = intercepts;
crosscorrelation.R_squareds = R_squareds;

end