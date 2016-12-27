/****** Stored Procedure to test and evaluate the models trained in step 3-b) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[test_evaluate_model_reg]
GO

CREATE PROCEDURE [test_evaluate_model_reg] @connectionString varchar(300), 
					                       @metrics_table_name varchar(max) = 'Metrics_Reg',
					                       @dataset_name varchar(max) = 'LoS', 
					                       @training_name varchar(max) = 'Train_Id'
AS 
BEGIN

/* 	Test the models on CM_AD_Test.  */
	DECLARE @model_rf varbinary(max) = (select model from Models_Reg where model_name = 'RF');
	EXECUTE sp_execute_external_script @language = N'R',
     					   @script = N' 

##########################################################################################################################################
##	Specify the types of the features before the testing
##########################################################################################################################################
# Get the variables names, types and levels for factors.
LoS <- RxSqlServerData(table = dataset_name, connectionString = connection_string, stringsAsFactors = T)
column_info <- rxCreateColInfo(LoS)

##########################################################################################################################################
##	Point to the testing set and use the column_info list to specify the types of the features.
##########################################################################################################################################
LoS_Test <- RxSqlServerData(  
  sqlQuery = sprintf( "SELECT *   
					   FROM %s
					   WHERE eid NOT IN (SELECT eid from %s)", dataset_name, training_name),
  connectionString = connection_string, colInfo = column_info)

##########################################################################################################################################
## Model evaluation metrics
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
## Random forest scoring
##########################################################################################################################################
# Prediction on the testing set.
forest_model <- unserialize(forest_model)
forest_prediction  <-  RxSqlServerData(table = "Forest_Prediction_Reg", connectionString = connection_string, stringsAsFactors = T,
				       colInfo = column_info)
rxPredict(modelObject = forest_model,
	      data = LoS_Test,
		  outData = forest_prediction, 
		  type = "response",
          extraVarsToWrite = c("lengthofstay"),
		  overwrite = TRUE)

# Importing the predictions to evaluate the metrics. 
forest_prediction <- rxImport(forest_prediction)
forest_metrics <- evaluate_model(observed = forest_prediction$lengthofstay,
                                 predicted = forest_prediction$lengthofstay_Pred,
								 model = "RF")

##########################################################################################################################################
## Combine metrics and write to SQL. Compute Context is kept to Local to export data. 
##########################################################################################################################################
metrics_df <- rbind(forest_metrics)
metrics_df <- as.data.frame(metrics_df)
rownames(metrics_df) <- NULL
Algorithms <- c("Random Forest")
metrics_df <- cbind(Algorithms, metrics_df)

metrics_table <- RxSqlServerData(table = metrics_table_name,
                                 connectionString = connection_string)
rxDataStep(inData = metrics_df,
           outFile = metrics_table,
           overwrite = TRUE)	 		   	   	   
	   '
, @params = N' @forest_model varbinary(max), @connection_string varchar(300), @metrics_table_name varchar(max), @dataset_name varchar(max), @training_name varchar(max)'	  
, @forest_model = @model_rf
, @connection_string = @connectionString
, @metrics_table_name = @metrics_table_name 
, @dataset_name =  @dataset_name
, @training_name = @training_name

;
END
GO

