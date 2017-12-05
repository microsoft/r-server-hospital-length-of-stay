-- Script to execute yourself the SQL Stored Procedures instead of using PowerShell. 

-- Pre-requisites: 
-- 1) The data should be already loaded with PowerShell (run Load_Data.ps1 completely). 
-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3,4 and run "Execute". 
-- 3) You should connect to the database in the SQL Server of the DSVM with:
-- - Server Name: localhost
-- - username: XXYOURSQLUSER
-- - password: XXYOURSQLPW

-- The default table names have been specified. You can modify them by changing the value of the parameters in what follows.

/* Set the working database to the one where you created the stored procedures */ 
Use Hospital_Py
GO

/* Step 1: Preprocessing */
exec [dbo].[compute_stats];
exec [dbo].[fill_NA_mode_mean] @input='LengthOfStay', @output = 'LoS0';

/* Step 2: Feature Engineering */ 
exec [dbo].[feature_engineering]  @input = 'LoS0', @output = 'LoS', @is_production = '0';
exec [dbo].[get_column_info] @input = 'LoS';

/* Step 3: Training, Scoring, and Evaluating */ 

-- Split into train and test
exec [dbo].[splitting] @splitting_percent = 70, @input = 'LoS';

-- Train the models
exec [dbo].[train_model] @model_name = 'RF', @dataset_name = 'LoS';

exec [dbo].[train_model] @model_name = 'GBT', @dataset_name = 'LoS';

exec [dbo].[train_model] @model_name = 'FT', @dataset_name = 'LoS';

exec [dbo].[train_model] @model_name = 'NN', @dataset_name = 'LoS';

-- Test and Evaluate the models.
exec [dbo].[score] @model_name = 'RF',
				   @inquery = 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)',
				   @output = 'Forest_Prediction';

exec [dbo].[score] @model_name = 'GBT',
				   @inquery = 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)',
				   @output = 'Boosted_Prediction';

exec [dbo].[score] @model_name = 'FT',
				   @inquery = 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)',
				   @output = 'Fast_Prediction';

exec [dbo].[score] @model_name = 'NN',
				   @inquery = 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)',
				   @output = 'NN_Prediction';

exec [dbo].[evaluate] @model_name  = 'RF',
					  @predictions_table = 'Forest_Prediction';

exec [dbo].[evaluate] @model_name  = 'GBT',
					  @predictions_table = 'Boosted_Prediction';

exec [dbo].[evaluate] @model_name  = 'FT',
					  @predictions_table = 'Fast_Prediction';

exec [dbo].[evaluate] @model_name  = 'NN',
					  @predictions_table = 'NN_Prediction';

exec [dbo].[prediction_results]; --- uses Fast_Prediction, outputs to LoS_Predictions