-- Remove old rdemo user and login from master
USE [master]
GO
IF EXISTS (SELECT name  FROM sys.database_principals WHERE name = 'rdemo')
BEGIN
	PRINT 'Deleting old rdemo user from master'
    DROP USER [rdemo]
END
GO
IF EXISTS (SELECT name  FROM master.sys.server_principals WHERE name = 'rdemo')
BEGIN
	PRINT 'Deleting old rdemo login from master'
	DROP LOGIN [rdemo]
END
GO

-- Create new rdemo login in master
USE [master]
GO
PRINT 'Creating rdemo login in master'
CREATE LOGIN [rdemo] WITH PASSWORD=N'D@tascience', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
CREATE USER [rdemo] FOR LOGIN [rdemo] 
--ALTER ROLE [db_rrerole] ADD MEMBER [rdemo]
ALTER ROLE [db_owner] ADD MEMBER [rdemo]
GO

exec sp_addrolemember 'db_owner', 'rdemo'
exec sp_addrolemember 'db_ddladmin', 'rdemo'
exec sp_addrolemember 'db_accessadmin', 'rdemo'
exec sp_addrolemember 'db_datareader', 'rdemo'
exec sp_addrolemember 'db_datawriter', 'rdemo'
exec sp_addsrvrolemember @loginame= 'rdemo', @rolename = 'sysadmin'  
GO 


-- Enable implied authentification so a connection string can be automatically created in R codes embedded into SQL SP. 
USE [master]
GO
DECLARE @host_name nvarchar(100) 
SET @host_name = (SELECT HOST_NAME())
DECLARE @sql nvarchar(max);
SELECT @sql = N'
CREATE LOGIN [' + @host_name + '\SQLRUserGroup] FROM WINDOWS WITH DEFAULT_DATABASE=[master]';
EXEC sp_executesql @sql;
