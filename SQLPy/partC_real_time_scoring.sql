--- Perform Real Time Scoring on previously trained models
--- Use 'RF' for Random Forest, use 'GBT' for b_trees, use 'FT' for Fast Trees, or use 'NN' for Neural Network
--- Results are written to RTS_Prediction

--- NOTE: Run prepare_real_time_scoring.sql before running this script.

Use Hospital
GO

--- Real Time Scoring

--	Get the trained model
DECLARE @model_name VARCHAR(3) = 'GBT'
DECLARE @model VARBINARY(max) = (SELECT value FROM [dbo].[RTS] WHERE id = @model_name);		

--- Real Time Scoring is meant for small scoring request, which is why we select the top 10 for this example.
DECLARE @inputData VARCHAR(max);
SET @inputData = 'SELECT TOP (10) 
				eid, fibrosisandother, psychother, bloodureanitro, sodium,
				rcount, secondarydiagnosisnonicd9, bmi, neutrophils, respiration, 
				psychologicaldisordermajor, irondef, malnutrition, pneum, depress,
				CAST(lengthofstay AS float) lengthofstay, pulse, asthma,	
				gender, number_of_issues, creatinine, glucose, hematocrit,
				dialysisrenalendstage, hemo, substancedependence
				FROM LoS WHERE eid NOT IN (SELECT eid from Train_Id) ORDER BY eid';

DECLARE @output_table TABLE(lengthofstay_Pred FLOAT);
INSERT @output_table EXEC [dbo].[sp_rxPredict] @model = @model, @inputData = @inputData;
DROP TABLE IF EXISTS RTS_Prediction;
SELECT * INTO RTS_Prediction FROM @output_table