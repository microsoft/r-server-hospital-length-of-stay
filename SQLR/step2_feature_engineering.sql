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

	DECLARE @sql2 nvarchar(max);
	SELECT @sql2 = N'
		SELECT eid, vdate, rcount, gender, dialysisrenalendstage, asthma, irondef, pneum, substancedependence, psychologicaldisordermajor,
			   depress, psychother, fibrosisandother, malnutrition,
			   (hemo - AVG(hemo) OVER())/(STDEV(hemo) OVER())AS hemo_s,
			   (hematocritic - AVG(hematocritic) OVER())/(STDEV(hematocritic) OVER()) AS hematocritic_s,
			   (neutrophils - AVG(neutrophils) OVER())/(STDEV(neutrophils) OVER()) AS neutrophils_s,
			   (sodium - AVG(sodium) OVER())/(STDEV(sodium) OVER()) AS sodium_s,
			   (glucose - AVG(glucose) OVER())/(STDEV(glucose) OVER()) AS glucose_s,
			   (bloodureanitro - AVG(bloodureanitro) OVER())/(STDEV(bloodureanitro) OVER()) AS bloodureanitro_s,
			   (creatinine - AVG(creatinine) OVER())/(STDEV(creatinine) OVER()) AS creatinine_s,
			   (bmi - AVG(bmi) OVER())/(STDEV(bmi) OVER()) AS bmi_s,
			   (pulse - AVG(pulse) OVER())/(STDEV(pulse) OVER()) AS pulse_s,
			   (respiration - AVG(respiration) OVER())/(STDEV(respiration) OVER()) AS respiration_s,
			   CAST((CAST(dialysisrenalendstage as int) + CAST(asthma as int) + CAST(irondef as int) + CAST(pneum as int) +
			    CAST(substancedependence as int) + CAST(psychologicaldisordermajor as int) + CAST(depress as int) + CAST(psychother as int) +
                CAST(fibrosisandother as int) + CAST(malnutrition as int)) as varchar(2)) AS number_of_issues,
			   secondarydiagnosisnonicd9, discharged, facid, lengthofstay
	    INTO ' + @output + '
	    FROM ' + @input;
	EXEC sp_executesql @sql2

;
END
GO

exec [feature_engineering]

	