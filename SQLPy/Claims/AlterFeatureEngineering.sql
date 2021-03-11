Use Hospital_Py
go
ALTER PROCEDURE [dbo].[feature_engineering]  @input varchar(max), @output varchar(max), @is_production int
AS
BEGIN 

-- Drop the output table if it has been created in Py in the same database. 
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

-- Data Description: https://microsoft.github.io/r-server-hospital-length-of-stay/input_data.html
	DECLARE @sql2 nvarchar(max);
	SELECT @sql2 = N'
		CREATE VIEW ' + @output + '
		AS
		SELECT  ClaimClaimID, 
                ClaimReportedDate, 
                ClaimClaimStatusID, 
                ClaimStatusDescription, 
                StatesStateCode, 
                LossTypeDescription, 
                PolicyVersionAttributesFormType, 
                PolicyVersionAttributesOccupancyType, 			   
		       (PolicyVersionAttributesCoverageA - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''PolicyVersionAttributesCoverageA''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''PolicyVersionAttributesCoverageA'') AS PolicyVersionAttributesCoverageA,
		       --(ClaimMoneyReserve - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''ClaimMoneyReserve''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''ClaimMoneyReserve'') AS ClaimMoneyReserve,
		       (ClaimMoneyLosses - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''ClaimMoneyLosses''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''ClaimMoneyLosses'') AS ClaimMoneyLosses,
		       (ClaimMoneyLAE - (SELECT mean FROM [dbo].[Stats] WHERE variable_name = ''ClaimMoneyLAE''))/(SELECT std FROM [dbo].[Stats] WHERE variable_name = ''ClaimMoneyLAE'') AS ClaimMoneyLAE,
               ClaimRoomsWithDamage AS number_of_issues,
			   ClaimDateClosed,'+
			   (CASE WHEN @is_production = 0 THEN 'CAST(lengthofstay as float) lengthofstay' else 'NULL as lengthofstay' end) + '
	    FROM ' + @input;
	EXEC sp_executesql @sql2

;
END
GO
