:on error exit
--
-- remove old $(username) user and login from master.
-- $(username) and $(password) is substituted by Invoke-SqlCmd
-- through environment variables.
--
USE [master]
GO
IF EXISTS (SELECT name  FROM sys.database_principals WHERE name = '$(username)')
BEGIN
    PRINT 'Deleting old $(username) user from master'
    DROP USER [$(username)]
END
GO
IF EXISTS (SELECT name  FROM master.sys.server_principals WHERE name = '$(username)')
BEGIN
    PRINT 'Deleting old $(username) login from master'
    DROP LOGIN [$(username)]
END
GO
--
-- create new $(username) login in master
--
USE [master]
GO
PRINT 'Creating $(username) login in master'
CREATE LOGIN [$(username)] WITH PASSWORD=N'$(password)', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
CREATE USER [$(username)] FOR LOGIN [$(username)] 
--ALTER ROLE [db_rrerole] ADD MEMBER [$(username)]
ALTER ROLE [db_owner] ADD MEMBER [$(username)]
GO

exec sp_addrolemember 'db_owner', '$(username)'
exec sp_addrolemember 'db_ddladmin', '$(username)'
exec sp_addrolemember 'db_accessadmin', '$(username)'
exec sp_addrolemember 'db_datareader', '$(username)'
exec sp_addrolemember 'db_datawriter', '$(username)'
exec sp_addsrvrolemember @loginame= '$(username)', @rolename = 'sysadmin'  
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


-- Increase memory allocated to R. 
USE [master]
GO
SELECT * FROM sys.resource_governor_resource_pools WHERE name = 'default'  
SELECT * FROM sys.resource_governor_external_resource_pools WHERE name = 'default'  
ALTER EXTERNAL RESOURCE POOL "default" WITH (max_memory_percent = 100);  
ALTER RESOURCE GOVERNOR reconfigure;  

