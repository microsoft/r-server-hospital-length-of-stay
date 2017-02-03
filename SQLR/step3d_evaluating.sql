-- Stored Procedure to evaluate the models tested.

-- @modelName: specify 'RF' to use the Random Forest,  or 'GBT' for Boosted Trees.
-- @predictions_table : name of the table that holds the predictions (output of scoring).

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[evaluate]
GO

CREATE PROCEDURE [evaluate] @model_name varchar(20),
							@predictions_table varchar(max)


AS 
BEGIN
	-- Create an empty table to be filled with the Metrics.
	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Metrics' AND xtype = 'U')
	CREATE TABLE [dbo].[Metrics](
		[model_name] [varchar](30) NOT NULL,
		[mean_absolute_error] [float] NULL,
		[root_mean_squared_error] [float] NULL,
		[relative_absolute_error] [float] NULL,
		[relative_squared_error] [float] NULL,
		[coefficient_of_determination] [float] NULL
		)

	-- Import the Predictions Table as an input to the R code, and get the current database name. 
	DECLARE @inquery nvarchar(max) = N' SELECT * FROM ' + @predictions_table  
	DECLARE @database_name varchar(max) = db_name();
	INSERT INTO Metrics 
	EXECUTE sp_execute_external_script @language = N'R',
     					   @script = N' 

##########################################################################################################################################
##	Define the connection string
##########################################################################################################################################
connection_string <- paste("Driver=SQL Server;Server=localhost;Database=", database_name, ";Trusted_Connection=true;", sep="")

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
  metrics <- c(model, mae, rmse, rae, rse, rsq)
  print(model)
  print("Summary statistics of the absolute error")
  print(summary(abs(observed-predicted)))
  return(metrics)
 }

##########################################################################################################################################
## Random forest Evaluation 
##########################################################################################################################################
if(model_name == "RF"){
	OutputDataSet <- data.frame(rbind(evaluate_model(observed = InputDataSet$lengthofstay,
							        predicted = InputDataSet$lengthofstay_Pred,
							        model = "Random Forest (rxDForest)")))
 }
##########################################################################################################################################
## Boosted tree Evaluation.
##########################################################################################################################################
if(model_name == "GBT"){
	library("MicrosoftML")
	OutputDataSet <- data.frame(rbind(evaluate_model(observed = InputDataSet$lengthofstay,
							        predicted = InputDataSet$Score,
							        model = "Boosted Trees (rxFastTrees)")))
}'
, @input_data_1 = @inquery
, @params = N' @model_name varchar(20), @predictions_table varchar(max), @database_name varchar(max)'	  
, @model_name = @model_name 
, @predictions_table = @predictions_table 
, @database_name = @database_name
;
END
GO

