-- Create an empty table LengthOfStay_Prod to be filled with the new data with PowerShell during Production. 
DROP TABLE IF EXISTS [dbo].[LengthOfStay_Prod]
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
    )

CREATE CLUSTERED COLUMNSTORE INDEX lengthprod_cci ON LengthOfStay_Prod WITH (DROP_EXISTING = OFF);

-- Copy the Stats, Models, and ColInfo tables to the Production database (Only used for Production). 

-- @dev_db: specify the name of the development database holding those tables. 

DROP PROCEDURE IF EXISTS [dbo].[copy_modeling_tables]
GO

CREATE PROCEDURE [copy_modeling_tables]  @dev_db varchar(max) = 'Hospital'
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
;
