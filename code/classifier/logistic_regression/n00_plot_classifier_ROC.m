%%% This function plots the ROC curve of a classifier

function n00_plot_classifier_ROC(plot_file_name, combination)

classifier_results = combination.classifier_results{:};

ROC_curve   = classifier_results.ROC_curve;
specificity = classifier_results.specificity;
sensitivity = classifier_results.sensitivity;
cv_score    = classifier_results.cv_score;

figure('Units', 'pixels', 'Position', [0, 0, 360, 360], 'Visible', 'off')

hold on

plot(ROC_curve.false_positive, ROC_curve.true_positive)

text(0.7, 0.4, sprintf('AUC: %.02f',ROC_curve.AUC))
text(0.7, 0.35, sprintf('sensitivity: %.02f',sensitivity))
text(0.7, 0.3, sprintf('specificity: %.02f',specificity))

if isnumeric(cv_score.statistic)
    text(0.7, 0.25, sprintf('cv loss: %0.2f',cv_score.statistic))
    text(0.7, 0.2, sprintf('p: %.02f',cv_score.p_value))
end

hold off

print(plot_file_name,'-dpng')

close all

end
    