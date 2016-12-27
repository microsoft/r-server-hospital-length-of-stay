/*** Stored procedure for feature engineering. ***/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[feature_engineering]
GO

CREATE PROCEDURE [dbo].[feature_engineering]  @input varchar(max) = 'LengthOfStay', @output varchar(max) = 'LoS'
AS
BEGIN 

-- Drop the output table if it already exists. 
	DECLARE @sql1 nvarchar(max);
	SELECT @sql1 = N'
		DROP TABLE if exists ' + @output;
	EXEC sp_executesql @sql1

-- 1- Standardize the health numeric variables by substracting the mean and dividing by the standard deviation. 
-- 2- Create number_of_issues variable corresponding to the total number of preidentified medical conditions. 
-- 3- Create lengthofstay_bucket, which is the bucketed version of the target variable for classification.

	DECLARE @sql2 nvarchar(max);
	SELECT @sql2 = N'
		SELECT eid, vdate, rcount, gender, dialysisrenalendstage, asthma, irondef, pneum, substancedependence, psychologicaldisordermajor,
			   depress, psychother, fibrosisandother, malnutrition,
			   (hemo - AVG(hemo) OVER())/(STDEV(hemo) OVER())AS hemo,
			   (hematocritic - AVG(hematocritic) OVER())/(STDEV(hematocritic) OVER()) AS hematocritic,
			   (neutrophils - AVG(neutrophils) OVER())/(STDEV(neutrophils) OVER()) AS neutrophils,
			   (sodium - AVG(sodium) OVER())/(STDEV(sodium) OVER()) AS sodium,
			   (glucose - AVG(glucose) OVER())/(STDEV(glucose) OVER()) AS glucose,
			   (bloodureanitro - AVG(bloodureanitro) OVER())/(STDEV(bloodureanitro) OVER()) AS bloodureanitro,
			   (creatinine - AVG(creatinine) OVER())/(STDEV(creatinine) OVER()) AS creatinine,
			   (bmi - AVG(bmi) OVER())/(STDEV(bmi) OVER()) AS bmi,
			   (pulse - AVG(pulse) OVER())/(STDEV(pulse) OVER()) AS pulse,
			   (respiration - AVG(respiration) OVER())/(STDEV(respiration) OVER()) AS respiration,
			   CAST((CAST(dialysisrenalendstage as int) + CAST(asthma as int) + CAST(irondef as int) + CAST(pneum as int) +
			    CAST(substancedependence as int) + CAST(psychologicaldisordermajor as int) + CAST(depress as int) + CAST(psychother as int) +
                CAST(fibrosisandother as int) + CAST(malnutrition as int)) as varchar(2)) AS number_of_issues,
			   secondarydiagnosisnonicd9, discharged, facid, lengthofstay,
			    lengthofstay_bucket = CASE WHEN lengthofstay < 4 THEN ''1'' WHEN lengthofstay < 7 THEN ''2'' WHEN lengthofstay < 10 THEN ''3''  
									  ELSE ''4'' END
	    INTO ' + @output + '
	    FROM ' + @input;
	EXEC sp_executesql @sql2

;
END
GO
