##########################################################################################################################################
## This R script will do the following:
## 1. Split LoS into a Training LoS_Train, and a Testing set LoS_Test.  
## 2. Train regression model Random Forest (rxDForest implementation) on LoS_Train, and save it to SQL. 
## 3. Score the Random Forest on LoS_Test.

## Input : Data set LoS
## Output: Regression Random forest saved to SQL. 

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load revolution R library and Microsoft ML packages. 
library(RevoScaleR)
library("MicrosoftML")

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the compute context to local. It will be changed to sql for modelling.
rxSetComputeContext(local)

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

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
variables_to_remove <- c("eid", "vdate", "discharged", "facid")
traning_variables <- variables_all[!(variables_all %in% c("lengthofstay", variables_to_remove))]
formula <- as.formula(paste("lengthofstay ~", paste(traning_variables, collapse = "+")))


##########################################################################################################################################

##	Random Forest (rxDForest implementation) Training and saving the model to SQL

##########################################################################################################################################

# Set the compute context to SQL for model training. 
rxSetComputeContext(sql)

# Train the Random Forest.
forest_model <- rxDForest(formula = formula,
                          data = LoS_Train,
                          nTree = 40,
                          minSplit = 10,
                          minBucket = 5,
                          cp = 0.00005,
                          seed = 5)

# Save the Random Forest in SQL. The compute context is set to local in order to export the model. 
rxSetComputeContext(local)
saveRDS(forest_model, file = "forest_model.rds")
forest_model_raw <- readBin("forest_model.rds", "raw", n = file.size("forest_model.rds"))
forest_model_char <- as.character(forest_model_raw)
forest_model_sql <- RxSqlServerData(table = "Models", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = forest_model_char ), outFile = forest_model_sql, overwrite = TRUE)

##########################################################################################################################################

##	Boosted Trees (rxFastTrees implementation) Training and saving the model to SQL

##########################################################################################################################################

# Set the compute context to SQL for model training. 
rxSetComputeContext(sql)

# Train the Boosted Trees model.
boosted_model <- rxFastTrees(formula = formula,
                             data = LoS_Train,
                             type = c("regression"),
                             numTrees = 40,
                             learningRate = 0.2,
                             splitFraction = 5/24,
                             featureFraction = 1,
                             minSplit = 10)	

# Save the Boosted Trees in SQL. The compute context is set to Local in order to export the model. 
rxSetComputeContext(local)
saveRDS(boosted_model, file = "boosted_model.rds")
boosted_model_raw <- readBin("boosted_model.rds", "raw", n = file.size("boosted_model.rds"))
boosted_model_char <- as.character(boosted_model_raw)
boosted_model_sql <- RxSqlServerData(table = "Models", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = boosted_model_char ), outFile = boosted_model_sql, overwrite = TRUE)


##########################################################################################################################################

## Regression model evaluation metrics

##########################################################################################################################################

# Write a function that computes regression performance metrics. 
evaluate_model <- function(observed, predicted, model) {
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
  metrics <- c("Mean Absolute Error" = mae,
               "Root Mean Squared Error" = rmse,
               "Relative Absolute Error" = rae,
               "Relative Squared Error" = rse,
               "Coefficient of Determination" = rsq)
  print(model)
  print(metrics)
  print("Summary statistics of the absolute error")
  print(summary(abs(observed-predicted)))
  return(metrics)
}

##########################################################################################################################################

##	Random Forest Scoring

##########################################################################################################################################

# Make Predictions, then import them into R. 
forest_prediction_sql <- RxSqlServerData(table = "Forest_Prediction", stringsAsFactors = T, connectionString = connection_string)

rxPredict(modelObject = forest_model,
          data = LoS_Test, 
          outData = forest_prediction_sql,
          overwrite = T, 
          type = "response",
          extraVarsToWrite = c("lengthofstay", "eid"))

# Compute the performance metrics of the model.
forest_prediction <- rxImport(inData = forest_prediction_sql)

forest_metrics <- evaluate_model(observed = forest_prediction$lengthofstay,
                                 predicted = forest_prediction$lengthofstay_Pred,
                                 model = "RF")

##########################################################################################################################################

##	Boosted Trees Scoring

##########################################################################################################################################

# Make Predictions, then import them into R. 
boosted_prediction_sql <- RxSqlServerData(table = "Boosted_Prediction", stringsAsFactors = T, connectionString = connection_string)

rxPredict(modelObject = boosted_model,
          data = LoS_Test,
          outData = boosted_prediction_sql,
          extraVarsToWrite = c("lengthofstay", "eid"),
          overwrite = TRUE)

# Compute the performance metrics of the model.
boosted_prediction <- rxImport(boosted_prediction_sql)

boosted_metrics <- evaluate_model(observed = boosted_prediction$lengthofstay,
                                  predicted = boosted_prediction$Score,
                                  model = "GBT")

##########################################################################################################################################

##	Table for PowerBI

##########################################################################################################################################

# We create the variables discharged_pred_forest and discharged_pred_boosted, holding the predicted dates for discharge.

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists LoS_Predictions;", sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
  "SELECT LoS.eid, CONVERT(DATE, vdate, 110) as vdate, rcount, gender, dialysisrenalendstage, asthma,
          irondef, pneum, substancedependence, psychologicaldisordermajor, depress, psychother, 
          fibrosisandother, malnutrition, hemo, hematocritic, neutrophils, sodium,  glucose, 
          bloodureanitro, creatinine, bmi, pulse, respiration, number_of_issues, secondarydiagnosisnonicd9, 
          CONVERT(DATE, discharged, 110) as discharged, facid, LoS.lengthofstay, 
          CONVERT(DATE, CONVERT(DATETIME, vdate, 110) + CAST(ROUND(lengthofstay_pred, 0) as int), 110) as discharged_pred_forest,
          CONVERT(DATE, CONVERT(DATETIME, vdate, 110) + CAST(ROUND(Score, 0) as int), 110) as discharged_pred_boosted
  INTO LoS_Predictions
  FROM Forest_Prediction JOIN LoS ON LoS.eid = Forest_Prediction.eid
  JOIN Boosted_Prediction ON LoS.eid = Boosted_Prediction.eid;"
  ,sep = ""))
