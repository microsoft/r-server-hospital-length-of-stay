/****** Object:  Table [dbo].[LengthOfStay]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LengthOfStay](
	[eid] [int] NOT NULL,
	[vdate] [date] NULL,
	[rcount] [varchar](2) NULL,
	[gender] [varchar](1) NULL,
	[dialysisrenalendstage] [varchar](1) NULL,
	[asthma] [varchar](1) NULL,
	[irondef] [varchar](1) NULL,
	[pneum] [varchar](1) NULL,
	[substancedependence] [varchar](1) NULL,
	[psychologicaldisordermajor] [varchar](1) NULL,
	[depress] [varchar](1) NULL,
	[psychother] [varchar](1) NULL,
	[fibrosisandother] [varchar](1) NULL,
	[malnutrition] [varchar](1) NULL,
	[hemo] [varchar](1) NULL,
	[hematocrit] [float] NULL,
	[neutrophils] [float] NULL,
	[sodium] [float] NULL,
	[glucose] [float] NULL,
	[bloodureanitro] [float] NULL,
	[creatinine] [float] NULL,
	[bmi] [float] NULL,
	[pulse] [float] NULL,
	[respiration] [float] NULL,
	[secondarydiagnosisnonicd9] [varchar](2) NULL,
	[discharged] [date] NULL,
	[facid] [varchar](1) NULL,
	[lengthofstay] [int] NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[QueryPatient]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[QueryPatient](
	[eid] [int] NOT NULL,
	[vdate] [date] NULL,
	[rcount] [varchar](2) NULL,
	[gender] [varchar](1) NULL,
	[dialysisrenalendstage] [varchar](1) NULL,
	[asthma] [varchar](1) NULL,
	[irondef] [varchar](1) NULL,
	[pneum] [varchar](1) NULL,
	[substancedependence] [varchar](1) NULL,
	[psychologicaldisordermajor] [varchar](1) NULL,
	[depress] [varchar](1) NULL,
	[psychother] [varchar](1) NULL,
	[fibrosisandother] [varchar](1) NULL,
	[malnutrition] [varchar](1) NULL,
	[hemo] [varchar](1) NULL,
	[hematocrit] [float] NULL,
	[neutrophils] [float] NULL,
	[sodium] [float] NULL,
	[glucose] [float] NULL,
	[bloodureanitro] [float] NULL,
	[creatinine] [float] NULL,
	[bmi] [float] NULL,
	[pulse] [float] NULL,
	[respiration] [float] NULL,
	[secondarydiagnosisnonicd9] [varchar](2) NULL,
	[discharged] [date] NULL,
	[facid] [varchar](1) NULL,
	[lengthofstay] [int] NULL
) ON [PRIMARY]
GO

/****** Object:  View [dbo].[LoS0]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

		CREATE VIEW [dbo].[LoS0]
		AS
		SELECT *
	    FROM LengthOfStay
GO
/****** Object:  Table [dbo].[Stats]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Stats](
	[variable_name] [varchar](30) NOT NULL,
	[type] [varchar](30) NOT NULL,
	[mode] [varchar](30) NULL,
	[mean] [float] NULL,
	[std] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[LoS]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

		CREATE VIEW [dbo].[LoS]
		AS
		SELECT eid, vdate, rcount, gender, dialysisrenalendstage, asthma, irondef, pneum, substancedependence, psychologicaldisordermajor, depress,
			   psychother, fibrosisandother, malnutrition, hemo,
		       (hematocrit - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'hematocrit'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'hematocrit') AS hematocrit,
		       (neutrophils - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'neutrophils'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'neutrophils') AS neutrophils,
		       (sodium - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'sodium '))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'sodium ') AS sodium,
		       (glucose - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'glucose'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'glucose') AS glucose,
		       (bloodureanitro - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'bloodureanitro'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'bloodureanitro') AS bloodureanitro,
		       (creatinine - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'creatinine'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'creatinine') AS creatinine,
		       (bmi - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'bmi'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'bmi') AS bmi,
		       (pulse - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'pulse'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'pulse') AS pulse,
		       (respiration - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = 'respiration'))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = 'respiration') AS respiration,
		       CAST((CAST(hemo as int) + CAST(dialysisrenalendstage as int) + CAST(asthma as int) + CAST(irondef as int) + CAST(pneum as int) +
			        CAST(substancedependence as int) + CAST(psychologicaldisordermajor as int) + CAST(depress as int) +
                    CAST(psychother as int) + CAST(fibrosisandother as int) + CAST(malnutrition as int)) as varchar(2)) 
               AS number_of_issues,
			   secondarydiagnosisnonicd9, discharged, facid, lengthofstay
	    FROM LoS0
GO
/****** Object:  Table [dbo].[Boosted_Prediction]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Boosted_Prediction](
	[eid] [int] NULL,
	[lengthofstay] [int] NULL,
	[Score] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ColInfo]    Script Date: 12/15/2017 5:10:15 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ColInfo](
	[info] [varbinary](max) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LengthOfStay_Prod]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LengthOfStay_Prod](
	[eid] [int] NOT NULL,
	[vdate] [datetime] NULL,
	[rcount] [varchar](2) NULL,
	[gender] [varchar](1) NULL,
	[dialysisrenalendstage] [varchar](1) NULL,
	[asthma] [varchar](1) NULL,
	[irondef] [varchar](1) NULL,
	[pneum] [varchar](1) NULL,
	[substancedependence] [varchar](1) NULL,
	[psychologicaldisordermajor] [varchar](1) NULL,
	[depress] [varchar](1) NULL,
	[psychother] [varchar](1) NULL,
	[fibrosisandother] [varchar](1) NULL,
	[malnutrition] [varchar](1) NULL,
	[hemo] [varchar](1) NULL,
	[hematocrit] [float] NULL,
	[neutrophils] [float] NULL,
	[sodium] [float] NULL,
	[glucose] [float] NULL,
	[bloodureanitro] [float] NULL,
	[creatinine] [float] NULL,
	[bmi] [float] NULL,
	[pulse] [float] NULL,
	[respiration] [float] NULL,
	[secondarydiagnosisnonicd9] [varchar](2) NULL,
	[discharged] [datetime] NULL,
	[facid] [varchar](1) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[LoS_Predictions]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoS_Predictions](
	[eid] [int] NOT NULL,
	[vdate] [date] NULL,
	[rcount] [varchar](2) NULL,
	[gender] [varchar](1) NULL,
	[dialysisrenalendstage] [varchar](1) NULL,
	[asthma] [varchar](1) NULL,
	[irondef] [varchar](1) NULL,
	[pneum] [varchar](1) NULL,
	[substancedependence] [varchar](1) NULL,
	[psychologicaldisordermajor] [varchar](1) NULL,
	[depress] [varchar](1) NULL,
	[psychother] [varchar](1) NULL,
	[fibrosisandother] [varchar](1) NULL,
	[malnutrition] [varchar](1) NULL,
	[hemo] [varchar](1) NULL,
	[hematocrit] [float] NULL,
	[neutrophils] [float] NULL,
	[sodium] [float] NULL,
	[glucose] [float] NULL,
	[bloodureanitro] [float] NULL,
	[creatinine] [float] NULL,
	[bmi] [float] NULL,
	[pulse] [float] NULL,
	[respiration] [float] NULL,
	[number_of_issues] [varchar](2) NULL,
	[secondarydiagnosisnonicd9] [varchar](2) NULL,
	[discharged] [date] NULL,
	[facid] [varchar](1) NULL,
	[lengthofstay] [int] NULL,
	[discharged_pred_boosted] [date] NULL,
	[Score] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Metrics]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Metrics](
	[model_name] [varchar](30) NOT NULL,
	[mean_absolute_error] [float] NULL,
	[root_mean_squared_error] [float] NULL,
	[relative_absolute_error] [float] NULL,
	[relative_squared_error] [float] NULL,
	[coefficient_of_determination] [float] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Models]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE TABLE [dbo].[Models](
		model_name varchar(30) not null primary key,
		model varbinary(max) not null,
		native_model varbinary(max) not null
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Train_Id]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Train_Id](
	[eid] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Models] ADD  DEFAULT ('default model') FOR [model_name]
GO
/****** Object:  StoredProcedure [dbo].[compute_stats]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[compute_stats]  @input varchar(max) = 'LengthOfStay'
AS
BEGIN

	-- Create an empty table that will store the Statistics. 
	DROP TABLE if exists [dbo].[Stats]
	CREATE TABLE [dbo].[Stats](
		[variable_name] [varchar](30) NOT NULL,
		[type] [varchar](30) NOT NULL,
		[mode] [varchar](30) NULL, 
		[mean] [float] NULL,
		[std] [float] NULL
	)
	-- Get the names and variable types of the columns to analyze.
		DECLARE @sql nvarchar(max);
		SELECT @sql = N'
		INSERT INTO Stats(variable_name, type)
		SELECT *
		FROM (SELECT COLUMN_NAME as variable_name, DATA_TYPE as type
			  FROM INFORMATION_SCHEMA.COLUMNS
	          WHERE TABLE_NAME = ''' + @input + ''' 
			  AND COLUMN_NAME NOT IN (''eid'', ''lengthofstay'', ''vdate'', ''discharged'')) as t ';
		EXEC sp_executesql @sql;

	-- Loops to compute the Mode for categorical variables.
		DECLARE @name1 NVARCHAR(100)
		DECLARE @getname1 CURSOR

		SET @getname1 = CURSOR FOR
		SELECT variable_name FROM [dbo].[Stats] WHERE type IN('varchar', 'nvarchar', 'int')
	
		OPEN @getname1
		FETCH NEXT
		FROM @getname1 INTO @name1
		WHILE @@FETCH_STATUS = 0
		BEGIN	

			DECLARE @sql1 nvarchar(max);
			SELECT @sql1 = N'
			UPDATE Stats
			SET Stats.mode = T.mode
			FROM (SELECT TOP(1) ' + @name1 + ' as mode, count(*) as cnt
						 FROM ' + @input + ' 
						 GROUP BY ' + @name1 + ' 
						 ORDER BY cnt desc) as T
			WHERE Stats.variable_name =  ''' + @name1 + '''';
			EXEC sp_executesql @sql1;

			FETCH NEXT
		    FROM @getname1 INTO @name1
		END
		CLOSE @getname1
		DEALLOCATE @getname1
		
	-- Loops to compute the Mean and Standard Deviation for continuous variables.
		DECLARE @name2 NVARCHAR(100)
		DECLARE @getname2 CURSOR

		SET @getname2 = CURSOR FOR
		SELECT variable_name FROM [dbo].[Stats] WHERE type IN('float')
	
		OPEN @getname2
		FETCH NEXT
		FROM @getname2 INTO @name2
		WHILE @@FETCH_STATUS = 0
		BEGIN	

			DECLARE @sql2 nvarchar(max);
			SELECT @sql2 = N'
			UPDATE Stats
			SET Stats.mean = T.mean,
				Stats.std = T.std
			FROM (SELECT  AVG(' + @name2 + ') as mean, STDEV(' + @name2 + ') as std
				  FROM ' + @input + ') as T
			WHERE Stats.variable_name =  ''' + @name2 + '''';
			EXEC sp_executesql @sql2;

			FETCH NEXT
		    FROM @getname2 INTO @name2
		END
		CLOSE @getname2
		DEALLOCATE @getname2

END

GO
/****** Object:  StoredProcedure [dbo].[copy_modeling_tables]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE PROCEDURE [dbo].[copy_modeling_tables]  @dev_db varchar(max) = 'Hospital_R'
	AS
	BEGIN
		-- Only copy deployment tables if the production and the deployment databases are different. 
		DECLARE @database_name varchar(max) = db_name() 
		IF(@database_name <> @dev_db )
		BEGIN 

			-- Copy the Stats table into the production database. 
			 DROP TABLE IF EXISTS [dbo].[Stats]
			 DECLARE @sql1 nvarchar(max);
				SELECT @sql1 = N'
				SELECT *
				INTO [dbo].[Stats]
				FROM ['+ @dev_db + '].[dbo].[Stats]';
				EXEC sp_executesql @sql1;

			-- Copy the Models table into the production database. 
			 DROP TABLE IF EXISTS [dbo].[Models]
			 DECLARE @sql2 nvarchar(max);
				SELECT @sql2 = N'
				SELECT *
				INTO [dbo].[Models]
				FROM ['+ @dev_db + '].[dbo].[Models]';
				EXEC sp_executesql @sql2;

			-- Copy the ColInfo table into the production database. 
			 DROP TABLE IF EXISTS [dbo].[ColInfo]
			 DECLARE @sql3 nvarchar(max);
				SELECT @sql3 = N'
				SELECT *
				INTO [dbo].[ColInfo]
				FROM ['+ @dev_db + '].[dbo].[ColInfo]';
				EXEC sp_executesql @sql3;
		END;
	END

GO
/****** Object:  StoredProcedure [dbo].[dev_lengthofstay]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[dev_lengthofstay]  @input varchar(max) = 'LengthOfStay'							  
	AS
	BEGIN


		-- Stored Procedure for the Modeling/Development pipeline. 
		-- 1) The data should be already loaded with PowerShell into LengthOfStay.
		-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3 and run "Execute". 
		-- 3) You should connect to the database in the SQL Server of the DSVM with:
		-- - Server Name: localhost


		-- Set the working database to the one where you created the stored procedures.


	-- @input: specify the name of the table holding the raw data set for Modeling/Development. 

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
/****** Object:  StoredProcedure [dbo].[evaluate]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE PROCEDURE [dbo].[evaluate] @model_name varchar(20),
								@predictions_table varchar(max)


	AS 
	BEGIN
		-- Create an empty table to be filled with the Metrics.
		IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Metrics' AND xtype = 'U')
		CREATE TABLE [dbo].[Metrics](
			[model_name] [varchar](30) NOT NULL,
			[mean_absolute_error] [float] NULL,
			[root_mean_squared_error] [float] NULL,
			[relative_absolute_error] [float] NULL,
			[relative_squared_error] [float] NULL,
			[coefficient_of_determination] [float] NULL
			)

		-- Import the Predictions Table as an input to the R code, and get the current database name. 
		DECLARE @inquery nvarchar(max) = N' SELECT * FROM ' + @predictions_table  
		DECLARE @database_name varchar(max) = db_name(), @server_name varchar(100) = @@serverName
		INSERT INTO Metrics 
		EXECUTE sp_execute_external_script @language = N'R',
     						   @script = N' 

	##########################################################################################################################################
	##	Define the connection string
	##########################################################################################################################################
	connection_string <- paste("Driver=SQL Server;Server=", server_name, ";Database=", database_name, ";Trusted_Connection=true;", sep="")

	##########################################################################################################################################
	## Model evaluation metrics.
	##########################################################################################################################################
	evaluate_model <- function(observed, predicted, model) {
	  mean_observed <- mean(observed)
	  se <- (observed - predicted)^2
	  ae <- abs(observed - predicted)
	  sem <- (observed - mean_observed)^2
	  aem <- abs(observed - mean_observed)
	  mae <- mean(ae)
	  rmse <- sqrt(mean(se))
	  rae <- sum(ae) / sum(aem)
	  rse <- sum(se) / sum(sem)
	  rsq <- 1 - rse
	  metrics <- c(model, mae, rmse, rae, rse, rsq)
	  print(model)
	  print("Summary statistics of the absolute error")
	  print(summary(abs(observed-predicted)))
	  return(metrics)
	 }

	##########################################################################################################################################
	## Random forest Evaluation 
	##########################################################################################################################################
	if(model_name == "RF"){
		OutputDataSet <- data.frame(rbind(evaluate_model(observed = InputDataSet$lengthofstay,
										predicted = InputDataSet$lengthofstay_Pred,
										model = "Random Forest (rxDForest)")))
	 }
	##########################################################################################################################################
	## Boosted tree Evaluation.
	##########################################################################################################################################
	if(model_name == "GBT"){
		library("MicrosoftML")
		OutputDataSet <- data.frame(rbind(evaluate_model(observed = InputDataSet$lengthofstay,
										predicted = InputDataSet$Score,
										model = "Boosted Trees (rxFastTrees)")))
	}'
	, @input_data_1 = @inquery
	, @params = N' @model_name varchar(20), @predictions_table varchar(max), @database_name varchar(max), @server_name varchar(100)'	  
	, @model_name = @model_name 
	, @predictions_table = @predictions_table 
	, @database_name = @database_name
	, @server_name = @server_name
	;
	END

GO
/****** Object:  StoredProcedure [dbo].[ Inital_Run_Once_R]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

  
		CREATE Proc [dbo].[Inital_Run_Once_R]

		AS
 
    --# compute statistics for production and faster NA replacement.
		EXEC compute_stats
  
    --# execute the NA replacement
		EXEC fill_NA_mode_mean 'LengthOfStay', 'LoS0'
  
    --# execute the feature engineering
		EXEC feature_engineering 'LoS0', 'LoS', 0

    --# get the column information
		EXEC get_column_info 'LoS'

    --# execute the procedure
    DECLARE @splitting_percent int = 70
		EXEC splitting @splitting_percent, 'LoS'

	DECLARE @modelName varchar(10) = 'GBT'
    --# execute the training 
		EXEC train_model @modelName, 'LoS'
   
    --# execute the scoring 
		EXEC score @modelName, 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)', 'Boosted_Prediction'

    --# execute the evaluation 
		EXEC evaluate @modelName, 'Boosted_Prediction'

    --#Execute Prediction Results
		EXEC prediction_results

	---#Execute RF Training Model for Native Scoring
		EXEC train_model 'RF', 'LoS'
GO
/****** Object:  StoredProcedure [dbo].[feature_engineering]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[feature_engineering]  @input varchar(max), @output varchar(max), @is_production int
AS
BEGIN 

-- Drop the output table if it has been created in R in the same database. 
    DECLARE @sql0 nvarchar(max);
	SELECT @sql0 = N'
	IF OBJECT_ID (''' + @output + ''', ''U'') IS NOT NULL  
	DROP TABLE ' + @output ;  
	EXEC sp_executesql @sql0

-- Drop the output view if it already exists. 
	DECLARE @sql1 nvarchar(max);
	SELECT @sql1 = N'
	IF OBJECT_ID (''' + @output + ''', ''V'') IS NOT NULL  
	DROP VIEW ' + @output ;  
	EXEC sp_executesql @sql1

-- Create a View with new features:
-- 1- Standardize the health numeric variables by substracting the mean and dividing by the standard deviation. 
-- 2- Create number_of_issues variable corresponding to the total number of preidentified medical conditions. 
-- lengthofstay variable is only selected if it exists (ie. in Modeling pipeline).

	DECLARE @sql2 nvarchar(max);
	SELECT @sql2 = N'
		CREATE VIEW ' + @output + '
		AS
		SELECT eid, vdate, rcount, gender, dialysisrenalendstage, asthma, irondef, pneum, substancedependence, psychologicaldisordermajor, depress,
			   psychother, fibrosisandother, malnutrition, hemo,
		       (hematocrit - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''hematocrit''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''hematocrit'') AS hematocrit,
		       (neutrophils - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''neutrophils''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''neutrophils'') AS neutrophils,
		       (sodium - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''sodium ''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''sodium '') AS sodium,
		       (glucose - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''glucose''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''glucose'') AS glucose,
		       (bloodureanitro - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''bloodureanitro''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''bloodureanitro'') AS bloodureanitro,
		       (creatinine - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''creatinine''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''creatinine'') AS creatinine,
		       (bmi - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''bmi''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''bmi'') AS bmi,
		       (pulse - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''pulse''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''pulse'') AS pulse,
		       (respiration - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''respiration''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''respiration'') AS respiration,
		       CAST((CAST(hemo as int) + CAST(dialysisrenalendstage as int) + CAST(asthma as int) + CAST(irondef as int) + CAST(pneum as int) +
			        CAST(substancedependence as int) + CAST(psychologicaldisordermajor as int) + CAST(depress as int) +
                    CAST(psychother as int) + CAST(fibrosisandother as int) + CAST(malnutrition as int)) as varchar(2)) 
               AS number_of_issues,
			   secondarydiagnosisnonicd9, discharged, facid, '+
			   (CASE WHEN @is_production = 0 THEN 'lengthofstay' else 'NULL as lengthofstay' end) + '
	    FROM ' + @input;
	EXEC sp_executesql @sql2

;
END

GO
/****** Object:  StoredProcedure [dbo].[fill_NA_explicit]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[fill_NA_explicit]  @input varchar(max), @output varchar(max)
AS
BEGIN

    -- Drop the output table if it has been created in R in the same database. 
    DECLARE @sql0 nvarchar(max);
	SELECT @sql0 = N'
	IF OBJECT_ID (''' + @output + ''', ''U'') IS NOT NULL  
	DROP TABLE ' + @output ;  
	EXEC sp_executesql @sql0

	-- Create a View with the raw data. 
	DECLARE @sqlv1 nvarchar(max);
	SELECT @sqlv1 = N'
	IF OBJECT_ID (''' + @output + ''', ''V'') IS NOT NULL  
	DROP VIEW ' + @output ;  
	EXEC sp_executesql @sqlv1

	DECLARE @sqlv2 nvarchar(max);
	SELECT @sqlv2 = N'
		CREATE VIEW ' + @output + '
		AS
		SELECT *
	    FROM ' + @input;
	EXEC sp_executesql @sqlv2

    -- Loops to fill missing values for the character variables with 'missing'. 
	DECLARE @name1 NVARCHAR(100)
	DECLARE @getname1 CURSOR

	SET @getname1 = CURSOR FOR
	SELECT variable_name FROM [dbo].[Stats] WHERE type IN ('varchar', 'nvarchar')

	OPEN @getname1
	FETCH NEXT
	FROM @getname1 INTO @name1
	WHILE @@FETCH_STATUS = 0
	BEGIN	

		-- Check whether the variable contains a missing value. We perform cleaning only for variables containing NULL. 
		DECLARE @missing1 varchar(50)
		DECLARE @sql10 nvarchar(max);
		DECLARE @Parameter10 nvarchar(500);
		SELECT @sql10 = N'
			SELECT @missingOUT1 = missing
			FROM (SELECT count(*) - count(' + @name1 + ') as missing
			      FROM ' + @output + ') as t';
		SET @Parameter10 = N'@missingOUT1 varchar(max) OUTPUT';
		EXEC sp_executesql @sql10, @Parameter10, @missingOUT1=@missing1 OUTPUT;

		IF (@missing1 > 0)
		BEGIN 

			-- Replace character variables with 'missing'. 
				DECLARE @sql11 nvarchar(max)
				SET @sql11 = 
				'UPDATE ' + @output + '
				SET ' + @name1 + ' = ISNULL(' + @name1 + ',''missing'')';
				EXEC sp_executesql @sql11;
		END;
		FETCH NEXT
		FROM @getname1 INTO @name1
	END
	CLOSE @getname1
	DEALLOCATE @getname1

    -- Loops to fill numeric variables with '-1'.  
	DECLARE @name2 NVARCHAR(100)
	DECLARE @getname2 CURSOR

	SET @getname2 = CURSOR FOR
	SELECT variable_name FROM [dbo].[Stats] WHERE type IN ('int', 'float')

	OPEN @getname2
	FETCH NEXT
	FROM @getname2 INTO @name2
	WHILE @@FETCH_STATUS = 0
	BEGIN	

		-- Check whether the variable contains a missing value. We perform cleaning only for variables containing NULL. 
		DECLARE @missing2 varchar(50)
		DECLARE @sql20 nvarchar(max);
		DECLARE @Parameter20 nvarchar(500);
		SELECT @sql20 = N'
			SELECT @missingOUT2 = missing
			FROM (SELECT count(*) - count(' + @name2 + ') as missing
			      FROM ' + @output + ') as t';
		SET @Parameter20 = N'@missingOUT2 varchar(max) OUTPUT';
		EXEC sp_executesql @sql20, @Parameter20, @missingOUT2=@missing2 OUTPUT;

		IF (@missing2 > 0)
		BEGIN 

			-- Replace numeric variables with '-1'. 
				DECLARE @sql21 nvarchar(max)
				SET @sql21 = 
				'UPDATE ' + @output + '
				 SET ' + @name2 + ' = ISNULL(' + @name2 + ', -1)';
				EXEC sp_executesql @sql21;
		END;
		FETCH NEXT
		FROM @getname2 INTO @name2
	END
	CLOSE @getname2
	DEALLOCATE @getname2
END

GO
/****** Object:  StoredProcedure [dbo].[fill_NA_mode_mean]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[fill_NA_mode_mean]  @input varchar(max), @output varchar(max)
AS
BEGIN

    -- Drop the output table if it has been created in R in the same database. 
    DECLARE @sql0 nvarchar(max);
	SELECT @sql0 = N'
	IF OBJECT_ID (''' + @output + ''', ''U'') IS NOT NULL  
	DROP TABLE ' + @output ;  
	EXEC sp_executesql @sql0

	-- Create a View with the raw data. 
	DECLARE @sqlv1 nvarchar(max);
	SELECT @sqlv1 = N'
	IF OBJECT_ID (''' + @output + ''', ''V'') IS NOT NULL  
	DROP VIEW ' + @output ;  
	EXEC sp_executesql @sqlv1

	DECLARE @sqlv2 nvarchar(max);
	SELECT @sqlv2 = N'
		CREATE VIEW ' + @output + '
		AS
		SELECT *
	    FROM ' + @input;
	EXEC sp_executesql @sqlv2

    -- Loops to fill missing values for the categorical variables with the mode. 
	DECLARE @name1 NVARCHAR(100)
	DECLARE @getname1 CURSOR

	SET @getname1 = CURSOR FOR
	SELECT variable_name FROM  [dbo].[Stats] WHERE type IN ('varchar', 'nvarchar', 'int')

	OPEN @getname1
	FETCH NEXT
	FROM @getname1 INTO @name1
	WHILE @@FETCH_STATUS = 0
	BEGIN	

		-- Check whether the variable contains a missing value. We perform cleaning only for variables containing NULL. 
		DECLARE @missing1 varchar(50)
		DECLARE @sql10 nvarchar(max);
		DECLARE @Parameter10 nvarchar(500);
		SELECT @sql10 = N'
			SELECT @missingOUT1 = missing
			FROM (SELECT count(*) - count(' + @name1 + ') as missing
			      FROM ' + @output + ') as t';
		SET @Parameter10 = N'@missingOUT1 varchar(max) OUTPUT';
		EXEC sp_executesql @sql10, @Parameter10, @missingOUT1=@missing1 OUTPUT;

		IF (@missing1 > 0)
		BEGIN 
			-- Replace categorical variables with the mode. 
			DECLARE @sql11 nvarchar(max)
			SET @sql11 = 
			'UPDATE ' + @output + '
			SET ' + @name1 + ' = ISNULL(' + @name1 + ', (SELECT mode FROM [dbo].[Stats] WHERE variable_name = ''' + @name1 + '''))';
			EXEC sp_executesql @sql11;
		END;
		FETCH NEXT
		FROM @getname1 INTO @name1
	END
	CLOSE @getname1
	DEALLOCATE @getname1

    -- Loops to fill continous variables with the mean.  
	DECLARE @name2 NVARCHAR(100)
	DECLARE @getname2 CURSOR

	SET @getname2 = CURSOR FOR
	SELECT variable_name FROM  [dbo].[Stats] WHERE type IN ('float')

	OPEN @getname2
	FETCH NEXT
	FROM @getname2 INTO @name2
	WHILE @@FETCH_STATUS = 0
	BEGIN	

		-- Check whether the variable contains a missing value. We perform cleaning only for variables containing NULL. 
		DECLARE @missing2 varchar(50)
		DECLARE @sql20 nvarchar(max);
		DECLARE @Parameter20 nvarchar(500);
		SELECT @sql20 = N'
			SELECT @missingOUT2 = missing
			FROM (SELECT count(*) - count(' + @name2 + ') as missing
			      FROM ' + @output + ') as t';
		SET @Parameter20 = N'@missingOUT2 varchar(max) OUTPUT';
		EXEC sp_executesql @sql20, @Parameter20, @missingOUT2=@missing2 OUTPUT;

		IF (@missing2 > 0)
		BEGIN 
			-- Replace numeric variables with '-1'. 
			DECLARE @sql21 nvarchar(max)
			SET @sql21 = 
			'UPDATE ' + @output + '
			SET ' + @name2 + ' = ISNULL(' + @name2 + ', (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''' + @name2 + '''))';
			EXEC sp_executesql @sql21;
		END;
		FETCH NEXT
		FROM @getname2 INTO @name2
	END
	CLOSE @getname2
	DEALLOCATE @getname2
END

GO
/****** Object:  StoredProcedure [dbo].[get_column_info]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[get_column_info] @input varchar(max)
AS 
BEGIN
	-- Create an empty table to store the serialized column information. 
	DROP TABLE IF EXISTS [dbo].[ColInfo]
	CREATE TABLE [dbo].[ColInfo](
		[info] [varbinary](max) NOT NULL
		)

	-- Serialize the column information. 
	DECLARE @database_name varchar(max) = db_name(),@server_name varchar(100) = @@serverName
	INSERT INTO ColInfo
	EXECUTE sp_execute_external_script @language = N'R',
     					               @script = N' 

connection_string <- paste("Driver=SQL Server;Server=",server_name, ";Database=", database_name, ";Trusted_Connection=true;", sep="");
LoS <- RxSqlServerData(sqlQuery = sprintf( "SELECT *  FROM [%s]", input),
					   connectionString = connection_string, 
					   stringsAsFactors = T)
OutputDataSet <- data.frame(payload = as.raw(serialize(rxCreateColInfo(LoS), connection=NULL)))
'
, @params = N'@input varchar(max), @database_name varchar(max), @server_name varchar(100)'
, @input = @input
, @database_name = @database_name
, @server_name = @server_name 
;
END

GO
/****** Object:  StoredProcedure [dbo].[prediction_results]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[prediction_results] 
AS 
BEGIN

	DROP TABLE if exists LoS_Predictions
  
	SELECT LoS0.eid, CONVERT(DATE, LoS0.vdate, 110) as vdate, LoS0.rcount, LoS0.gender, LoS0.dialysisrenalendstage, 
		   LoS0.asthma, LoS0.irondef, LoS0.pneum, LoS0.substancedependence,
		   LoS0.psychologicaldisordermajor, LoS0.depress, LoS0.psychother, LoS0.fibrosisandother, 
		   LoS0.malnutrition, LoS0.hemo, LoS0.hematocrit, LoS0.neutrophils, LoS0.sodium, 
	       LoS0.glucose, LoS0.bloodureanitro, LoS0.creatinine, LoS0.bmi, LoS0.pulse, LoS0.respiration, number_of_issues, LoS0.secondarydiagnosisnonicd9, 
           CONVERT(DATE, LoS0.discharged, 110) as discharged, LoS0.facid, LoS.lengthofstay, 
	       CONVERT(DATE, CONVERT(DATETIME, LoS0.vdate, 110) + CAST(ROUND(Score, 0) as int), 110) as discharged_pred_boosted,
		   CAST(ROUND(Score, 0) as int) as Score
     INTO LoS_Predictions
     FROM LoS JOIN Boosted_Prediction ON LoS.eid = Boosted_Prediction.eid JOIN LoS0 ON LoS.eid = LoS0.eid
;
END

GO
/****** Object:  StoredProcedure [dbo].[prod_lengthofstay]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[prod_lengthofstay]  @input varchar(max) = 'LengthOfStay_Prod',  @dev_db varchar(max) = 'Hospital_R'								  
	AS
	BEGIN

		-- Stored Procedure for the Production pipeline. 
		-- Pre-requisites: 
		-- 1) The data should be already loaded with PowerShell into LengthOfStay_Prod.
		-- 2) The stored procedures should be defined. Open the .sql files for steps 1,2,3 and run "Execute". 
		-- 3) You should connect to the database in the SQL Server of the DSVM with:
		-- - Server Name: localhost

		-- Set the working database to the one where you created the stored procedures.

		-- @input: specify the name of the table holding the raw data set for Production.
		-- @dev_db: specify the name of the development database holding the Stats, Colinfo and Models tables.


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
/****** Object:  StoredProcedure [dbo].[score]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[score] @model_name varchar(20), 
						 @inquery varchar(max),
						 @output varchar(max)

AS 
BEGIN

	--	Get the trained model, the current database name and the column information.
	DECLARE @model varbinary(max) = (select model from [dbo].[Models] where model_name = @model_name);
	DECLARE @database_name varchar(max) = db_name(), @server_name varchar(100) = @@serverName;
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	-- Compute the predictions. 
	EXECUTE sp_execute_external_script @language = N'R',
     					               @script = N' 

##########################################################################################################################################
##	Define the connection string
##########################################################################################################################################
connection_string <- paste("Driver=SQL Server;Server=",server_name, ";Database=", database_name, ";Trusted_Connection=true;", sep="");

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
, @params = N' @model_name varchar(20), @model varbinary(max), @inquery nvarchar(max), @database_name varchar(max), @info varbinary(max), @output varchar(max), @server_name varchar(100)'	  
, @model_name = @model_name
, @model = @model
, @inquery = @inquery
, @database_name = @database_name
, @info = @info
, @output = @output
, @server_name = @server_name 
;
END

GO
/****** Object:  StoredProcedure [dbo].[splitting]    Script Date: 12/15/2017 5:10:16 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[splitting]  @splitting_percent int = 70, @input varchar(max) 
AS
BEGIN

  DECLARE @sql nvarchar(max);
  SET @sql = N'
  DROP TABLE IF EXISTS Train_Id
  SELECT eid 
  INTO Train_Id
  FROM ' + @input + ' 
  WHERE ABS(CAST(BINARY_CHECKSUM(eid, NEWID()) as int)) % 100 < ' + Convert(Varchar, @splitting_percent);

  EXEC sp_executesql @sql
;
END

GO
/****** Object:  StoredProcedure [dbo].[train_model]    Script Date: 12/15/2017 10:54:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[train_model]   @modelName varchar(20),
								 @dataset_name varchar(max)
AS 
BEGIN
	DECLARE								 
		@trained_model varbinary(max), 
		@native_model varbinary(max)

	-- Create an empty table to be filled with the trained models.
	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models' AND xtype = 'U')
	CREATE TABLE [dbo].[Models](
		model_name varchar(30) not null primary key,
		model varbinary(max) not null,
		native_model varbinary(max) not null
		)


	-- Get the database name and the column information. 
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	DECLARE @database_name varchar(max) = db_name();


	-- Train the model on the training set.	
	DELETE FROM Models WHERE model_name = @modelName;
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
# Set to local compute context to use rxSerializeModel
local <- RxLocalSeq()
rxSetComputeContext(local)		
native_model <- rxSerializeModel(model, realtimeScoringOnly = TRUE)
trained_model <- as.raw(serialize(model, connection=NULL))'
  				       
, @params = N' @model_name varchar(20), @dataset_name varchar(max), @info varbinary(max), @database_name varchar(max),
   @trained_model varbinary(max) OUTPUT, @native_model varbinary(max) OUTPUT'

, @model_name = @modelName 
, @dataset_name =  @dataset_name
, @info = @info
, @database_name = @database_name
, @trained_model = @trained_model OUTPUT
, @native_model = @native_model OUTPUT;

delete from Models where model_name = @modelName;
insert into Models (model_name, model, native_model) values(@modelName, @trained_model, @native_model);
END

GO

/****** Object:  StoredProcedure [dbo].[do_native_predict]    Script Date: 12/19/2017 4:48:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[do_native_predict]
    @eid int
AS
BEGIN
    DECLARE @nativeModel VARBINARY(MAX)
    DECLARE @start DATETIME
    DECLARE @end DATETIME
    DECLARE @elapsed varchar(max)

    -- Get the native model from the models table
    SET @nativeModel = ( SELECT native_model
    FROM [Models]
    WHERE model_name = 'RF')


    -- Get the patient record from a historical table using the eid
	INSERT INTO [QueryPatient]
    SELECT *
    FROM [LengthOfStay]
    WHERE eid = @eid

--	Step 1: Replace the missing values with the mode and the mean. 
	exec [dbo].[fill_NA_mode_mean] @input = [QueryPatient], @output = 'LoS0_Prod'

-- Step 2: Feature Engineering. 
    exec [dbo].[feature_engineering]  @input = 'LoS0_Prod', @output = 'Los_Prod', @is_production = 1


    SET @start = GETDATE()

    -- Do real time scoring using native PREDICT clause
    SELECT [LengthOfStay_Pred]
    FROM PREDICT (MODEL = @nativeModel, DATA = [LoS_Prod] ) WITH ( LengthOfStay_Pred FLOAT ) p;

    SET @end = GETDATE()

    SET @elapsed = CONVERT(VARCHAR(max),(SELECT DATEDIFF(MICROSECOND,@start,@end)))

    PRINT 'Elapsed Time for 1 row scoring is : ' + @elapsed + ' microseconds.'
	TRUNCATE table QueryPatient 

END

;
