##########################################################################################################################################
## This R script will do the following:
## 1. Split LoS into a Training LoS_Train, and a Testing set LoS_Test.  
## 2. Train classification models Random Forest (RF) and Gradient Boosting Trees (GBT) on LoS_Train, and save them to SQL. 
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

##	Specify the type of the features before the training. The target variable is converted to factor for regression.

##########################################################################################################################################

## Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("ALTER TABLE LoS ALTER COLUMN lengthofstay char(1);", sep=""))

column_info <- rxCreateColInfo(LoS)

##########################################################################################################################################

##	Split the data set into a training and a testing set 

##########################################################################################################################################

# Randomly split the data into a training set and a testing set, with a splitting % p.
# p % goes to the training set, and the rest goes to the testing set. Default is 70%. 

p <- "70" 

## Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

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
forest_model_class <- rxDForest(formula = formula,
                                data = LoS_Train,
                                nTree = 40,
                                minSplit = 10,
                                minBucket = 5,
                                cp = 0.00005,
                                seed = 5)

# Save the Random Forest in SQL. The compute context is set to Local in order to export the model. 
rxSetComputeContext(local)
saveRDS(forest_model_class, file = "forest_model_class.rds")
forest_model_class_raw <- readBin("forest_model_class.rds", "raw", n = file.size("forest_model_class.rds"))
forest_model_class_char <- as.character(forest_model_class_raw)
forest_model_class_sql <- RxSqlServerData(table = "Forest_Model_Class", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = forest_model_class_char ), outFile = forest_model_class_sql, overwrite = TRUE)

# Set back the compute context to SQL.
rxSetComputeContext(sql)


##########################################################################################################################################

##	Gradient Boosted Trees Training and saving the model to SQL

##########################################################################################################################################

# Train the GBT.
btree_model_class <- rxBTrees(formula = formula,
                              data = LoS_Train,
                              learningRate = 0.05,
                              minSplit = 10,
                              minBucket = 5,
                              cp = 0.0005,
                              nTree = 40,
                              seed = 5,
                              lossFunction = "multinomial")

# Save the GBT in SQL. The Compute Context is set to Local in order to export the model. 
rxSetComputeContext(local)
saveRDS(btree_model_class, file = "btree_model_class.rds")
btree_model_class_raw <- readBin("btree_model_class.rds", "raw", n = file.size("btree_model_class.rds"))
btree_model_class_char <- as.character(btree_model_class_raw)
btree_model_class_sql <- RxSqlServerData(table = "Btree_Model_Class", connectionString = connection_string) 
rxDataStep(inData = data.frame(x = btree_model_class_char ), outFile = btree_model_class_sql, overwrite = TRUE)


##########################################################################################################################################

##	Multi-class classification model evaluation metrics

##########################################################################################################################################

# Write a function that computes multi-class classification metrics. 
evaluate_model_class <- function(observed, predicted, model) {
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
  print(model)
  print(metrics)
  print(confusion)
  return(metrics)
}


##########################################################################################################################################

##	Random Forest Scoring

##########################################################################################################################################

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_RF_Class <- RxSqlServerData(table = "Forest_Prediction_Class", stringsAsFactors = T, connectionString = connection_string)
rxPredict(forest_model_class, data = LoS_Test, outData = Prediction_Table_RF_Class, overwrite = T, type = "prob",
          extraVarsToWrite = c("lengthofstay"))

Prediction_RF_Class <- rxImport(inData = Prediction_Table_RF_Class, stringsAsFactors = T, outFile = NULL)

# Compute the performance metrics of the model.
Metrics_RF_Class <- evaluate_model_class(observed = factor(Prediction_RF_Class$lengthofstay, levels = c("1","2","3","4")),
                                         predicted = factor(Prediction_RF_Class$lengthofstay_Pred, levels = c("1","2","3","4")),
                                         model = "RF")


##########################################################################################################################################

##	Gradient Boosted Trees Scoring 

##########################################################################################################################################

# Make Predictions, then import them into R. The observed Conversion_Flag is kept through the argument extraVarsToWrite.
Prediction_Table_GBT_Class <- RxSqlServerData(table = "Boosted_Prediction_Class", stringsAsFactors = T, connectionString = connection_string)
rxPredict(btree_model_class,data = LoS_Test, outData = Prediction_Table_GBT_Class, overwrite = T, type="prob",
          extraVarsToWrite = c("lengthofstay"))

Prediction_GBT_Class <- rxImport(inData = Prediction_Table_GBT_Class, stringsAsFactors = T, outFile = NULL)

# Compute the performance metrics of the model.
Metrics_GBT_Class <- evaluate_model_class(observed = factor(Prediction_GBT_Class$lengthofstay, levels = c("1","2","3","4")),
                                          predicted = factor(Prediction_GBT_Class$lengthofstay_Pred, levels = c("1","2","3","4")),
                                          model = "GBT")