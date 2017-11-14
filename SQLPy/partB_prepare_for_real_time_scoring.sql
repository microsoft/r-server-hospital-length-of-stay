-- Script to prepare data for and train RTS models

-- Pre-requisites: 
-- 1) The data should be already loaded with PowerShell (run Load_Data.ps1 completely). 
-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3,4 and run "Execute".  Also execute train_real_time_scoring.sql.
-- 3) You should connect to the database in the SQL Server of the DSVM with:
-- - Server Name: localhost
-- - username: XXYOURSQLUSER
-- - password: XXYOURSQLPW

-- The default table names have been specified. You can modify them by changing the value of the parameters in what follows.

/* Set the working database to the one where you created the stored procedures */ 
Use Hospital
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
print 'training';
exec [dbo].[train_model_real_time_scoring] @model_name = 'RF';

exec [dbo].[train_model_real_time_scoring] @model_name = 'GBT';

exec [dbo].[train_model_real_time_scoring] @model_name = 'FT';

exec [dbo].[train_model_real_time_scoring] @model_name = 'NN';