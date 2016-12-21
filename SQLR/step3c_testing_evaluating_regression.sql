/****** Stored Procedure to test and evaluate the models trained in step 3-b) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[test_evaluate_models_reg]
GO

CREATE PROCEDURE [test_evaluate_models_reg] @modelrf varchar(20),
											  @modelbtree varchar(20),
		                                      @connectionString varchar(300), 
					                          @metrics_table_name varchar(max) = 'Metrics_Reg',
					                          @dataset_name varchar(max) = 'LoS', 
					                          @training_name varchar(max) = 'Train_Id'
AS 
BEGIN

/*  Make sure that the target variable will be treated as a numeric value. */
	DECLARE @sql0 nvarchar(max);
	SELECT @sql0 = N'
	ALTER TABLE ' + @dataset_name + ' ALTER COLUMN lengthofstay int ' ;
	EXEC sp_executesql @sql0;

/* 	Test the models on CM_AD_Test.  */
	DECLARE @model_rf varbinary(max) = (select model from Models_Reg where model_name = @modelrf);
	DECLARE @model_btree varbinary(max) = (select model from Models_Reg where model_name = @modelbtree);
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
## Boosted tree scoring
##########################################################################################################################################
# Prediction on the testing set.
boosted_model <- unserialize(boosted_model)
boosted_prediction <-  RxSqlServerData(table = "Boosted_Prediction_Reg", connectionString = connection_string, stringsAsFactors = T,
				       colInfo = column_info)
rxPredict(modelObject = boosted_model,
          data = LoS_Test,
		  outData = boosted_prediction, 
          type = "response",
		  extraVarsToWrite = c("lengthofstay"),
          overwrite = TRUE)

# Importing the predictions to evaluate the metrics.
boosted_prediction <- rxImport(boosted_prediction)
boosted_metrics <- evaluate_model(observed = boosted_prediction$lengthofstay, 
                                  predicted = boosted_prediction$lengthofstay_Pred, 
								  model = "GBT")

##########################################################################################################################################
## Combine metrics and write to SQL. Compute Context is kept to Local to export data. 
##########################################################################################################################################
metrics_df <- rbind(forest_metrics, boosted_metrics)
metrics_df <- as.data.frame(metrics_df)
rownames(metrics_df) <- NULL
Algorithms <- c("Random Forest",
                "Boosted Decision Tree")
metrics_df <- cbind(Algorithms, metrics_df)

metrics_table <- RxSqlServerData(table = metrics_table_name,
                                 connectionString = connection_string)
rxDataStep(inData = metrics_df,
           outFile = metrics_table,
           overwrite = TRUE)	 		   	   	   
	   '
, @params = N'@forest_model varbinary(max), @boosted_model varbinary(max), @connection_string varchar(300),
			  @metrics_table_name varchar(max), @dataset_name varchar(max), @training_name varchar(max)'	  
, @forest_model = @model_rf
, @boosted_model = @model_btree
, @connection_string = @connectionString
, @metrics_table_name = @metrics_table_name 
, @dataset_name =  @dataset_name
, @training_name = @training_name

;
END
GO

