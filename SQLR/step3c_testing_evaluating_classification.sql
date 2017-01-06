/****** Stored Procedure to test and evaluate the model trained in step 3-b) ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[test_evaluate_model_class]
GO

CREATE PROCEDURE [test_evaluate_model_class]  @connectionString varchar(300),
					      @metrics_table_name varchar(max) = 'Metrics_Class',
					      @dataset_name varchar(max) = 'LoS', 
					      @training_name varchar(max) = 'Train_Id'
AS 
BEGIN

/* 	Test the models on CM_AD_Test.  */
	DECLARE @model_rf varbinary(max) = (select model from Models_Class where model_name = 'RF');
	EXECUTE sp_execute_external_script @language = N'R',
     					   @script = N' 
##########################################################################################################################################
##	Specify the types of the features before the testing
##########################################################################################################################################
# Get the variables names, types and levels for factors.
LoS <- RxSqlServerData(table = dataset_name, connectionString = connection_string, stringsAsFactors = T)
column_info <- rxCreateColInfo(LoS)

# Reorder the factors for clarity during evaluation.
column_info$lengthofstay_bucket$levels <- c("1","2","3","4")

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
## Random forest scoring
##########################################################################################################################################
# Prediction on the testing set.
forest_model <- unserialize(forest_model)
forest_prediction  <-  RxSqlServerData(table = "Forest_Prediction_Class", connectionString = connection_string, stringsAsFactors = T,
				       colInfo = column_info)
rxPredict(modelObject = forest_model,
	  data = LoS_Test,
          outData = forest_prediction, 
	  type = "prob",
          extraVarsToWrite = c("lengthofstay_bucket", "eid"),
          overwrite = TRUE)

# Importing the predictions to evaluate the metrics. 
forest_prediction <- rxImport(forest_prediction)
forest_metrics <- evaluate_model(observed = factor(forest_prediction$lengthofstay_bucket, levels = c("1","2","3","4")),
                                 predicted = factor(forest_prediction$lengthofstay_bucket_Pred, levels = c("1","2","3","4")),
				 model = "RF")

##########################################################################################################################################
## Combine metrics and write to SQL. Compute Context is kept to Local to export data. 
##########################################################################################################################################
metrics_df <- rbind(forest_metrics)
metrics_df <- as.data.frame(metrics_df)
rownames(metrics_df) <- NULL
Algorithms <- c("Random Forest")
metrics_df <- cbind(Algorithms, metrics_df)
metrics_table <- RxSqlServerData(table = metrics_table_name, connectionString = connection_string)
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
