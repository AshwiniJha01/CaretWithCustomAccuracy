# In a machine learning project, a situation may arise where the default metric being used in training a model is not able to meet our accuracy objective. For example, we may be building a multiclass classification model, and we are more particular about achieving higher accuracy in a certain class (like capturing true positives in medical tests is more important than penalty for false positives).

# In R programming, caret package offers a functionality through its "trainControl" method that can help us do so. In this article, we will see how we can use caret package to train a model on the Iris (no surprise here) dataset. We will use a random forest algorithm in training a classification model and change the default metric overall accuracy to something else while training through cross-validation

# Let's read in the libraries we will need:
lapply(c("caret","dplyr", "ranger", "e1071"), require, character.only = T)

# A look at the dataset
str(iris)

head(iris)

# Declare the dependent and independent variables:
frmla <- formula(Species ~ .)

# Declaring a grid of parameters for the training process to go through while finding the optimal model
parameterGrid <- expand.grid(
  mtry = c(2,3),
  min.node.size = c(1,2,3),
  splitrule = "gini")
# This how the grid looks:
parameterGrid

# We are defining the seeds here for replicable results
set.seed(1234)
seeds <- vector(mode = "list", length = 6)
for(i in 1:6) seeds[[i]]<- sample.int(n=10000, 10)


# We will next train the model with default overall accuracy metric .We are not splitting the data into test and train, as iris dataset is small and I don't want to pass too few observations into the process. My objective is to help you with the coding process by demonstrating it, accuracy may or may not improve with the iris dataset.
modelRf <- caret::train(
  form = frmla,
  data = iris,
  tuneGrid = parameterGrid,
  method = "ranger", #algorithm to use
  num.tree = 500,
  classification = T,
  trControl = trainControl(verboseIter = T,
                           savePredictions = T,
                           seeds = seeds,
                           method = "cv", #cross validation for stable accuracy output
                           number = 5, #five fold cross validations
                           search = "grid" #to iterate over all combinations in tuneGrid (alternatively, for vast tuneGrid, you can set search = "random" and tuneLength as the number of random combinations from tuneGrid to test from)
  ))

# Let's see how does the accuracy look like:
modelRf$results
# Now we see that the accuracy is pretty much identical across the models with different parameters, this is expected as given the kind of simple data we are dealing with.

# We can also explicitly check the metric used in training the model:
modelRf$metric


# This is how the confusion matrix looks like with the best model of the lot:
confusionMatrix(modelRf)

# Now there are two ways in which you can introduce new metrics for the model training process to focus on: use the inbuilt metric Kappa or write a new function with your own customized accuracy metric. The parameters built in caret that help in this process are "metric" in train function and "summaryFunction" in trainControl function (There is a third way too, which is applicable to two class problems - inbuilt function "twoClassSummary", but we won't be seeing that here as we are working with multiclass problem. This one is also farily easy to use like the first way, and code is available in caret documentation)

# Let's look at the first way - Kappa
modelRfKappaMetric <- caret::train(
  form = frmla,
  data = iris,
  tuneGrid = parameterGrid,
  method = "ranger",
  num.tree = 500,
  classification = T,
  metric = "Kappa", # This is the parameter we have added to change the metric for training the model
  trControl = trainControl(verboseIter = T,
                           savePredictions = T,
                           seeds = seeds,
                           method = "cv",
                           number = 5,
                           search = "grid"
  ))

# Let's check the new metric used in training the model
modelRfKappaMetric$metric

# Let's see difference in the models:
modelRfKappaMetric$results
# We see that both Accuracy and Kappa values have increased compared to our previous model where we have used default accuracy metric. Another point to note is that the standard deviation in the Kappa values have decreased. One thing I would like to call out is that the improvement is too marginal to be called as significant, this is to be expected given the number of observaions and nature of distribution. My intention with this whole exercise is to help you become familiar with the functionalities in caret, how to program it so that you can try it in your business problems or projects.

# Next we look at the second way - customized accuracy metric
# We first build a function that will calculate the metric we are interested in using in the training process. It's upto our business problem and creative imagination what metric we design and use in the process. Here, to demonstrate the exercise and coding that goes along with it, I am going to use harmonic mean of overall accuracy and sensitivity of class "Virginica". Harmonic mean ensures the mean value is closer to the smaller of the two quantity. Assuming that detecting virginica class is important to my business case, I am skewing the accuracy metric towards how well does the training process do for detecting virginica along with overall accuracy.
customAccuracy <- function (data, lev = NULL, model = NULL){
  cf <- confusionMatrix(data$obs, data$pred)
  detectionRate <- cf$byClass[row.names(cf$byClass) == "virginica","Sensitivity"]
  overAllAccuracy <- as.numeric(cf$overall["Accuracy"])
  vec <- c(detectionRate, overAllAccuracy)
  customizedAccuracy <- 1/mean(1/vec)
  names(customizedAccuracy) <- "newAccuracyMetric"
  return(customizedAccuracy)
}

# Here we train different models using our customized accuracy metric:
modelRfCustomMetric <- caret::train(
  form = frmla,
  data = iris,
  tuneGrid = parameterGrid,
  method = "ranger",
  num.tree = 500,
  classification = T,
  metric = "newAccuracyMetric",
  trControl = trainControl(verboseIter = T,
                           savePredictions = T,
                           seeds = seeds,
                           method = "cv",
                           number = 5,
                           search = "grid",
                           summaryFunction = customAccuracy
  ))

# We can check that the metric in training the model is the one we have designed
modelRfCustomMetric$metric

# Let's looks at the confusion matrix
confusionMatrix(modelRfCustomMetric)

# We again see a slight increase in the accuracy compared to the first model with default accuracy, along with better sensitivity to class virginica, for which we have designed the custom accuracy.

# We now come to an end to this write up. When I was trying this customized accuracy methodology first time in my work, I had faced multiple errors and could not find much help over the internet. As a result, I took quite a bit of time to figure out the process through trial and error. I hope this article helps people like me in spending less time and effort around coding logistics so that they can focus more on solving a problem at hand.

# Try it out in your work, let me know if this helped in meeting specific accuracy objectives.

# May you get cleaner data! Cheers!
