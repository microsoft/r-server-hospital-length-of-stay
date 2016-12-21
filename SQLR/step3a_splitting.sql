/****** Stored Procedure for splitting the data set into a training and a testing set  ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DROP PROCEDURE IF EXISTS [dbo].[splitting]
GO

CREATE PROCEDURE [splitting]  @splitting_percent int = 70, @input varchar(max) = 'LoS',  @output varchar(max) = 'Train_Id'
AS
BEGIN

  DECLARE @sql nvarchar(max);
  SET @sql = N'
  DROP TABLE IF EXISTS ' + @output + '
  SELECT eid 
  INTO ' + @output + '
  FROM ' + @input + ' 
  WHERE ABS(CAST(BINARY_CHECKSUM(eid, NEWID()) as int)) % 100 < ' + Convert(Varchar, @splitting_percent);

  EXEC sp_executesql @sql
;
END
GO

