-- Stored Procedure to use native scoring for RF model (rxDForest implementation) for a single new case

-- @eid: specify the patient id to retrive record and score

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[do_native_predict]
    @eid int
AS
BEGIN
    DECLARE @nativeModel VARBINARY(MAX)
    DECLARE @start DATETIME
    DECLARE @end DATETIME
    DECLARE @elapsed varchar(max)

    -- Get the native model from the models table
    SET @nativeModel = ( SELECT native_model
    FROM [Models]
    WHERE model_name = 'RF')


    -- Get the patient record from a historical table using the eid
    SELECT *
    INTO [#QueryPatient]
    FROM [LoS]
    WHERE eid = @eid

    SET @start = GETDATE()

    -- Do real time scoring using native PREDICT clause
    SELECT [LengthOfStay_Pred]
    FROM PREDICT (MODEL = @nativeModel, DATA = [#QueryPatient] ) WITH ( LengthOfStay_Pred FLOAT ) p;

    SET @end = GETDATE()

    SET @elapsed = CONVERT(VARCHAR(max),(SELECT DATEDIFF(MICROSECOND,@start,@end)))

    PRINT 'Elapsed Time for 1 row scoring is : ' + @elapsed + ' microseconds.'
END

