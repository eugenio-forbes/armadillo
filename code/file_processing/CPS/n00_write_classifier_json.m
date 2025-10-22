function n00_write_classifier_json(file_name, regularization, classes, features, classifier_results, channel_labels, frequencies, excluded_channels, bipolar_jacksheet_file)

features = mat2cell(features, ones(size(features, 1), 1), size(features, 2));

switch num2str(regularization)
    case '0'
        penalty = '<[]>';
        C = '<[]>';

    case '1'
        penalty = 'l1';
        C = 1 / classifier_results.lambda;

    case '2'
        penalty = 'l2';
        C = 1 / classifier_results.lambda;
end

if ~iscolumn(channel_labels)
    channel_labels = channel_labels';
end

if ~iscolumn(frequencies)
    frequencies = frequencies';
end

if ~iscolumn(classes)
    classes = classes';
end

if iscolumn(classifier_results.coefficients)
    classifier_results.coefficients = classifier_results.coefficients';
end

classifier_results.coefficients = mat2cell(classifier_results.coefficients, 1, size(classifier_results.coefficients, 2));

classifier_json = struct;
classifier_json.C            = C;
classifier_json.X            = features; %%% Mak sure features are rows per event
classifier_json.class_weight = 'balanced';
classifier_json.classes_     = [0; 1];

classifier_cross_validation_params = struct;
classifier_cross_validation_params.C            = C;
classifier_cross_validation_params.class_weight = {'balanced'};
classifier_cross_validation_params.solver       = {'liblinear'};

classifier_json.classifer_cross_validation_params = classifier_cross_validation_params;
classifier_json.classifier_type                   = 'sklearn.linear_model._logistic.LogisticRegression';
classifier_json.coef_                             = classifier_results.coefficients; %%% Make sure it is a row

coords = struct;
coords.channel   = channel_labels;
coords.frequency = frequencies;

classifier_json.coords = coords;

classifier_json.cross_validation_groups = classifier_results.cv_groups;
classifier_json.cross_validation_score  = classifier_results.cv_score.statistic;
classifier_json.dims                    = {'frequency';'channel'};
classifier_json.dual                    = false;

if ~isempty(excluded_channels)
    classifier_json.excluded_channels = excluded_channels;
else
    classifier_json.excluded_channels = '<{}>';
end

classifier_json.feature_names_in_ = '<[]>';
classifier_json.fit_intercept     = true;
classifier_json.intercept_        = classifier_results.intercept;
classifier_json.intercept_scaling = 1;
classifier_json.l1_ratio          = '<[]>';
classifier_json.max_iter          = 100;
classifier_json.montage_file      = bipolar_jacksheet_file;
classifier_json.multi_class       = 'auto';
classifier_json.n_features_in_    = size(features, 2);
classifier_json.n_iter_           = 3;
classifier_json.n_jobs            = '<[]>';
classifier_json.penalty           = penalty;
classifier_json.random_state      = '<[]>';

significance_test = struct;
significance_test.cv_permutation_test = classifier_results.cv_score;

classifier_json.significance_test = significance_test;

classifier_json.sklearn_version = '1.0.2';
classifier_json.solver          = 'liblinear';
classifier_json.time_stamp      = '01_01_2020__12:00:00';
classifier_json.tol             = 0.0001;
classifier_json.verbose         = 0;
classifier_json.warm_start      = false;
classifier_json.y               = classes;

n00_save_config(file_name, classifier_json);

end