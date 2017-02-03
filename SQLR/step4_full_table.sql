-- We create a full table by adding the predictions to the testing set with discharged_pred: predicted date for discharge given by boosted trees. 
-- This will be used for PowerBI visualizations. 

DROP PROCEDURE IF EXISTS [dbo].[prediction_results]
GO

CREATE PROCEDURE [prediction_results] 
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


