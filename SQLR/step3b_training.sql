/****** Stored Procedure to train a Random Forest (rxDForest implementation) or Boosted Trees (rxFastTrees implementation). ******/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[train_model];
GO
-- For Random Forest, specify 'RF' for model name. For Boosted Trees, specify 'GBT'. 
CREATE PROCEDURE [train_model]   @modelName varchar(20),
							     @connectionString varchar(300),
							     @dataset_name varchar(max) = 'LoS',
							     @training_name varchar(max) = 'Train_Id'
AS 
BEGIN

	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models' AND xtype='U')
		CREATE TABLE Models
		(
		model_name varchar(30) not null default('default model') primary key,
		model varbinary(max) not null
		)

/* 	Train the model on CM_AD_Train.  */	
	DELETE FROM Models WHERE model_name = @modelName;
	INSERT INTO Models (model)
	EXECUTE sp_execute_external_script @language = N'R',
					   @script = N' 

##########################################################################################################################################
##	Set the compute context to SQL for faster training
##########################################################################################################################################
sql <- RxInSqlServer(connectionString = connection_string)
rxSetComputeContext(sql)

##########################################################################################################################################
##	Specify the types of the features before the training
##########################################################################################################################################
# Get the variables names, types and levels for factors.
LoS <- RxSqlServerData(table = dataset_name, connectionString = connection_string, stringsAsFactors = T)
column_info <- rxCreateColInfo(LoS)

##########################################################################################################################################
##	Point to the training set and use the column_info list to specify the types of the features.
##########################################################################################################################################
LoS_Train <- RxSqlServerData(  
  sqlQuery = sprintf( "SELECT *   
                       FROM %s
                       WHERE eid IN (SELECT eid from %s)", dataset_name, training_name),
  connectionString = connection_string, colInfo = column_info)

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
						 splitFraction=5/24,
						 featureFraction=1,
                         minSplit = 10)	
}				   				       
OutputDataSet <- data.frame(payload = as.raw(serialize(model, connection=NULL)))'
, @params = N' @model_name varchar(20), @connection_string varchar(300), @dataset_name varchar(max) , @training_name varchar(max) '
, @model_name = @modelName 
, @connection_string = @connectionString 
, @dataset_name =  @dataset_name
, @training_name = @training_name 

UPDATE Models set model_name = @modelName 
WHERE model_name = 'default model'

;
END
GO

