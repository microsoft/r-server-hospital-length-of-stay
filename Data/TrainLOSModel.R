library(RevoScaleR)

####################################################################################################
## Training regression models to answer questions on whether an engine will fail  fail in different 
## cycles. The models will be trained include:
## 1. Decision forest;
## 3. Boosted decision tree;
## Input : The processed train and test dataset in SQL tables
## Output: The evaluations on test dataset and the metrics saved in SQL tables
####################################################################################################
####################################################################################################
## Connection string and compute context
####################################################################################################
connection_string <- "Driver=SQL Server;
Trusted_Connection=True;
Server=lengthofstayvm;
Database=SolutionAcc;"

print(connection_string)

sql_share_directory <- paste("c:\\AllShare\\", Sys.getenv("USERNAME"), sep = "")
dir.create(sql_share_directory, recursive = TRUE, showWarnings = FALSE)
sql <- RxInSqlServer(connectionString = connection_string, 
                     shareDir = sql_share_directory)
local <- RxLocalParallel()
####################################################################################################
## Drop variables and make label a factor in train table
####################################################################################################
rxSetComputeContext(sql)
train_table_name <- "lengthofstay_Classification_Train_Data"
train_table <- RxSqlServerData(table = train_table_name, 
                               connectionString = connection_string,
                               colInfo = list(lengthofstay = list(type = "factor", levels = c("1", "2", "3","4")),gender=list(type = "factor", levels = c("M","F"))
                                              ,dialysisrenalendstage=list(type = "factor", levels = c("1","0")),
                                              asthma=list(type = "factor", levels = c("1","0")),
                                              irondef=list(type = "factor", levels = c("1","0")),
                                              pneum=list(type = "factor", levels = c("1","0")),
                                              substancedependence=list(type = "factor", levels = c("1","0")),
                                              psychologicaldisordermajor=list(type = "factor", levels = c("1","0")),
                                              depress=list(type = "factor", levels = c("1","0")),
                                              psychother=list(type = "factor", levels = c("1","0")),
                                              fibrosisandother=list(type = "factor", levels = c("1","0")),
                                              malnutrition=list(type = "factor", levels = c("1","0"))
                               ))

responseVar='lengthofstay'
predictors= c("gender","dialysisrenalendstage","asthma","irondef","pneum",
              "substancedependence",
              "psychologicaldisordermajor",
              "depress",
              "psychother",
              "fibrosisandother",
              "malnutrition",
              "hemo",
              "hematocritic",
              "neutrophils",
              "sodium",
              "glucose",
              "bloodureanitro",
              "creatinine",
              "bmi",
              "pulse",
              "respiration",
              "secondarydiagnosisnonicd9",
              "rcount")
formula   <- as.formula(paste(responseVar,paste("~", paste(predictors, collapse = "+"))))


####################################################################################################
## Import test into data frame for faster prediction and model evaluation
####################################################################################################
test_table_name <- "lengthofstay_Classification_Test_Data"
test_table <- RxSqlServerData(table = test_table_name,
                              connectionString = connection_string,
                              colInfo = list(lengthofstay = list(type = "factor", levels = c("1", "2", "3","4")),gender=list(type = "factor", levels = c("M","F"))
                                             ,dialysisrenalendstage=list(type = "factor", levels = c("1","0")),
                                             asthma=list(type = "factor", levels = c("1","0")),
                                             irondef=list(type = "factor", levels = c("1","0")),
                                             pneum=list(type = "factor", levels = c("1","0")),
                                             substancedependence=list(type = "factor", levels = c("1","0")),
                                             psychologicaldisordermajor=list(type = "factor", levels = c("1","0")),
                                             depress=list(type = "factor", levels = c("1","0")),
                                             psychother=list(type = "factor", levels = c("1","0")),
                                             fibrosisandother=list(type = "factor", levels = c("1","0")),
                                             malnutrition=list(type = "factor", levels = c("1","0"))
                              ))

prediction_df <- rxImport(inData = test_table)

####################################################################################################
## Mulit-classification model evaluation metrics
####################################################################################################
evaluate_model <- function(observed, predicted) {
  confusion <- table(observed, predicted)
  num_classes <- nlevels(observed)
  tp <- rep(0, num_classes)
  fn <- rep(0, num_classes)
  fp <- rep(0, num_classes)
  tn <- rep(0, num_classes)
  accuracy <- rep(0, num_classes)
  precision <- rep(0, num_classes)
  recall <- rep(0, num_classes)
  for(i in 1:num_classes) {
    tp[i] <- sum(confusion[i, i])
    fn[i] <- sum(confusion[-i, i])
    fp[i] <- sum(confusion[i, -i])
    tn[i] <- sum(confusion[-i, -i])
    accuracy[i] <- (tp[i] + tn[i]) / (tp[i] + fn[i] + fp[i] + tn[i])
    precision[i] <- tp[i] / (tp[i] + fp[i])
    recall[i] <- tp[i] / (tp[i] + fn[i])
  }
  overall_accuracy <- sum(tp) / sum(confusion)
  average_accuracy <- sum(accuracy) / num_classes
  micro_precision <- sum(tp) / (sum(tp) + sum(fp))
  macro_precision <- sum(precision) / num_classes
  micro_recall <- sum(tp) / (sum(tp) + sum(fn))
  macro_recall <- sum(recall) / num_classes
  metrics <- c("Overall accuracy" = overall_accuracy,
               "Average accuracy" = average_accuracy,
               "Micro-averaged Precision" = micro_precision,
               "Macro-averaged Precision" = macro_precision,
               "Micro-averaged Recall" = micro_recall,
               "Macro-averaged Recall" = macro_recall)
  return(metrics)
}
####################################################################################################
## Decision forest modeling
####################################################################################################
rxSetComputeContext(sql)

forest_model <- rxDForest(formula = formula,
                          data = train_table,
                          nTree = 8,
                          maxDepth = 32,
                          mTry = 35,
                          seed = 5)
rxSetComputeContext(local)
forest_prediction <- rxPredict(modelObject = forest_model,
                               data = prediction_df,
                               type = "prob",
                               overwrite = TRUE)

names(forest_prediction) <- c("Forest_Probability_Class_0",
                              "Forest_Probability_Class_1",
                              "Forest_Probability_Class_2",
                              "Forest_Probability_Class_3",
                              "Forest_Prediction")

forest_metrics <- evaluate_model(observed = prediction_df$lengthofstay,
                                 predicted = forest_prediction$Forest_Prediction)
####################################################################################################
## Boosted tree modeling
####################################################################################################
rxSetComputeContext(sql)
boosted_model <- rxBTrees(formula = formula,
                          data = train_table,
                          learningRate = 0.2,
                          minSplit = 10,
                          minBucket = 10,
                          nTree = 100,
                          seed = 5,
                          lengthofstaysFunction = "multinomial")
rxSetComputeContext(local)
boosted_prediction <- rxPredict(modelObject = boosted_model,
                                data = prediction_df,
                                type = "prob",
                                overwrite = TRUE)

names(boosted_prediction) <- c("Boosted_Probability_Class_0",
                               "Boosted_Probability_Class_1",
                               "Boosted_Probability_Class_2",
                               "Boosted_Probability_Class_3",
                               "Boosted_Prediction")

boosted_metrics <- evaluate_model(observed = prediction_df$lengthofstay,
                                  predicted = boosted_prediction$Boosted_Prediction)
####################################################################################################
## Write test predictions to SQL
####################################################################################################
rxSetComputeContext(local)
predictions <- cbind(prediction_df$eid, prediction_df$vdate, forest_prediction, 
                     boosted_prediction)
colnames(predictions)[1] <- "eid"
colnames(predictions)[2] <- "vdate"

prediction_table <- RxSqlServerData(table = "Multiclass_prediction",
                                    connectionString = connection_string)
rxDataStep(inData = predictions,
           outFile = prediction_table,
           overwrite = TRUE)
####################################################################################################
## Combine metrics and write to SQL
####################################################################################################
metrics_df <- rbind(forest_metrics, boosted_metrics)
metrics_df <- as.data.frame(metrics_df)
rownames(metrics_df) <- NULL
Algorithms <- c("Decision Forest",
                "Boosted Decision Tree"
)
metrics_df <- cbind(Algorithms, metrics_df)

metrics_table <- RxSqlServerData(table = "Multiclass_metrics",
                                 connectionString = connection_string)
rxDataStep(inData = metrics_df,
           outFile = metrics_table,
           overwrite = TRUE)
####################################################################################################
## Cleanup
####################################################################################################
rm(list = ls())