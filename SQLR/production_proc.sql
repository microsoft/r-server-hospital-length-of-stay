-- Stored Procedure for the Production pipeline. 
-- Pre-requisites: 
-- 1) The data should be already loaded with PowerShell into LengthOfStay_Prod.
-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3 and run "Execute". 
-- 3) You should connect to the database in the SQL Server of the DSVM with:
-- - Server Name: localhost
-- - username: rdemo (if you did not change it)
-- - password: D@tascience (if you did not change it)


-- Set the working database to the one where you created the stored procedures.
Use Hospital_Prod
GO

-- @input: specify the name of the table holding the raw data set for Production.
-- @dev_db: specify the name of the development database holding the Stats, Colinfo and Models tables.  

DROP PROCEDURE IF EXISTS [dbo].[prod_lengthofstay]
GO

CREATE PROCEDURE [dbo].[prod_lengthofstay]  @input varchar(max) = 'LengthOfStay_Prod',  @dev_db varchar(max) = 'Hospital'								  
AS
BEGIN

-- Step 0: Copy the Stats, Models, and ColInfo tables to the production database (Only used for Production). 
	exec [dbo].[copy_modeling_tables] @dev_db = @dev_db 

-- Step 1: Replace the missing values with the mode and the mean. 
	exec [dbo].[fill_NA_mode_mean] @input = @input, @output = 'LoS0_Prod'

-- Step 2: Feature Engineering. 
    exec [dbo].[feature_engineering]  @input = 'LoS0_Prod', @output = 'LoS_Prod', @is_production = 1

-- Step 3: Scoring.
	DECLARE @query_string_prod nvarchar(max)
	SET @query_string_prod ='
	SELECT * FROM LoS_Prod' 

	exec [dbo].[score] @model_name = 'RF', @inquery = @query_string_prod, @output = 'Forest_Prediction_Prod'
	exec [dbo].[score] @model_name = 'GBT', @inquery = @query_string_prod, @output = 'Boosted_Prediction_Prod'

END
GO
;

