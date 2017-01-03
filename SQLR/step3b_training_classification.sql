/****** Stored Procedure to train classification RF model. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[train_model_class];
GO

CREATE PROCEDURE [train_model_class] @connectionString varchar(300),
				     @dataset_name varchar(max) = 'LoS', 
				     @training_name varchar(max) = 'Train_Id'
AS 
BEGIN

	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models_Class' AND xtype='U')
		CREATE TABLE Models_Class
		(
		model_name varchar(30) not null default('default model') primary key,
		model varbinary(max) not null
		)

/* 	Train the model on CM_AD_Train.  */	
	DELETE FROM Models_Class WHERE model_name = 'RF';
	INSERT INTO Models_Class (model)
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

# Reorder the factors for clarity during evaluation.
column_info$lengthofstay_bucket$levels <- c("1","2","3","4")

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
# Write the formula after removing variables not used in the modeling.
variables_all <- rxGetVarNames(LoS_Train)
variables_to_remove <- c("eid", "vdate", "discharged", "lengthofstay", "facid")
traning_variables <- variables_all[!(variables_all %in% c("lengthofstay_bucket", variables_to_remove))]
formula <- as.formula(paste("lengthofstay_bucket ~", paste(traning_variables, collapse = "+")))

# In order to deal with class imbalance, we do a stratification sampling.
# We take all observations in the smallest class  and we sample from the three other classes to have the same number.
summary <- rxSummary(formula = ~ lengthofstay_bucket, LoS_Train)$categorical[[1]]
strat_sampling <- function(){
  min <- which.min(summary[,2])
  return(c(summary[min,2]/summary[1,2], summary[min,2]/summary[2,2], summary[min,2]/summary[3,2],
           summary[min,2]/summary[4,2]))
}
sampling_rate <- strat_sampling()

##########################################################################################################################################
## Training model based on model selection
##########################################################################################################################################
# Train the Random Forest.
model <- rxDForest(formula = formula,
		   data = LoS_Train,
                   nTree = 40,
                   minSplit = 10,
                   minBucket = 5,
                   cp = 0.00005,
                   seed = 5, 
                   strata = c("lengthofstay_bucket"),
                   sampRate = sampling_rate)
					   				       
OutputDataSet <- data.frame(payload = as.raw(serialize(model, connection=NULL)))'
, @params = N'@connection_string varchar(300), @dataset_name varchar(max) , @training_name varchar(max) '
, @connection_string = @connectionString 
, @dataset_name =  @dataset_name
, @training_name = @training_name 

UPDATE Models_Class set model_name = 'RF'
WHERE model_name = 'default model'

;
END
GO
