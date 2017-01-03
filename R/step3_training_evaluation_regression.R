##########################################################################################################################################
## This R script will do the following:
## 1. Split LoS into a Training LoS_Train, and a Testing set LoS_Test.  
## 2. Train regression model Random Forest (RF) on LoS_Train, and save it to SQL. 
## 3. Score RF on LoS_Test.

## Input : Data set LoS
## Output: Regression Random forest saved to SQL. 

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
variables_to_remove <- c("eid", "vdate", "discharged", "lengthofstay_bucket", "facid")
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
,
# Save the Random Forest in SQL. The compute context is set to Local in order to export the model. 
rxSetComputeContext(local)
saveRDS(forest_model_reg, file = "forest_model_reg.rds")
forest_model_reg_raw <- readBin("forest_model_reg.rds", "raw", n = file.size("forest_model_reg.rds"))
forest_model_reg_char <- as.character(forest_model_reg_raw)
forest_model_reg_sql <- RxSqlServerData(table = "Forest_Model_Reg", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = forest_model_reg_char ), outFile = forest_model_reg_sql, overwrite = TRUE)


##########################################################################################################################################

## Regression model evaluation metrics

##########################################################################################################################################

# Write a function that computes regression performance metrics. 
evaluate_model_reg <- function(observed, predicted, model) {
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

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_RF_Reg <- RxSqlServerData(table = "Forest_Prediction_Reg", stringsAsFactors = T, connectionString = connection_string)
rxPredict(forest_model_reg, data = LoS_Test, outData = Prediction_Table_RF_Reg, overwrite = T, type = "response",
          extraVarsToWrite = c("lengthofstay", "eid"))

Prediction_RF_Reg<- rxImport(inData = Prediction_Table_RF_Reg, stringsAsFactors = T, outFile = NULL)

# Compute the performance metrics of the model.
Metrics_RF_Reg <- evaluate_model_reg(observed = Prediction_RF_Reg$lengthofstay,
                                    predicted = Prediction_RF_Reg$lengthofstay_Pred,
                                    model = "RF")
