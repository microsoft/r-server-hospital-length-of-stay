-- Stored Procedure for splitting the data set into a training and a testing set. 

-- @splitting_percent: specify the percentage of the featurized data set that will go to the training set for the development pipeline. 
-- @input: specify the name of the featurized data set.  

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[splitting]
GO

CREATE PROCEDURE [splitting]  @splitting_percent int = 70, @input varchar(max) 
AS
BEGIN

  DECLARE @sql nvarchar(max);
  SET @sql = N'
  DROP TABLE IF EXISTS Train_Id
  SELECT eid 
  INTO Train_Id
  FROM ' + @input + ' 
  WHERE ABS(CAST(BINARY_CHECKSUM(eid, NEWID()) as int)) % 100 < ' + Convert(Varchar, @splitting_percent);

  EXEC sp_executesql @sql
;
END
GO

