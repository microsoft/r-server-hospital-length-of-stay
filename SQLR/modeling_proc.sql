-- Stored Procedure for the Modeling/Development pipeline. 
-- 1) The data should be already loaded with PowerShell into LengthOfStay.
-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3 and run "Execute". 
-- 3) You should connect to the database in the SQL Server of the DSVM with:
-- - Server Name: localhost
-- - username: rdemo (if you did not change it)
-- - password: D@tascience (if you did not change it)


-- Set the working database to the one where you created the stored procedures.
Use Hospital
GO

-- @input: specify the name of the table holding the raw data set for Modeling/Development. 

DROP PROCEDURE IF EXISTS [dbo].[dev_lengthofstay]
GO

CREATE PROCEDURE [dbo].[dev_lengthofstay]  @input varchar(max) = 'LengthOfStay'							  
AS
BEGIN

-- Step 1: 
-- Compute the Statistics of the input table to be used for Production. 
	exec [dbo].[compute_stats]  @input = @input

-- Replace the missing values with the mode and the mean. 
	exec [dbo].[fill_NA_mode_mean]  @input = @input, @output = 'LoS0'

-- Step 2: 
-- Feature Engineering. 
    exec [dbo].[feature_engineering]  @input = 'LoS0', @output = 'LoS', @is_production = 0

-- Getting column information. 
	exec [dbo].[get_column_info] @input = 'LoS'

-- Step 3a: Splitting into a training and testing set.
    exec [dbo].[splitting]  @splitting_percent = 70, @input = 'LoS' 

-- Step 3b: Training the two models (rxDForest and rxFastTrees) on the training set.
    exec [dbo].[train_model]   @modelName = 'RF', @dataset_name = 'LoS'
	exec [dbo].[train_model]   @modelName = 'GBT', @dataset_name = 'LoS'

-- Step 3c: Scoring the models on the test set.
	DECLARE @query_string nvarchar(max)
	SET @query_string ='
	SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)' 

	exec [dbo].[score] @model_name = 'RF', @inquery = @query_string, @output = 'Forest_Prediction'  
	exec [dbo].[score] @model_name = 'GBT', @inquery = @query_string, @output = 'Boosted_Prediction'  

-- Step 3d: Evaluating the models on the test set. 
	exec [dbo].[evaluate] @model_name = 'RF', @predictions_table = 'Forest_Prediction'
	exec [dbo].[evaluate] @model_name = 'GBT', @predictions_table = 'Boosted_Prediction'

END
GO
;

