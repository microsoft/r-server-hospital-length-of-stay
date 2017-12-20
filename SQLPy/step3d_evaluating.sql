-- Stored Procedure to evaluate the models tested.

-- @model_name: specify 'RF' to train a Random Forest, 'GBT' for Boosted Trees, 'FT' for Fast Trees, or 'NN' for Neural Network.
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
	EXECUTE sp_execute_external_script @language = N'Python',
     					   @script = N' 
from pandas import DataFrame
import numpy as np
from collections import OrderedDict 

##########################################################################################################################################
## Model evaluation metrics.
##########################################################################################################################################
def evaluate_model(observed, predicted, model):
    mean_observed = np.mean(observed)
    se = (observed - predicted)**2
    ae = abs(observed - predicted)
    sem = (observed - mean_observed)**2
    aem = abs(observed - mean_observed)
    mae = np.mean(ae)
    rmse = np.sqrt(np.mean(se))
    rae = sum(ae) / sum(aem)
    rse = sum(se) / sum(sem)
    rsq = 1 - rse
    metrics = OrderedDict([ ("model_name", [model]),
				("mean_absolute_error", [mae]),
                ("root_mean_squared_error", [rmse]),
                ("relative_absolute_error", [rae]),
                ("relative_squared_error", [rse]),
                ("coefficient_of_determination", [rsq]) ])
    print(metrics)
    return(metrics)

##########################################################################################################################################
## Random forest Evaluation 
##########################################################################################################################################
if model_name == "RF":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["lengthofstay_Pred"], model = model_name))

##########################################################################################################################################
## Boosted tree Evaluation.
##########################################################################################################################################
if model_name == "GBT":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["lengthofstay_Pred"], model = model_name))

##########################################################################################################################################
## Fast Trees Evaluation.
##########################################################################################################################################
if model_name == "FT":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["Score"], model = model_name))

##########################################################################################################################################
## Neural Network Evaluation.
##########################################################################################################################################
if model_name == "NN":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["Score"], model = model_name))
'
, @input_data_1 = @inquery
, @params = N' @model_name varchar(20), @predictions_table varchar(max), @database_name varchar(max)'	  
, @model_name = @model_name 
, @predictions_table = @predictions_table 
, @database_name = @database_name
;
END
GO

