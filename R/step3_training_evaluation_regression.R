##########################################################################################################################################
## This R script will do the following:
## 1. Split LoS into a Training LoS_Train, and a Testing set LoS_Test.  
## 2. Train regression models Random Forest (RF) and Gradient Boosting Trees (GBT) on LoS_Train, and save them to SQL. 
## 3. Score RF and GBT on LoS_Test.

## Input : Data set LoS
## Output: Random forest and GBT models saved to SQL. 

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load revolution R library. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the compute context to Local for splitting. It will be changed to sql for modelling.
rxSetComputeContext(local)


##########################################################################################################################################

## Function to get the top n rows of a table stored on SQL Server.
## You can execute this function at any time during  your progress by removing the comment "#", and inputting:
##  - the table name.
##  - the number of rows you want to display.

##########################################################################################################################################

display_head <- function(table_name, n_rows){
  table_sql <- RxSqlServerData(sqlQuery = sprintf("SELECT TOP(%s) * FROM %s", n_rows, table_name), connectionString = connection_string)
  table <- rxImport(table_sql)
  print(table)
}

# table_name <- "insert_table_name"
# n_rows <- 10
# display_head(table_name, n_rows)


##########################################################################################################################################

## Input: Point to the SQL table with the data set for modeling

##########################################################################################################################################

LoS <- RxSqlServerData(table = "LoS", connectionString = connection_string, stringsAsFactors = T)

##########################################################################################################################################

##	Specify the type of the features before the training. The target variable is converted to integer for regression.

##########################################################################################################################################

## Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("ALTER TABLE LoS ALTER COLUMN lengthofstay int;", sep=""))

column_info <- rxCreateColInfo(LoS)

##########################################################################################################################################

##	Split the data set into a training and a testing set 

##########################################################################################################################################

# Randomly split the data into a training set and a testing set, with a splitting % p.
# p % goes to the training set, and the rest goes to the testing set. Default is 70%. 

p <- "70" 

## Create the Train_Id table containing Lead_Id of training set. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Train_Id;", sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf(
  "SELECT eid
   INTO Train_Id
   FROM LoS
   WHERE ABS(CAST(BINARY_CHECKSUM(eid, NEWID()) as int)) %s < %s ;"
  ,"% 100", p ))

## Point to the training set. It will be created on the fly when training models. 
LoS_Train <- RxSqlServerData(  
  sqlQuery = "SELECT *   
              FROM LoS 
              WHERE eid IN (SELECT eid from Train_Id)",
  connectionString = connection_string, colInfo = column_info)

## Point to the testing set. It will be created on the fly when testing models. 
LoS_Test <- RxSqlServerData(  
  sqlQuery = "SELECT *   
              FROM LoS 
              WHERE eid NOT IN (SELECT eid from Train_Id)",
  connectionString = connection_string, colInfo = column_info)


##########################################################################################################################################

##	Specify the variables to keep for the training 

##########################################################################################################################################

# Write the formula after removing variables not used in the modeling.
variables_all <- rxGetVarNames(LoS)
variables_to_remove <- c("eid", "vdate", "discharged")
traning_variables <- variables_all[!(variables_all %in% c("lengthofstay", variables_to_remove))]
formula <- as.formula(paste("lengthofstay ~", paste(traning_variables, collapse = "+")))


##########################################################################################################################################

##	Random Forest Training and saving the model to SQL

##########################################################################################################################################

# Set the compute context to SQL for model training. 
rxSetComputeContext(sql)

# Train the Random Forest.
forest_model_reg <- rxDForest(formula = formula,
                              data = LoS_Train,
                              nTree = 40,
                              minSplit = 10,
                              minBucket = 5,
                              cp = 0.00005,
                              seed = 5)

# Save the Random Forest in SQL. The compute context is set to Local in order to export the model. 
rxSetComputeContext(local)
saveRDS(forest_model_reg, file = "forest_model_reg.rds")
forest_model_reg_raw <- readBin("forest_model_reg.rds", "raw", n = file.size("forest_model_reg.rds"))
forest_model_reg_char <- as.character(forest_model_reg_raw)
forest_model_reg_sql <- RxSqlServerData(table = "Forest_Model_Reg", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = forest_model_reg_char ), outFile = forest_model_reg_sql, overwrite = TRUE)

# Set back the compute context to SQL.
rxSetComputeContext(sql)


##########################################################################################################################################

##	Gradient Boosted Trees Training and saving the model to SQL

##########################################################################################################################################

# Train the GBT.
btree_model_reg <- rxBTrees(formula = formula,
                            data = LoS_Train,
                            learningRate = 0.05,
                            minSplit = 10,
                            minBucket = 5,
                            cp = 0.0005,
                            nTree = 40,
                            seed = 5,
                            lossFunction = "gaussian")

# Save the GBT in SQL. The Compute Context is set to Local in order to export the model. 
rxSetComputeContext(local)
saveRDS(btree_model_reg, file = "btree_model_reg.rds")
btree_model_reg_raw <- readBin("btree_model_reg.rds", "raw", n = file.size("btree_model_reg.rds"))
btree_model_reg_char <- as.character(btree_model_reg_raw)
btree_model_reg_sql <- RxSqlServerData(table = "Btree_Model_Reg", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = btree_model_reg_char ), outFile = btree_model_reg_sql, overwrite = TRUE)

##########################################################################################################################################

## Regression model evaluation metrics

##########################################################################################################################################

# Write a function that computes regression performance metrics. 
evaluate_model_reg <- function(observed, predicted, model) {
  
  print(model)
  ## Regression Metrics
  mean_observed <- mean(observed)
  se <- (observed - predicted)^2
  ae <- abs(observed - predicted)
  sem <- (observed - mean_observed)^2
  aem <- abs(observed - mean_observed)
  mae <- mean(ae)
  rmse <- sqrt(mean(se))
  rae <- sum(ae) / sum(aem)
  rse <- sum(se) / sum(sem)
  rsq <- 1 - rse
  
  ## Classification Metrics when the prediction is rounded to the nearest integer. 
  predicted <- factor(round(predicted), levels = c("1","2","3","4"))
  observed <- factor(observed, levels = c("1","2","3","4"))
  
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
  
  ## Writing all the performance metrics. 
  metrics <- c("Mean Absolute Error" = mae,
               "Root Mean Squared Error" = rmse,
               "Relative Absolute Error" = rae,
               "Relative Squared Error" = rse,
               "Coefficient of Determination" = rsq,
               "Overall accuracy (Rounded Prediction)" = overall_accuracy,
               "Average accuracy (Rounded Prediction)" = average_accuracy,
               "Micro-averaged Precision (Rounded Prediction)" = micro_precision,
               "Macro-averaged Precision (Rounded Prediction)" = macro_precision,
               "Micro-averaged Recall (Rounded Prediction)" = micro_recall,
               "Macro-averaged Recall (Rounded Prediction)" = macro_recall)
  print(metrics)
  print("Confusion Matrix when the prediction is rounded")
  print(confusion)
  return(metrics)
}

##########################################################################################################################################

##	Random Forest Scoring

##########################################################################################################################################

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_RF_Reg <- RxSqlServerData(table = "Forest_Prediction_Reg", stringsAsFactors = T, connectionString = connection_string)
rxPredict(forest_model_reg, data = LoS_Test, outData = Prediction_Table_RF_Reg, overwrite = T, type = "response",
          extraVarsToWrite = c("lengthofstay"))

Prediction_RF_Reg<- rxImport(inData = Prediction_Table_RF_Reg, stringsAsFactors = T, outFile = NULL)

# Compute the performance metrics of the model.
Metrics_RF_Reg <- evaluate_model_reg(observed = Prediction_RF_Reg$lengthofstay,
                                    predicted = Prediction_RF_Reg$lengthofstay_Pred,
                                    model = "RF")


##########################################################################################################################################

##	Gradient Boosted Trees Scoring 

##########################################################################################################################################

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_GBT_Reg <- RxSqlServerData(table = "Boosted_Prediction_Reg", stringsAsFactors = T, connectionString = connection_string)
rxPredict(btree_model_reg,data = LoS_Test, outData = Prediction_Table_GBT_Reg, overwrite = T, type="response",
          extraVarsToWrite = c("lengthofstay"))

Prediction_GBT_Reg <- rxImport(inData = Prediction_Table_GBT_Reg, stringsAsFactors = T, outFile = NULL)

# Compute the performance metrics of the model.
Metrics_GBT_Reg <- evaluate_model_reg(observed = Prediction_GBT_Reg$lengthofstay,
                                      predicted = Prediction_GBT_Reg$lengthofstay_Pred,
                                      model = "GBT")