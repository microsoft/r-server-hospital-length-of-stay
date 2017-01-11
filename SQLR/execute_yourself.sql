-- Script to execute yourself the SQL Stored Procedures instead of using PowerShell. 

-- Pre-requisites: 
-- 1) The data should be already loaded with PowerShell (run Load_Data.ps1 completely, or step 0 of Length_Of_Stay.ps1). 
-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3 and run "Execute". 
-- 3) You should connect to the database in the SQL Server of the DSVM with:
-- - Server Name: localhost
-- - username: rdemo (if you did not change it)
-- - password: D@tascience (if you did not change it)

-- The default table names have been specified. You can modify them by changing the value of the parameters in what follows.

/* Set the working database to the one where you created the stored procedures */ 
Use Hospital
GO

/* Step 1 */

-- If you want to fill the missing character values with 'missing' and numeric values with '-1': 
exec [dbo].[fill_NA_explicit] @input_output = 'LengthOfStay'

-- If you want to fill the missing categorical values with the mode and numeric values with the mean" 
exec [dbo].[fill_NA_mode_mean] @input_output = 'LengthOfStay'

/* Step 2 */ 
exec [dbo].[feature_engineering]  @input = 'LengthOfStay', @output = 'LoS'

/* Step 3 */ 

-- Split into train and test
exec [dbo].[splitting] @splitting_percent = 70, @input = 'LoS',  @output = 'Train_Id'  

-- Train the models
exec [dbo].[train_model] @modelName = 'RF',
                         @connectionString ="Driver=SQL Server;Server=localhost;Database=Hospital;UID=rdemo;PWD=D@tascience",
						 @dataset_name = 'LoS',
						 @training_name = 'Train_Id'

exec [dbo].[train_model] @modelName = 'GBT',
                         @connectionString ="Driver=SQL Server;Server=localhost;Database=Hospital;UID=rdemo;PWD=D@tascience",
						 @dataset_name = 'LoS',
						 @training_name = 'Train_Id'

-- Test and Evaluate the models. 
exec [dbo].[test_evaluate_models] @modelrf  = 'RF',
								  @modelbtree  = 'GBT',
                                  @connectionString ="Driver=SQL Server;Server=localhost;Database=Hospital;UID=rdemo;PWD=D@tascience", 
								  @metrics_table_name = 'Metrics',
								  @dataset_name = 'LoS', 
								  @training_name = 'Train_Id'

		
		
