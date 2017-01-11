/****** Stored Procedure to test and evaluate the models trained in step 3-b) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[test_evaluate_models]
GO

CREATE PROCEDURE [test_evaluate_models] @modelrf varchar(20) = 'RF',
										@modelbtree varchar(20) = 'GBT',
										@connectionString varchar(300), 
										@metrics_table_name varchar(max) = 'Metrics',
										@dataset_name varchar(max) = 'LoS', 
										@training_name varchar(max) = 'Train_Id'
AS 
BEGIN

/* 	Test the models on CM_AD_Test.  */
	DECLARE @model_rf varbinary(max) = (select model from Models where model_name = @modelrf);
	DECLARE @model_btree varbinary(max) = (select model from Models where model_name = @modelbtree);
	EXECUTE sp_execute_external_script @language = N'R',
     					   @script = N' 

##########################################################################################################################################
## Specify the types of the features before the testing.
##########################################################################################################################################
# Get the variables names, types and levels for factors.
LoS <- RxSqlServerData(table = dataset_name, connectionString = connection_string, stringsAsFactors = T)
column_info <- rxCreateColInfo(LoS)

##########################################################################################################################################
## Point to the testing set and use the column_info list to specify the types of the features.
##########################################################################################################################################
LoS_Test <- RxSqlServerData(  
  sqlQuery = sprintf( "SELECT *   
		       FROM %s
		       WHERE eid NOT IN (SELECT eid from %s)", dataset_name, training_name),
  connectionString = connection_string, colInfo = column_info)

##########################################################################################################################################
## Model evaluation metrics.
##########################################################################################################################################
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
  metrics <- c("Algorithm" = model,
			    "Mean Absolute Error" = mae,
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
## Empty Metrics Table.
##########################################################################################################################################
metrics <- data.frame(matrix(nrow = 0, ncol = 6))
colnames(metrics) <- c("Algorithm", "Mean Absolute Error", "Root Mean Squared Error", "Relative Absolute Error",
                       "Relative Squared Error", "Coefficient of Determination")

##########################################################################################################################################
## Random forest scoring.
##########################################################################################################################################
# Prediction on the testing set. The prediction results are directly written to a SQL table. 
if(length(forest_model) > 0) {
	forest_model <- unserialize(forest_model)

	forest_prediction_sql <- RxSqlServerData(table = "Forest_Prediction", connectionString = connection_string, stringsAsFactors = T)

	rxPredict(modelObject = forest_model,
			 data = LoS_Test,
			 outData = forest_prediction_sql,
			type = "response",
			extraVarsToWrite = c("lengthofstay", "eid"),
			overwrite = TRUE)

	# Evaluate the model after importing the predictions in-memory.
	forest_prediction <- rxImport(forest_prediction_sql)

	metrics[(nrow(metrics) + 1),] <- evaluate_model(observed = forest_prediction$lengthofstay,
									                predicted = forest_prediction$lengthofstay_Pred,
									                model = "Random Forest (rxDForest)")
 }
##########################################################################################################################################
## Boosted tree scoring.
##########################################################################################################################################
# Prediction on the testing set. The prediction results are directly written to a SQL table.
if(length(boosted_model) > 0) {
	library("MicrosoftML")
	boosted_model <- unserialize(boosted_model)

	boosted_prediction_sql <- RxSqlServerData(table = "Boosted_Prediction", connectionString = connection_string, stringsAsFactors = T)

	rxPredict(modelObject = boosted_model,
			data = LoS_Test,
			outData = boosted_prediction_sql,
			extraVarsToWrite = c("lengthofstay", "eid"),
			overwrite = TRUE)

	# Evaluate the model after importing the predictions in-memory.
	boosted_prediction <- rxImport(boosted_prediction_sql)

	metrics[(nrow(metrics) + 1),] <- evaluate_model(observed = boosted_prediction$lengthofstay,
									                predicted = boosted_prediction$Score,
									                model = "Boosted Trees (rxFastTrees)")
 }

##########################################################################################################################################
## Write metrics to SQL.
##########################################################################################################################################
rownames(metrics) <- NULL

metrics_table <- RxSqlServerData(table = metrics_table_name, connectionString = connection_string)
rxDataStep(inData = metrics,
           outFile = metrics_table,
           overwrite = TRUE)	 		   	   	   
	   '
, @params = N' @forest_model varbinary(max), @boosted_model varbinary(max), @connection_string varchar(300), @metrics_table_name varchar(max), @dataset_name varchar(max), @training_name varchar(max)'	  
, @forest_model = @model_rf
, @boosted_model = @model_btree
, @connection_string = @connectionString
, @metrics_table_name = @metrics_table_name 
, @dataset_name =  @dataset_name
, @training_name = @training_name

;
END
GO

-- We create a full table by adding the predictions to the testing set with discharged_pred: predicted date for discharge given by boosted trees. 
-- This will be used for PowerBI visualizations. 

DROP PROCEDURE IF EXISTS [dbo].[prediction_results]
GO

CREATE PROCEDURE [prediction_results] 
AS 
BEGIN

	DROP TABLE if exists LoS_Predictions
  
	SELECT LoS.eid, CONVERT(DATE, vdate, 110) as vdate, rcount, gender, dialysisrenalendstage, asthma, irondef, pneum, substancedependence,
		   psychologicaldisordermajor, depress, psychother, fibrosisandother, malnutrition, hemo, hematocritic, neutrophils, sodium, 
	       glucose, bloodureanitro, creatinine, bmi, pulse, respiration, number_of_issues, secondarydiagnosisnonicd9, 
           CONVERT(DATE, discharged, 110) as discharged, facid, LoS.lengthofstay, 
	       CONVERT(DATE, CONVERT(DATETIME, vdate, 110) + CAST(ROUND(Score, 0) as int), 110) as discharged_pred_boosted
     INTO LoS_Predictions
     FROM LoS JOIN Boosted_Prediction ON LoS.eid = Boosted_Prediction.eid 
;
END
GO
