/* Missing value treatment.  */
/* Assumption, eid has no missing values.  */

/*** 1st Method: NULL is replaced with "missing" (character variables) or -1 (numeric variables)  ***/

DROP PROCEDURE IF EXISTS [dbo].[fill_NA_explicit]
GO

CREATE PROCEDURE [fill_NA_explicit]  @input_output varchar(max) = 'LengthOfStay'
AS
BEGIN

 -- Update the statistics of the input table for faster computations. 
	DECLARE @sql0 nvarchar(max);
	SELECT @sql0 = N'
	UPDATE STATISTICS ' + @input_output ;
	EXEC sp_executesql @sql0;

 -- Get the names of the columns to analyze. 
	DECLARE @sql nvarchar(max);
	SELECT @sql = N'
	DROP TABLE if exists Sql_Columns
	SELECT name 
	INTO Sql_Columns
	FROM syscolumns 
	WHERE id = object_id(''' + @input_output + ''') AND name NOT IN (''eid'')';
	EXEC sp_executesql @sql;

    -- Loops to fill missing values for the variables.
	DECLARE @name NVARCHAR(100)
	DECLARE @getname CURSOR

	SET @getname = CURSOR FOR
	SELECT name FROM  Sql_Columns

	OPEN @getname
	FETCH NEXT
	FROM @getname INTO @name
	WHILE @@FETCH_STATUS = 0
	BEGIN	

		-- Check whether the variable contains a missing value. We perform cleaning only for variables containing NULL. 
		DECLARE @missing varchar(50)
		DECLARE @sql1 nvarchar(max);
		DECLARE @Parameter1 nvarchar(500);
		SELECT @sql1 = N'
			SELECT @missingOUT = missing
			FROM (SELECT count(*) - count(' + @name + ') as missing
			      FROM ' + @input_output + ') as t';
		SET @Parameter1 = N'@missingOUT varchar(max) OUTPUT';
		EXEC sp_executesql @sql1, @Parameter1, @missingOUT=@missing OUTPUT;
		IF (@missing > 0)
		BEGIN 

			-- Get the variable type.
			DECLARE @type varchar(50)
			DECLARE @sql10 nvarchar(max);
			DECLARE @Parameter10 nvarchar(500);
			SELECT @sql10 = N'
				SELECT @typeOUT = type
				FROM (SELECT DATA_TYPE as type
					  FROM INFORMATION_SCHEMA.COLUMNS
	                  WHERE TABLE_NAME = ''' + @input_output + ''' 
			          AND COLUMN_NAME = ''' + @name + ''' ) as t ';
			SET @Parameter10 = N'@typeOUT varchar(max) OUTPUT';
			EXEC sp_executesql @sql10, @Parameter10, @typeOUT=@type OUTPUT;

			-- Replace character variables with 'missing'. 
			IF (@type = 'varchar')
			BEGIN 
				DECLARE @sql101 nvarchar(max)
				SET @sql101 = 
				'UPDATE ' + @input_output + '
				SET ' + @name + ' = ISNULL(' + @name + ',''missing'')';
				EXEC sp_executesql @sql101;
			END;

			-- Replace numeric variables with '-1'. 
			ELSE
			BEGIN
				DECLARE @sql102 nvarchar(max)
				SET @sql102 = 
				'UPDATE ' + @input_output + '
				 SET ' + @name + ' = ISNULL(' + @name + ', -1)';
				EXEC sp_executesql @sql102;
			END;
		END;
		FETCH NEXT
		FROM @getname INTO @name
	END
	CLOSE @getname
	DEALLOCATE @getname

	-- Drop intermediate table.
	DROP TABLE Sql_Columns

END
GO
;


/*** 2nd Method: NULL is replaced with the mode (categorical variables) or mean (float variables)  ***/

DROP PROCEDURE IF EXISTS [dbo].[fill_NA_mode_mean]
GO

CREATE PROCEDURE [fill_NA_mode_mean]  @input_output varchar(max) = 'LengthOfStay'
AS
BEGIN

 -- Update the statistics of the input table for faster computations. 
	DECLARE @sql0 nvarchar(max);
	SELECT @sql0 = N'
	UPDATE STATISTICS ' + @input_output ;
	EXEC sp_executesql @sql0;

 -- Select the column names to be filled into the table Sql_Columns.
	DECLARE @sql nvarchar(max);
	SELECT @sql = N'
	DROP TABLE if exists Sql_Columns
	SELECT name 
	INTO Sql_Columns
	FROM syscolumns 
	WHERE id = object_id(''' + @input_output + ''') AND name NOT IN (''eid'')';
	EXEC sp_executesql @sql;

    -- Loops to fill missing values for the variables.
	DECLARE @name NVARCHAR(100)
	DECLARE @getname CURSOR

	SET @getname = CURSOR FOR
	SELECT name FROM  Sql_Columns

	OPEN @getname
	FETCH NEXT
	FROM @getname INTO @name
	WHILE @@FETCH_STATUS = 0
	BEGIN	

		-- Check whether the variable contains a missing value. We perform cleaning only for variables containing NULL. 
		DECLARE @missing varchar(50)
		DECLARE @sql1 nvarchar(max);
		DECLARE @Parameter1 nvarchar(500);
		SELECT @sql1 = N'
			SELECT @missingOUT = missing
			FROM (SELECT count(*) - count(' + @name + ') as missing
			      FROM ' + @input_output + ') as t';
		SET @Parameter1 = N'@missingOUT varchar(max) OUTPUT';
		EXEC sp_executesql @sql1, @Parameter1, @missingOUT=@missing OUTPUT;
		IF (@missing > 0)
		BEGIN 

			-- Get the variable type.
			DECLARE @type varchar(50)
			DECLARE @sql10 nvarchar(max);
			DECLARE @Parameter10 nvarchar(500);
			SELECT @sql10 = N'
				SELECT @typeOUT = type
				FROM (SELECT DATA_TYPE as type
					  FROM INFORMATION_SCHEMA.COLUMNS
	                  WHERE TABLE_NAME = ''' + @input_output + ''' 
			          AND COLUMN_NAME = ''' + @name + ''' ) as t ';
			SET @Parameter10 = N'@typeOUT varchar(max) OUTPUT';
			EXEC sp_executesql @sql10, @Parameter10, @typeOUT=@type OUTPUT;

			-- Replace categorical variables with the mode. 
			IF (@type = 'varchar' or @type = 'int')
			BEGIN 
				DECLARE @mode varchar(50);
				DECLARE @sql101 nvarchar(max);
				DECLARE @Parameter101 nvarchar(500);
				SELECT @sql101 = N'
					SELECT @modeOUT = mode
					FROM (SELECT TOP(1) ' + @name + ' as mode, count(*) as cnt
						  FROM ' + @input_output + ' 
						  GROUP BY ' + @name + ' 
						  ORDER BY cnt desc) as t ';
				SET @Parameter101 = N'@modeOUT varchar(max) OUTPUT';
				EXEC sp_executesql @sql101, @Parameter101, @modeOUT=@mode OUTPUT;

				DECLARE @sql102 nvarchar(max)
				SET @sql102 = 
				'UPDATE ' + @input_output + '
				SET ' + @name + ' = ISNULL(' + @name + ', (SELECT '''  + @mode + '''))';
				EXEC sp_executesql @sql102;
			END;

			-- Replace continuous variables with the mean. 
			ELSE
			BEGIN
				DECLARE @mean float;
				DECLARE @sql103 nvarchar(max);
				DECLARE @Parameter103 nvarchar(500);
				SELECT @sql103= N'
					SELECT @meanOUT = mean
					FROM (SELECT AVG(' + @name + ') as mean
						  FROM ' + @input_output + ') as t ';
				SET @Parameter103 = N'@meanOUT float OUTPUT';
				EXEC sp_executesql @sql103, @Parameter103, @meanOUT=@mean OUTPUT;

				DECLARE @sql104 nvarchar(max)
				SET @sql104 = 
				'UPDATE ' + @input_output + '
				SET ' + @name + ' = ISNULL(' + @name + ', (SELECT '  + Convert(Varchar,  @mean) + '))';
				EXEC sp_executesql @sql104;
			END;
		END;
		FETCH NEXT
		FROM @getname INTO @name
	END
	CLOSE @getname
	DEALLOCATE @getname

	-- Drop intermediate table.
	DROP TABLE Sql_Columns

END
GO
;

