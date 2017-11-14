
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

		CREATE VIEW [dbo].[LoS0]
		AS
		SELECT *
	    FROM LoS
GO
/****** Object:  Table [dbo].[Boosted_Prediction]    Script Date: 11/14/2017 7:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Boosted_Prediction](
	[lengthofstay_Pred] [float] NULL,
	[lengthofstay] [float] NULL,
	[eid] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Forest_Prediction]    Script Date: 11/14/2017 7:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Forest_Prediction](
	[lengthofstay_Pred] [float] NULL,
	[lengthofstay] [float] NULL,
	[eid] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[LoS]    Script Date: 11/14/2017 7:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[LoS](
	[eid] [int] NULL,
	[vdate] [nvarchar](255) NULL,
	[rcount] [nvarchar](255) NULL,
	[gender] [nvarchar](255) NULL,
	[dialysisrenalendstage] [nvarchar](255) NULL,
	[asthma] [nvarchar](255) NULL,
	[irondef] [nvarchar](255) NULL,
	[pneum] [nvarchar](255) NULL,
	[substancedependence] [nvarchar](255) NULL,
	[psychologicaldisordermajor] [nvarchar](255) NULL,
	[depress] [nvarchar](255) NULL,
	[psychother] [nvarchar](255) NULL,
	[fibrosisandother] [nvarchar](255) NULL,
	[malnutrition] [nvarchar](255) NULL,
	[hemo] [nvarchar](255) NULL,
	[hematocrit] [float] NULL,
	[neutrophils] [float] NULL,
	[sodium] [float] NULL,
	[glucose] [float] NULL,
	[bloodureanitro] [float] NULL,
	[creatinine] [float] NULL,
	[bmi] [float] NULL,
	[pulse] [float] NULL,
	[respiration] [float] NULL,
	[secondarydiagnosisnonicd9] [nvarchar](255) NULL,
	[discharged] [nvarchar](255) NULL,
	[facid] [nvarchar](255) NULL,
	[lengthofstay] [float] NULL,
	[number_of_issues] [varchar](2) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[NN_Prediction]    Script Date: 11/14/2017 7:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NN_Prediction](
	[eid] [int] NULL,
	[lengthofstay] [float] NULL,
	[Score] [float] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[RTS]    Script Date: 11/14/2017 7:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RTS](
	[id] [nvarchar](255) NULL,
	[value] [varbinary](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  StoredProcedure [dbo].[compute_stats]    Script Date: 11/14/2017 7:38:13 PM ******/
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
/****** Object:  StoredProcedure [dbo].[evaluate]    Script Date: 11/14/2017 7:38:13 PM ******/
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
	DECLARE @database_name varchar(max) = db_name();
	INSERT INTO Metrics 
	EXECUTE sp_execute_external_script @language = N'Python',
     					   @script = N' 
from pandas import DataFrame
import numpy as np
from collections import OrderedDict 

##########################################################################################################################################
## Model evaluation metrics.
##########################################################################################################################################
def evaluate_model(observed, predicted, model):
    mean_observed = np.mean(observed)
    se = (observed - predicted)**2
    ae = abs(observed - predicted)
    sem = (observed - mean_observed)**2
    aem = abs(observed - mean_observed)
    mae = np.mean(ae)
    rmse = np.sqrt(np.mean(se))
    rae = sum(ae) / sum(aem)
    rse = sum(se) / sum(sem)
    rsq = 1 - rse
    metrics = OrderedDict([ ("model_name", [model]),
				("mean_absolute_error", [mae]),
                ("root_mean_squared_error", [rmse]),
                ("relative_absolute_error", [rae]),
                ("relative_squared_error", [rse]),
                ("coefficient_of_determination", [rsq]) ])
    print(metrics)
    return(metrics)

##########################################################################################################################################
## Random forest Evaluation 
##########################################################################################################################################
if model_name == "RF":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["lengthofstay_Pred"], model = model_name))

##########################################################################################################################################
## Boosted tree Evaluation.
##########################################################################################################################################
if model_name == "GBT":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["lengthofstay_Pred"], model = model_name))

##########################################################################################################################################
## Fast Trees Evaluation.
##########################################################################################################################################
if model_name == "FT":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["Score"], model = model_name))

##########################################################################################################################################
## Neural Network Evaluation.
##########################################################################################################################################
if model_name == "NN":
	OutputDataSet = DataFrame.from_dict(evaluate_model(observed = InputDataSet["lengthofstay"], predicted = InputDataSet["Score"], model = model_name))
'
, @input_data_1 = @inquery
, @params = N' @model_name varchar(20), @predictions_table varchar(max), @database_name varchar(max)'	  
, @model_name = @model_name 
, @predictions_table = @predictions_table 
, @database_name = @database_name
;
END

GO
/****** Object:  StoredProcedure [dbo].[feature_engineering]    Script Date: 11/14/2017 7:38:13 PM ******/
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
			   (CASE WHEN @is_production = 0 THEN 'CAST(lengthofstay as float) lengthofstay' else 'NULL as lengthofstay' end) + '
	    FROM ' + @input;
	EXEC sp_executesql @sql2

;
END

GO
/****** Object:  StoredProcedure [dbo].[fill_NA_explicit]    Script Date: 11/14/2017 7:38:13 PM ******/
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
/****** Object:  StoredProcedure [dbo].[fill_NA_mode_mean]    Script Date: 11/14/2017 7:38:13 PM ******/
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
/****** Object:  StoredProcedure [dbo].[get_column_info]    Script Date: 11/14/2017 7:38:13 PM ******/
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
	DECLARE @database_name varchar(max) = db_name()
	INSERT INTO ColInfo
	EXECUTE sp_execute_external_script @language = N'Python',
     					               @script = N' 
from dill import dumps
from pandas import DataFrame

# TODO: replace with rxCreateColInfo once available
col_info = {"irondef": {"type": "factor", "levels":["0", "1"]},
               "psychother": {"type": "factor", "levels":["0", "1"]},
               "pulse": {"type": "numeric"},
               "malnutrition": {"type": "factor", "levels":["0", "1"]},
               "pneum": {"type": "factor", "levels":["0", "1"]},
               "respiration": {"type": "numeric"},
               "eid": {"type": "integer"},
               "hematocrit": {"type": "numeric"},
               "sodium": {"type": "numeric"},
               "psychologicaldisordermajor": {"type": "factor", "levels":["0", "1"]},
               "hemo": {"type": "factor", "levels":["0", "1"]},
               "dialysisrenalendstage": {"type": "factor", "levels":["0", "1"]},
               "discharged": {"type": "factor"},
               "facid": {"type": "factor", "levels":["B", "A", "E", "D", "C"]},
               "rcount": {"type": "factor", "levels":["0", "5+", "1", "4", "2", "3"]},
               "substancedependence": {"type": "factor", "levels":["0", "1"]},
               "number_of_issues": {"type": "factor", "levels":["0", "2", "1", "3", "4", "5", "6", "7", "8", "9"]},
               "bmi": {"type": "numeric"},
               "secondarydiagnosisnonicd9": {"type": "factor", "levels":["4", "1", "2", "3", "0", "7", "6", "10", "8", "5", "9"]},
               "glucose": {"type": "numeric"},
               "vdate": {"type": "factor"},
               "asthma": {"type": "factor", "levels":["0", "1"]},
               "depress": {"type": "factor", "levels":["0", "1"]},
               "gender": {"type": "factor", "levels":["F", "M"]},
               "fibrosisandother": {"type": "factor", "levels":["0", "1"]},
               "lengthofstay": {"type": "numeric"},
               "neutrophils": {"type": "numeric"},
               "bloodureanitro": {"type": "numeric"},
               "creatinine": {"type": "numeric"}}

OutputDataSet = DataFrame({"payload": dumps(col_info)}, index=[0])
'
, @params = N'@input varchar(max), @database_name varchar(max)'
, @input = @input
, @database_name = @database_name 
;
END

GO
/****** Object:  StoredProcedure [dbo].[prediction_results]    Script Date: 11/14/2017 7:38:13 PM ******/
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
		   CAST(ROUND(Score, 0) as int) as lengthofstay_Pred
     INTO LoS_Predictions
     FROM LoS JOIN Fast_Prediction ON LoS.eid = Fast_Prediction.eid JOIN LoS0 ON LoS.eid = LoS0.eid
;
END

GO
/****** Object:  StoredProcedure [dbo].[score]    Script Date: 11/14/2017 7:38:13 PM ******/
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
	DECLARE @database_name varchar(max) = db_name();
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	-- Compute the predictions. 
	EXECUTE sp_execute_external_script @language = N'Python',
     					               @script = N' 
import dill
from revoscalepy import RxSqlServerData, rx_predict, rx_data_step
##########################################################################################################################################
##	Define the connection string
##########################################################################################################################################
connection_string = "Driver=SQL Server;Server=localhost;Database=" + database_name + ";Trusted_Connection=true;"

##########################################################################################################################################
##	Get the column information.
##########################################################################################################################################
column_info = dill.loads(info)

##########################################################################################################################################
## Point to the data set to score and use the column_info list to specify the types of the features.
##########################################################################################################################################
LoS_Test = RxSqlServerData(sql_query = "{}".format(inquery),
							connection_string = connection_string,
							column_info = column_info)

##########################################################################################################################################
## Random forest scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table. 
if model_name == "RF" and len(model) > 0:
	model = dill.loads(model)

	forest_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	rx_predict(model,
			 data = LoS_Test,
			 output_data = forest_prediction_sql,
			 type = "response",
			 extra_vars_to_write = ["lengthofstay", "eid"],
			 overwrite = True)

##########################################################################################################################################
## Boosted tree scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if model_name == "GBT" and len(model) > 0:
	model = dill.loads(model)

	boosted_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	rx_predict(model,
			data = LoS_Test,
			output_data = boosted_prediction_sql,
			extra_vars_to_write = ["lengthofstay", "eid"],
			overwrite = True)
			
##########################################################################################################################################
## Fast tree scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if model_name == "FT" and len(model) > 0:
	from microsoftml import rx_predict as ml_predict
	model = dill.loads(model)

	fast_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	fast_prediction = ml_predict(model,
			data = LoS_Test,
			extra_vars_to_write = ["lengthofstay", "eid"])

	rx_data_step(input_data=fast_prediction, output_file=fast_prediction_sql, overwrite=True)

##########################################################################################################################################
## Neural network scoring.
##########################################################################################################################################
# The prediction results are directly written to a SQL table.
if model_name == "NN" and len(model) > 0:
	from microsoftml import rx_predict as ml_predict
	model = dill.loads(model)

	NN_prediction_sql = RxSqlServerData(table = output, connection_string = connection_string, strings_as_factors = True)

	NN_prediction = ml_predict(model,
			data = LoS_Test,
			extra_vars_to_write = ["lengthofstay", "eid"])

	rx_data_step(input_data=NN_prediction, output_file=NN_prediction_sql, overwrite=True)  
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
/****** Object:  StoredProcedure [dbo].[splitting]    Script Date: 11/14/2017 7:38:13 PM ******/
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
/****** Object:  StoredProcedure [dbo].[train_model]    Script Date: 11/14/2017 7:38:13 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[train_model]   @model_name varchar(20),
								 @dataset_name varchar(max) 
AS 
BEGIN
	-- Create an empty table to be filled with the trained models.
	IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'Models' AND xtype = 'U')
	CREATE TABLE [dbo].[Models](
		[model_name] [varchar](30) NOT NULL default('default model'),
		[model] [varbinary](max) NOT NULL
		)

	-- Get the database name and the column information. 
	DECLARE @info varbinary(max) = (select * from [dbo].[ColInfo]);
	DECLARE @database_name varchar(max) = db_name();

	-- Train the model on the training set.	
	DELETE FROM Models WHERE model_name = @model_name;
	INSERT INTO Models (model)
	EXECUTE sp_execute_external_script @language = N'Python',
									   @script = N' 
import dill
from numpy import sqrt
from pandas import DataFrame
from revoscalepy import RxInSqlServer, rx_set_compute_context, RxSqlServerData, rx_dforest, rx_btrees
from microsoftml import rx_fast_trees, rx_neural_network, adadelta_optimizer
##########################################################################################################################################
##	Set the compute context to SQL for faster training
##########################################################################################################################################
# Define the connection string
connection_string = "Driver=SQL Server;Server=localhost;Database=" + database_name + ";Trusted_Connection=true;"

# Set the Compute Context to SQL.
sql = RxInSqlServer(connection_string = connection_string)
rx_set_compute_context(sql)

##########################################################################################################################################
##	Get the column information.
##########################################################################################################################################
column_info = dill.loads(info)

##########################################################################################################################################
##	Point to the training set and use the column_info list to specify the types of the features.
##########################################################################################################################################
variables_all = [var for var in column_info]
variables_to_remove = ["eid", "vdate", "discharged", "facid"]
training_variables = [x for x in variables_all if x not in variables_to_remove]
LoS_Train = RxSqlServerData(sql_query = "SELECT eid, {} FROM LoS WHERE eid IN (SELECT eid from Train_Id)".format(", ".join(training_variables)),
                            connection_string = connection_string,
                            column_info = column_info)

##########################################################################################################################################
##	Specify the variables to keep for the training 
##########################################################################################################################################
variables_to_remove = ["eid", "vdate", "discharged", "facid", "lengthofstay"]
training_variables = [x for x in variables_all if x not in variables_to_remove]
formula = "lengthofstay ~ " + " + ".join(training_variables)

##########################################################################################################################################
## Training model based on model selection
##########################################################################################################################################
# Parameters of both models have been chosen for illustrative purposes, and can be further optimized.

if model_name == "RF":
	# Train the Random Forest.
	model = rx_dforest(formula=formula,
						data=LoS_Train,
						n_tree=40,
						cp=0.00005,
						min_split=int(sqrt(70000)),
						max_num_bins=int(sqrt(70000)),
						seed=5)
elif model_name == "GBT":
	# Train the Gradient Boosted Trees (rx_btrees implementation).
	model = rx_btrees(formula=formula,
						data=LoS_Train,
						n_tree=40,
						learning_rate=0.3,
						cp=0.00005,
						loss_function="gaussian",
						min_split=int(sqrt(70000)),
						max_num_bins=int(sqrt(70000)),
						seed=9)
elif model_name == "FT":
	# Train the Fast Trees (rx_fast_trees implementation).
	model = rx_fast_trees(formula=formula,
                          data=LoS_Train,
                          num_trees=40,
                          method="regression",
                          learning_rate=0.2,
                          split_fraction=5/24,
                          min_split=10)
else:
	# Train the Neural Network (rx_neural_network implementation).
	model = rx_neural_network(formula=formula,
                            data=LoS_Train,
                            method = "regression",
                            num_hidden_nodes = 128,
                            num_iterations = 100,
                            optimizer = adadelta_optimizer(),
                            mini_batch_size = 20)
			   				       
OutputDataSet = DataFrame({"payload": dill.dumps(model)}, index=[0])'
, @params = N' @model_name varchar(20), @dataset_name varchar(max), @info varbinary(max), @database_name varchar(max)'
, @model_name = @model_name 
, @dataset_name =  @dataset_name
, @info = @info
, @database_name = @database_name

UPDATE Models set model_name = @model_name 
WHERE model_name = 'default model'

;
END

GO
USE [master]
GO
ALTER DATABASE [Hospital_Py] SET  READ_WRITE 
GO
