-- Stored Procedure to train a Random Forest (rxDForest implementation) or Boosted Trees (rxFastTrees implementation).

-- @modelName: specify 'RF' to train a Random Forest,  or 'GBT' for Boosted Trees.
-- @dataset_name: specify the name of the featurized data set. 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[train_model];
GO

CREATE PROCEDURE [train_model]   @modelName varchar(20),
								 @dataset_name varchar(max) 
AS 
BEGIN

	-- Create an empty table to be filled with the trained models.
	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models' AND xtype = 'U')
	CREATE TABLE [dbo].[Models](
		[model_name] [varchar](30) NOT NULL default('default model'),
		[model] [varbinary](max) NOT NULL
		)

	-- Get the database name and the column information. 
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	DECLARE @database_name varchar(max) = db_name();

	-- Train the model on the training set.	
	DELETE FROM Models WHERE model_name = @modelName;
	INSERT INTO Models (model)
	EXECUTE sp_execute_external_script @language = N'R',
									   @script = N' 

##########################################################################################################################################
##	Set the compute context to SQL for faster training
##########################################################################################################################################
# Define the connection string
connection_string <- paste("Driver=SQL Server;Server=localhost;Database=", database_name, ";Trusted_Connection=true;", sep="")

# Set the Compute Context to SQL.
sql <- RxInSqlServer(connectionString = connection_string)
rxSetComputeContext(sql)

##########################################################################################################################################
##	Get the column information.
##########################################################################################################################################
column_info <- unserialize(info)

##########################################################################################################################################
##	Point to the training set and use the column_info list to specify the types of the features.
##########################################################################################################################################
LoS_Train <- RxSqlServerData(  
  sqlQuery = sprintf( "SELECT *   
                       FROM [%s]
                       WHERE eid IN (SELECT eid from Train_Id)", dataset_name),
  connectionString = connection_string, 
  colInfo = column_info)

##########################################################################################################################################
##	Specify the variables to keep for the training 
##########################################################################################################################################
variables_all <- rxGetVarNames(LoS_Train)
# We remove dates and ID variables.
variables_to_remove <- c("eid", "vdate", "discharged", "facid")
traning_variables <- variables_all[!(variables_all %in% c("lengthofstay", variables_to_remove))]
formula <- as.formula(paste("lengthofstay ~", paste(traning_variables, collapse = "+")))

##########################################################################################################################################
## Training model based on model selection
##########################################################################################################################################
# Parameters of both models have been chosen for illustrative purposes, and can be further optimized.

if (model_name == "RF") {
	# Train the Random Forest.
	model <- rxDForest(formula = formula,
	 	           data = LoS_Train,
			       nTree = 40,
 		           minBucket = 5,
		           minSplit = 10,
		           cp = 0.00005,
		           seed = 5)
} else{
	# Train the Gradient Boosted Trees (rxFastTrees implementation).
	library("MicrosoftML")
	model <- rxFastTrees(formula = formula,
			     data = LoS_Train,
			     type=c("regression"),
			     numTrees = 40,
			     learningRate = 0.2,
			     splitFraction = 5/24,
			     featureFraction = 1,
                             minSplit = 10)	
}				   				       
OutputDataSet <- data.frame(payload = as.raw(serialize(model, connection=NULL)))'
, @params = N' @model_name varchar(20), @dataset_name varchar(max), @info varbinary(max), @database_name varchar(max)'
, @model_name = @modelName 
, @dataset_name =  @dataset_name
, @info = @info
, @database_name = @database_name

UPDATE Models set model_name = @modelName 
WHERE model_name = 'default model'

;
END
GO

