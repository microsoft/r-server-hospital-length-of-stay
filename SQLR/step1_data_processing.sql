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

 -- Select the column names to be filled into the table Sql_Columns.
	DECLARE @sql nvarchar(max);
	SELECT @sql = N'
	DROP TABLE if exists Sql_Columns
	SELECT name 
	INTO Sql_Columns
	FROM syscolumns 
	WHERE id = object_id(''' + @input_output + ''')
	AND name NOT IN (''eid'')';
	EXEC sp_executesql @sql;

    -- Loops to fill missing values for the variables.
	DECLARE @name NVARCHAR(100)
	DECLARE @getname CURSOR

	SET @getname = CURSOR FOR
	SELECT name
	FROM  Sql_Columns

	OPEN @getname
	FETCH NEXT
	FROM @getname INTO @name
	WHILE @@FETCH_STATUS = 0
	BEGIN	
		-- Get the variable type.
		DECLARE @type varchar(50)
		DECLARE @sql00 nvarchar(max);
		DECLARE @Parameter00 nvarchar(500);
		SELECT @sql00 = N'
			SELECT @typeOUT = type
			FROM (SELECT DATA_TYPE as type
				  FROM INFORMATION_SCHEMA.COLUMNS
	              WHERE TABLE_NAME = ''' + @input_output + ''' 
				  AND   COLUMN_NAME = ''' + @name + ''' ) as t ';
		SET @Parameter00 = N'@typeOUT varchar(max) OUTPUT';
		EXEC sp_executesql @sql00, @Parameter00, @typeOUT=@type OUTPUT;

		-- Replace character variables with 'missing'. 
		IF (@type = 'varchar')
		BEGIN 
			DECLARE @sql02 nvarchar(max)
			SET @sql02 = 
			'UPDATE ' + @input_output + '
			 SET ' + @name + ' = ISNULL(' + @name + ',''missing'')';
			EXEC sp_executesql @sql02;
		END;

		-- Replace numeric variables with '-1'. 
		ELSE
		BEGIN
			DECLARE @sql04 nvarchar(max)
			SET @sql04 = 
			'UPDATE ' + @input_output + '
			 SET ' + @name + ' = ISNULL(' + @name + ', -1)';
			EXEC sp_executesql @sql04;
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
	WHERE id = object_id(''' + @input_output + ''')
	AND name NOT IN (''eid'')';
	EXEC sp_executesql @sql;

    -- Loops to fill missing values for the variables.
	DECLARE @name NVARCHAR(100)
	DECLARE @getname CURSOR

	SET @getname = CURSOR FOR
	SELECT name
	FROM  Sql_Columns

	OPEN @getname
	FETCH NEXT
	FROM @getname INTO @name
	WHILE @@FETCH_STATUS = 0
	BEGIN	
		-- Get the variable type.
		DECLARE @type varchar(50)
		DECLARE @sql00 nvarchar(max);
		DECLARE @Parameter00 nvarchar(500);
		SELECT @sql00 = N'
			SELECT @typeOUT = type
			FROM (SELECT DATA_TYPE as type
				  FROM INFORMATION_SCHEMA.COLUMNS
	              WHERE TABLE_NAME = ''' + @input_output + ''' 
				  AND   COLUMN_NAME = ''' + @name + ''' ) as t ';
		SET @Parameter00 = N'@typeOUT varchar(max) OUTPUT';
		EXEC sp_executesql @sql00, @Parameter00, @typeOUT=@type OUTPUT;

		-- Replace categorical variables with the mode. 
		IF (@type = 'varchar' or @type = 'int')
		BEGIN 
			DECLARE @mode varchar(50);
			DECLARE @sql01 nvarchar(max);
			DECLARE @Parameter01 nvarchar(500);
			SELECT @sql01 = N'
				SELECT @modeOUT = mode
				FROM (SELECT TOP(1) ' + @name + ' as mode, count(*) as cnt
					FROM ' + @input_output + ' 
					GROUP BY ' + @name + ' 
					ORDER BY cnt desc) as t ';
			SET @Parameter01 = N'@modeOUT varchar(max) OUTPUT';
			EXEC sp_executesql @sql01, @Parameter01, @modeOUT=@mode OUTPUT;

			DECLARE @sql02 nvarchar(max)
			SET @sql02 = 
			'UPDATE ' + @input_output + '
			 SET ' + @name + ' = ISNULL(' + @name + ', (SELECT '''  + @mode + '''))';
			EXEC sp_executesql @sql02;
		END;

		-- Replace continuous variables with the mean. 
		ELSE
		BEGIN
			DECLARE @mean float;
			DECLARE @sql03 nvarchar(max);
			DECLARE @Parameter03 nvarchar(500);
			SELECT @sql03 = N'
				SELECT @meanOUT = mean
				FROM (SELECT AVG(' + @name + ') as mean
					  FROM ' + @input_output + ') as t ';
			SET @Parameter03 = N'@meanOUT float OUTPUT';
			EXEC sp_executesql @sql03, @Parameter03, @meanOUT=@mean OUTPUT;

			DECLARE @sql04 nvarchar(max)
			SET @sql04 = 
			'UPDATE ' + @input_output + '
			 SET ' + @name + ' = ISNULL(' + @name + ', (SELECT '  + Convert(Varchar,  @mean) + '))';
			EXEC sp_executesql @sql04;
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

