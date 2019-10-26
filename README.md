# CaretWithCustomAccuracy
This repository has demo code for showing how to train models with caret using a customised accuracy metric

In a machine learning project, a situation may arise where the default metric being used in training a model is not able to meet our accuracy objective. For example, we may be building a multiclass classification model, and we are more particular about achieving higher accuracy in a certain class (like capturing true positives in medical tests is more important than penalty for false positives).

In R programming, caret package offers a functionality through its "trainControl" method that can help us do so. In this article, we will see how we can use caret package to train a model on the Iris (no surprise here) dataset. We will use a random forest algorithm in training a classification model and change the default metric overall accuracy to something else while training through cross-validation.
