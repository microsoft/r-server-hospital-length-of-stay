-- Stored Procedure to score a data set on a trained model stored in the Models table. 

-- @modelName: specify 'RF' to use the Random Forest,  or 'GBT' for Boosted Trees.
-- @inquery: select the dataset to be scored (the testing set for Development, or the featurized data set for Production). 
-- @output: name of the table that will hold the predictions. 

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[score]
GO

CREATE PROCEDURE [score] @model_name varchar(20), 
						 @inquery varchar(max),
						 @output varchar(max)

AS 
BEGIN

	--	Get the trained model, the current database name and the column information.
	DECLARE @model varbinary(max) = (select model from [dbo].[Models] where model_name = @model_name);
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	-- Compute the predictions. 
	EXECUTE sp_execute_external_script @language = N'R',
     					               @script = N' 

##########################################################################################################################################
##	Define the connection string
##########################################################################################################################################
connection_string <- paste("Driver=SQL Server;Server=localhost;Database=", database_name, ";Trusted_Connection=true;", sep="")

##########################################################################################################################################
##	Get the column information.
##########################################################################################################################################
column_info <- unserialize(info)

##########################################################################################################################################
## Point to the data set to score and use the column_info list to specify the types of the features.
##########################################################################################################################################
 LoS_Test <- RxSqlServerData(sqlQuery = sprintf("%s", inquery),
							 connectionString = connection_string,
							 colInfo = column_info)

##########################################################################################################################################
## Random forest scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table. 
if(model_name == "RF" & length(model) > 0){
	model <- unserialize(model)

	forest_prediction_sql <- RxSqlServerData(table = output, connectionString = connection_string, stringsAsFactors = T)

	rxPredict(modelObject = model,
			 data = LoS_Test,
			 outData = forest_prediction_sql,
			 type = "response",
			 extraVarsToWrite = c("eid", "lengthofstay"),
			 overwrite = TRUE)
 }
##########################################################################################################################################
## Boosted tree scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if(model_name == "GBT" & length(model) > 0){
	library("MicrosoftML")
	model <- unserialize(model)

	boosted_prediction_sql <- RxSqlServerData(table = output, connectionString = connection_string, stringsAsFactors = T)

	rxPredict(modelObject = model,
			data = LoS_Test,
			outData = boosted_prediction_sql,
			extraVarsToWrite = c("eid", "lengthofstay"),
			overwrite = TRUE)
 }	 		   	   	   
'
, @params = N' @model_name varchar(20), @model varbinary(max), @inquery nvarchar(max), @database_name varchar(max), @info varbinary(max), @output varchar(max)'	  
, @model_name = @model_name
, @model = @model
, @inquery = @inquery
, @database_name = @database_name
, @info = @info
, @output = @output 
;
END
GO

