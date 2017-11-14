<#

This Script will install the Database and do the First run of scoring the data.
This can be run at anytime and will refresh teh Database to the initial state 
It is conifgured for default settings ie Creating the Hospital Database in the SQL Server 
If you want to choose a different database name , you can call this script from a ps cmd line using this cmd  ./CreateDatabase.ps1 -PromptedInstall Y
or run the script from this window.
Created on 10.5.2017 Bob White 
Added Python Scripting 11/14/2017 bw  
#>

param 
(
[Parameter(Mandatory=$false)] [String] $PromptedInstall  =  "",

[Parameter(Mandatory=$false)] [String] $ServerName  =  "",

[Parameter(Mandatory=$false)] [String] $dbName  =  ""
)

$startTime= Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time is for Database Configuration:" $startTime 

##DSVM Does not have SQLServer Powershell Module , this will try and install it if it is not present it will work , if it is already there it will error out 
Write-Host " Installing SQLServer Power Shell Module , if it is already installed a warning will be displayed , this is OK........."
Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
Import-Module -Name SQLServer


#Write-Host -ForegroundColor 'Cyan' " Switching SQL Server to Mixed Mode"


### Change Authentication From Windows Auth to Mixed Mode 
#Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 

Write-Host -ForeGroundColor 'cyan' " Configuring SQL to allow running of External Scripts "
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL (new feature on SQL 2017)
Invoke-Sqlcmd -Query "EXEC sp_configure  'external scripts enabled', 1"

### Force Change in SQL Policy on External Scripts 
Invoke-Sqlcmd -Query "RECONFIGURE WITH OVERRIDE" 
Write-Host -ForeGroundColor 'cyan' " SQL Server Configured to allow running of External Scripts "

Write-Host -ForeGroundColor 'cyan' " Restarting SQL Services "
### Changes Above Require Services to be cycled to take effect 
### Stop the SQL Service and Launchpad wild cards are used to account for named instances  
Stop-Service -Name "MSSQ*" -Force

### Start the SQL Service 
Start-Service -Name "MSSQ*"
Write-Host -ForegroundColor 'Cyan' " SQL Services Restarted"


Write-Host -ForegroundColor 'Cyan' " Done with configuration changes to SQL Server"


########################################################################
#Check Install Type Prompted Or Not Prompted, Not Prompted is Default
########################################################################
$Prompt = $PromptedInstall

#$Prompt = 'Y'
$Prompt = 
        if ($Prompt -eq 'Y' -or $Prompt -eq 'y') {'Y'} 
        elseif ([string]::IsNullOrEmpty($Prompt) -or $Prompt -eq 'N' -or $Prompt -eq 'n' ) {'N'}  
######################################################################## 
# If Prompted Install is Invoked, Prompt For SQLServer and dbName
########################################################################

$ServerName = if ([string]::IsNullOrEmpty($ServerName) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {Read-Host  -Prompt "Enter Desired SQL Server Name"} 
                elseif ((![string]::IsNullOrEmpty($ServerName)) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {$ServerName}
                else {"LOCALHOST"}

$dbName = if ([string]::IsNullOrEmpty($dbName) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {Read-Host  -Prompt "Enter Desired Database Name"} 
            elseif ((![string]::IsNullOrEmpty($dbName)) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {$dbName}
            else {"Hospital"} 
$dbName_R = $dbName + "_R"
$dbName_Py = $dbName + "_py"
    

######################################################################## 
#Decide whether we are using Trusted or Non Trusted Connections. ........Currently this does not work..............
########################################################################

$trustedConnection = "Y"
##$trustedConnection = if ($Prompt -eq 'y' -or $Prompt -eq 'Y') {"Y"} ELSE {Read-Host  -Prompt "Use Trusted Connection? Type in 'Y' or 'N'"}
##$UserName = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter UserName"}
##$Password = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter Password" -AsSecureString} 
 

 


 ##$ServerName = "LOCALHOST"
 $basePath = "c:\Solutions\Hospital\"
 $dataPath = $basePath+ "Data"
 $scriptPath =  $basePath + "Resources\ActionScripts\"
 $SqlRPath = $basePath + "SQLR"
 $SqlPyPath = $basePath + "SQLPy"
 

##########################################################################

# Create Database and BaseTables 

#########################################################################

Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

## Create RServer DB 
$SqlParameters = @("dbName=$dbName_R")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjects.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName_R database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName_R Created")
invoke-sqlcmd "USE $dbName;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName_R database")
invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName_R


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName_R Database")



## Create PYServer DB 
$SqlParameters = @("dbName=$dbName_Py")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjects.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName_Py database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName_Py Created")
invoke-sqlcmd "USE $dbName;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName_Py database")
invoke-sqlcmd -inputfile $CreateSQLObjectsPY -serverinstance $ServerName -database $dbName_Py


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName_Py Database")






#########################################################################
### Enable implied Authentication for the Launchpad group
#########################################################################

## Check to see if SQLRUser Group already exists 


$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)
$si =  if ($si -like '*\*') 

{
    $SN,$IN = $si.split('\')
    $SqlUser = $SN + '\SQLRUserGroup' + $IN
    if ((Get-SQLLogin -ServerInstance $si -LoginName $SQLUser -EA SilentlyContinue))
    {
    Write-Host -ForegroundColor 'Cyan'  ''$SqlUser 'is already created in the Master Database'
    }
    ELSE 
    { 
    Write-Host -ForegroundColor 'Cyan'  " Setting up SQLRUserGroup for Name Instance "
    $SN,$IN = $si.split('\')
    $Query = 'USE [master] CREATE LOGIN ['+$SN + '\SQLRUserGroup' + $IN +'] FROM WINDOWS WITH DEFAULT_DATABASE=[master]' 
    invoke-sqlcmd -serverinstance $ServerName -database $dbName_R -Query $Query 
    }
    Write-Host -ForegroundColor 'Cyan' " Giving SQLRUser Group access to  Name $Si "
    $Query = 'USE [' + $dbName_R +']' + ' CREATE USER [' + $SN + '\SQLRUserGroup' + $IN +'] FOR LOGIN [' +  $SN + '\SQLRUserGroup' + $IN + ']'
    invoke-sqlcmd -serverinstance $ServerName -database $dbName_R -Query $Query 
}
ELSE 
{   
    $SqlUser = $si + '\SQLRUserGroup'
    if ((Get-SQLLogin -ServerInstance $si -LoginName $SQLUser -EA SilentlyContinue)) 
    { 
    Write-Host ''$SqlUser 'has already been given access to the Database' 
    }
    ELSE
    {
    write-host -ForegroundColor 'Cyan'  " Setting up SQLRUser Group for Default Instance"
    $Query = 'USE [master] CREATE LOGIN ['+$si+'\SQLRUserGroup] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
    invoke-sqlcmd -serverinstance $ServerName -database $dbName_R -Query $Query 
    }
    write-host -ForegroundColor 'Cyan' " Giving SQLRUserGroup access to  $Si Database"
    $Query = 'USE [' + $dbName + '] CREATE USER [SQLRUserGroup] FOR LOGIN [' + $si + '\SQLRUserGroup]'
    invoke-sqlcmd -serverinstance $si -database $dbName_R -Query $Query 
}

    Write-Host -ForeGroundColor cyan " Installing latest Power BI..."
    # Download PowerBI Desktop installer
    Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi
    
    # Silently install PowerBI Desktop
    msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1
    
    if (!$?)
    {
        Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
    }

    write-host -ForegroundColor 'Green' " SQL Server has been configured, now load and train data...." 
    
##########################################################################
# Deployment Pipeline
##########################################################################
##Create Shortcuts and Autostart Help File 
    Copy-Item "$ScriptPath\SolutionHelp.url" C:\Users\Public\Desktop\
    Copy-Item "$ScriptPath\SolutionHelp.url" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
    Write-Host -ForeGroundColor cyan " Help Files Copied to Desktop"

    


###Copy PowerBI Reportt to Desktop 
  Copy-Item  "$ScriptPath\*.pbix"  C:\Users\Public\Desktop\
  Write-Host -ForeGroundColor cyan " PowerBI Reports Copied to Desktop"
  $ActionScript = "$SqlRPath\LoadandScoreDataSQLR.ps1"
  Invoke-Expression $ActionScript $ServerName $dbName_R $PromptedInstall $trustedConnection