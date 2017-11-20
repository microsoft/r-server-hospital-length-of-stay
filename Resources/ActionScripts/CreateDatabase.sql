



BEGIN
	DECLARE  @DbName VARCHAR(400) = N'$(dbName)'
	DECLARE @ServerName varchar(100) = (SELECT CAST(SERVERPROPERTY('ServerName') as Varchar))
	DECLARE @Qry VARCHAR(MAX) 

	SET @Qry = 
		(' 
		EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N''<DBName>''
		USE [master]
		ALTER DATABASE <DBName> SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
		USE [master]
		DROP DATABASE <DBName>
		')


	--If DB Already Exists , Drop it and recreate it 
	IF EXISTS(select * from sys.databases where name = @DbName)
	
	BEGIN 
		SET @Qry = (REPLACE(@Qry,'<dbName>',@DbName) )
		EXEC (@Qry) 
	END 

	
	DECLARE @Query VARCHAR(MAX)=''
---Find Default Database File Path and Create DB there 
	DECLARE @DbFilePath VARCHAR(400) = (SELECT top 1 LEFT(physical_name, (LEN(physical_name) - CHARINDEX('\',REVERSE(physical_name)))) + '\' as BasePath FROM sys.master_files WHERE type_desc = 'ROWS')

--Find Default Log File Path and Create Log there
	DECLARE @LogFilePath VARCHAR(400) = (SELECT top 1 LEFT(physical_name, (LEN(physical_name) - CHARINDEX('\',REVERSE(physical_name)))) + '\' as BasePath FROM sys.master_files WHERE type_desc = 'LOG')


	IF NOT EXISTS(select * from sys.databases where name = @DbName)
	BEGIN
		SET @Query = @Query + 'CREATE DATABASE '+@DbName +' ON  PRIMARY '
		SET @Query = @Query + '( NAME = '''+@DbName +''', FILENAME = '''+@DbFilePath+@DbName +'.mdf'' , SIZE = 73728KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB ) '
		SET @Query = @Query + ' LOG ON '
		SET @Query = @Query + '( NAME = '''+@DbName +'_log'', FILENAME = '''+@LogFilePath+@DbName +'_log.ldf'' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 1024KB)'
		exec(@query)
	END

	DECLARE @Alter VARCHAR(MAX) 
	SET @Alter = 
	(
	'ALTER DATABASE <db> SET COMPATIBILITY_LEVEL = 130
	IF (1 = FULLTEXTSERVICEPROPERTY(''IsFullTextInstalled''))
	begin
		EXEC <db>.[dbo].[sp_fulltext_database] @action = ''enable''
	end
	ALTER DATABASE <db> SET ANSI_NULL_DEFAULT OFF 
	ALTER DATABASE <db> SET ANSI_NULLS OFF 
	ALTER DATABASE <db> SET ANSI_PADDING OFF 
	ALTER DATABASE <db> SET ANSI_WARNINGS OFF 
	ALTER DATABASE <db> SET ARITHABORT OFF 
	ALTER DATABASE <db> SET AUTO_CLOSE OFF 
	ALTER DATABASE <db> SET AUTO_SHRINK OFF 
	ALTER DATABASE <db> SET AUTO_UPDATE_STATISTICS ON 
	ALTER DATABASE <db> SET CURSOR_CLOSE_ON_COMMIT OFF 
	ALTER DATABASE <db> SET CURSOR_DEFAULT  GLOBAL 
	ALTER DATABASE <db> SET CONCAT_NULL_YIELDS_NULL OFF 
	ALTER DATABASE <db> SET NUMERIC_ROUNDABORT OFF 
	ALTER DATABASE <db> SET QUOTED_IDENTIFIER OFF 
	ALTER DATABASE <db> SET RECURSIVE_TRIGGERS OFF 
	ALTER DATABASE <db> SET  ENABLE_BROKER 
	ALTER DATABASE <db> SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
	ALTER DATABASE <db> SET DATE_CORRELATION_OPTIMIZATION OFF 
	ALTER DATABASE <db> SET TRUSTWORTHY OFF 
	ALTER DATABASE <db> SET ALLOW_SNAPSHOT_ISOLATION OFF 
	ALTER DATABASE <db> SET PARAMETERIZATION SIMPLE 
	ALTER DATABASE <db> SET READ_COMMITTED_SNAPSHOT OFF 
	ALTER DATABASE <db> SET HONOR_BROKER_PRIORITY OFF 
	ALTER DATABASE <db> SET RECOVERY FULL 
	ALTER DATABASE <db> SET  MULTI_USER 
	ALTER DATABASE <db> SET PAGE_VERIFY CHECKSUM  
	ALTER DATABASE <db> SET DB_CHAINING OFF 
	ALTER DATABASE <db> SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
	ALTER DATABASE <db> SET TARGET_RECOVERY_TIME = 60 SECONDS 
	ALTER DATABASE <db> SET DELAYED_DURABILITY = DISABLED 
	EXEC sys.sp_db_vardecimal_storage_format N''<db>'', N''ON''
	ALTER DATABASE <db> SET QUERY_STORE = OFF
	ALTER DATABASE <db> SET  READ_WRITE'
	)
	SET @Alter = (REPLACE(@Alter,'<db>',@DbName)) 
	EXEC (@Alter) 
	SET @Qry = 
	'
	IF NOT EXISTS (SELECT name FROM master.sys.server_principals where name = ''<sn>\SQLRUserGroup'')
	BEGIN CREATE LOGIN [<sn>\SQLRUserGroup] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english] END
	'
	SET @Qry = REPLACE(@qry,'<sn>', @ServerName)
	
	EXEC (@Qry)



	SET @Qry = 
	'
	USE [<dbName>]
	CREATE USER [<sn>\SQLRUserGroup] FOR LOGIN [<sn>\SQLRUserGroup]


	ALTER USER [<sn>\SQLRUserGroup] WITH DEFAULT_SCHEMA=NULL

	ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [<sn>\SQLRUserGroup]

	ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [<sn>\SQLRUserGroup]

	ALTER AUTHORIZATION ON SCHEMA::[db_ddladmin] TO [<sn>\SQLRUserGroup]
	'
	SET @Qry = REPLACE(REPLACE(@qry,'<sn>', @ServerName),'<dbName>',@DbName) 
	
    EXEC (@Qry)

END 
