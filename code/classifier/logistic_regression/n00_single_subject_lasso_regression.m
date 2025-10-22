%%% This function takes binary classes, corresponding features,
%%% and a list of groups (partitions) to train lasso regression
%%% classifier. Returns classifier results.

function classifier_results = n00_single_subject_lasso_regression(varargin)
if isempty(varargin)
    classes = [];
    features = [];
    groups = [];
else
    classes = varargin{1};
    features = varargin{2};
    groups = varargin{3};
end

n_permutations = 100;
unique_groups = unique(groups);
n_groups = length(unique_groups);
class_weights = 1./histcounts(categorical(classes));
observation_weights = arrayfun(@(x) class_weights(x + 1), classes);
crossvalidation_partition = cvpartition('CustomPartition', groups+1);

logreg_CV_model = ...
    fitclinear(features', classes, ...
    'ObservationsIn', 'columns', ...
    'Weights', observation_weights, ...
    'Learner', 'logistic', ...
    'Regularization', 'lasso', ...
    'Solver', {'sgd', 'sparsa'}, ...
    'Lambda', 'auto', ...
    'OptimizeHyperparameters', 'Lambda', ...
    'ClassNames', [0, 1], ...
    'HyperparameterOptimizationOptions', struct('CVPartition', crossvalidation_partition));

lambda = logreg_CV_model.Lambda;

logreg_CV_model = ...
    fitclinear(features', classes, ...
    'ObservationsIn', 'columns', ...
    'Weights', observation_weights, ...
    'Learner', 'logistic', ...
    'Regularization', 'lasso', ...
    'Solver', {'sgd', 'sparsa'}, ...
    'Lambda', lambda, ...
    'ClassNames', [0, 1], ...
    'CVPartition', crossvalidation_partition);

[predicted_classes, classifier_probabilities] = kfoldPredict(logreg_CV_model);
classifier_probabilities = classifier_probabilities(:, 2);

confusion_matrix = confusionmat(classes, predicted_classes);

specificity = confusion_matrix(2, 2) / (confusion_matrix(2, 2) + confusion_matrix(2, 1));
sensitivity = confusion_matrix(1, 1) / (confusion_matrix(1, 1) + confusion_matrix(1, 2));

[false_positive, true_positive, thresholds, AUC] = perfcurve(classes, classifier_probabilities, true);
ROC_curve = struct;
ROC_curve.false_positive = false_positive;
ROC_curve.true_positive  = true_positive;
ROC_curve.thresholds     = thresholds;
ROC_curve.AUC            = AUC;

last_model = logreg_CV_model.Trained{n_groups};

intercept    = last_model.Bias;
coefficients = last_model.Beta;

cv_score = struct;
cv_score.statistic = kfoldLoss(logreg_CV_model);
cv_score.p_value   = cv_ridge_permutation_test(features, classes, observation_weights, crossvalidation_partition, lambda, cv_score.statistic, n_permutations);

classifier_results = struct;
classifier_results.regularization = 1;
classifier_results.intercept      = intercept;
classifier_results.coefficients   = coefficients;
classifier_results.lambda         = lambda;
classifier_results.cv_score       = cv_score;
classifier_results.cv_groups      = groups+1;
classifier_results.specificity    = specificity;
classifier_results.sensitivity    = sensitivity;
classifier_results.ROC_curve      = ROC_curve;

end


function p_value = cv_ridge_permutation_test(features, classes, observation_weights, crossvalidation_partition, lambda, original_loss, n_permutations)

n_observations = length(classes);
permutation_losses = zeros(n_permutations, 1);

for idx = 1:n_permutations
    
    permuted_indices = randperm(n_observations);
    
    permuted_CV_model = ...
        fitclinear(features', classes(permuted_indices), ...
        'ObservationsIn', 'columns', ...
        'Weights', observation_weights, ...
        'Learner', 'logistic', ...
        'Regularization', 'lasso', ...
        'Solver', {'sgd', 'sparsa'}, ...
        'Lambda', lambda, ...
        'ClassNames', [0, 1], ...
        'CVPartition', crossvalidation_partition);
    
    permutation_losses(idx) = kfoldLoss(permuted_CV_model);

end

p_value = mean(permutation_losses <= original_loss);

end