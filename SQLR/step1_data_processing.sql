-- Compute and store data statistics that will be used during production for preprocessing and feature engineering.

-- @input: specify the name of the raw data set of the Development/Modeling pipeline for which you want to store Statistics. 

DROP PROCEDURE IF EXISTS [dbo].[compute_stats]
GO

CREATE PROCEDURE [compute_stats]  @input varchar(max) = 'LengthOfStay'
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
;

-- Missing value treatment.  
-- Assumption, eid and lenghofstay have no missing values. 

-- @input: specify the name of the raw data set to be cleaned. 
-- @output: specify the name of the View that will hold the cleaned data set.

-- 1st Method: NULL is replaced with "missing" (character variables) or -1 (numeric variables) 

DROP PROCEDURE IF EXISTS [dbo].[fill_NA_explicit]
GO

CREATE PROCEDURE [fill_NA_explicit]  @input varchar(max), @output varchar(max)
AS
BEGIN

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
;


-- 2nd Method: NULL is replaced with the mode (categorical variables) or mean (float variables) 

DROP PROCEDURE IF EXISTS [dbo].[fill_NA_mode_mean]
GO

CREATE PROCEDURE [fill_NA_mode_mean]  @input varchar(max), @output varchar(max)
AS
BEGIN

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
;



