%%% This function takes binary classes, corresponding features,
%%% and a list of groups (partitions) to train logistic regression
%%% classifier. Returns classifier results.

function classifier_results = single_subject_logistic_regression(varargin)
if isempty(varargin)
    classes = [];
    features = [];
    groups = [];
else
    classes = varargin{1};
    features = varargin{2};
    groups = varargin{3};
end

holdout_fraction = 0.1;

n_observations = length(classes);
unique_classes = unique(classes);
n_classes = length(unique_classes);
unique_groups = unique(groups);
n_groups = length(unique_groups);
n_features = size(features, 2);

is_testing_set = false(n_observations, 1);

for idx = 1:n_groups
    
    this_group = unique_groups(idx);
    
    for jdx = 1:n_classes
    
        this_class = unique_classes(jdx);
        this_set = groups == this_group & classes == this_class;
        
        set_size = sum(this_set);
        
        n_holdout = ceil(set_size * holdout_fraction);
        holdout_indices = find(this_set, n_holdout, 'last');
        is_testing_set(holdout_indices) = true(n_holdout, 1);
        
     end

end

is_testing_set = groups == unique_groups(n_groups);

class_weights = 1 ./ histcounts(categorical(classes(~is_testing_set)));
observation_weights = arrayfun(@(x) class_weights(x+1), classes(~is_testing_set));

logreg_model = fitglm(features(~is_testing_set, :), classes(~is_testing_set), ...
    'Distribution', 'binomial', 'Weights', observation_weights);

classifier_probabilities = predict(logreg_model, features(is_testing_set, :));

predicted_classes = classifier_probabilities >= 0.5;

confusion_matrix = confusionmat(classes(is_testing_set), double(predicted_classes));

specificity = confusion_matrix(2, 2) / (confusion_matrix(2, 2) + confusion_matrix(2, 1));
sensitivity = confusion_matrix(1, 1) / (confusion_matrix(1, 1) + confusion_matrix(1, 2));

[false_positive, true_positive, thresholds, AUC] = perfcurve(classes(is_testing_set), classifier_probabilities, true);
ROC_curve = struct;
ROC_curve.false_positive = false_positive;
ROC_curve.true_positive  = true_positive;
ROC_curve.thresholds     = thresholds;
ROC_curve.AUC            = AUC;

intercept    = logreg_model.Coefficients.Estimate(1);
coefficients = logreg_model.Coefficients.Estimate(2:n_features + 1);

cv_score = struct;
cv_score.statistic = '<[]>';
cv_score.p_value   = '<[]>';
cv_groups          = double(is_testing_set);

classifier_results = struct;
classifier_results.regularization = 0;
classifier_results.intercept      = intercept;
classifier_results.coefficients   = coefficients;
classifier_results.specificity    = specificity;
classifier_results.sensitivity    = sensitivity;
classifier_results.ROC_curve      = ROC_curve;
classifier_results.cv_score       = cv_score;
classifier_results.cv_groups      = cv_groups;

end