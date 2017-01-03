/****** Stored Procedure to train models. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[train_model_reg];
GO

CREATE PROCEDURE [train_model_reg]   @connectionString varchar(300),
				     @dataset_name varchar(max) = 'LoS',
				     @training_name varchar(max) = 'Train_Id'
AS 
BEGIN

	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models_Reg' AND xtype='U')
		CREATE TABLE Models_Reg
		(
		model_name varchar(30) not null default('default model') primary key,
		model varbinary(max) not null
		)

/* 	Train the model on CM_AD_Train.  */	
	DELETE FROM Models_Reg WHERE model_name = 'RF';
	INSERT INTO Models_Reg (model)
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
variables_to_remove <- c("eid", "vdate", "discharged", "lengthofstay_bucket", "facid")
traning_variables <- variables_all[!(variables_all %in% c("lengthofstay", variables_to_remove))]
formula <- as.formula(paste("lengthofstay ~", paste(traning_variables, collapse = "+")))

##########################################################################################################################################
## Training model based on model selection
##########################################################################################################################################
# Train the Random Forest.
model <- rxDForest(formula = formula,
	 	   data = LoS_Train,
		   nTree = 40,
 		   minBucket = 5,
		   minSplit = 10,
		   cp = 0.00005,
		   seed = 5)
					   				       
OutputDataSet <- data.frame(payload = as.raw(serialize(model, connection=NULL)))'
, @params = N'@connection_string varchar(300), @dataset_name varchar(max) , @training_name varchar(max) '
, @connection_string = @connectionString 
, @dataset_name =  @dataset_name
, @training_name = @training_name 

UPDATE Models_Reg set model_name = 'RF'
WHERE model_name = 'default model'

;
END
GO

