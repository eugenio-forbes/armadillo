%%% This function uses event normalized power features and classifier coefficients and intercept
%%% to get classification probabilities for all events corresponding to the features.

function probabilities = n00_solve_logistic_regression(features, coefficients, intercept)

n_features = size(features, 2);
n_coefficients = size(coefficients, 1);

if n_features ~= n_coefficients
    error('Number of coefficients does not match number of features input.\n');
end

results = (features * coefficients) + intercept;

probabilities = 1 ./ (1 + exp(-1 * results));

end