<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).
---Need to add pass thru for Prompted install 

#>

param 
(
    [Parameter(Mandatory = $false)] [String]$Prompt = ""
) 

$Prompt= if ($Prompt -match '^y(es)?$') {'Y'} else {'N'}


$SolutionName = "Hospital"

$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime = Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time:" $startTime 



$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = $SolutionName
$SolutionPath = $solutionTemplatePath + '\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"
$scriptPath = $SolutionPath + "\Resources\ActionScripts\"

##########################################################################
#Clone Data from GIT
##########################################################################

### DON'T FORGET TO CHANGE TO MASTER LATER...

if (Test-Path $solutionTemplatePath) {
    Write-Host " Solution has already been cloned"
}
ELSE {
    git clone  --branch dev --single-branch https://github.com/Microsoft/r-server-hospital-length-of-stay $solutionPath
}
#################################################################
##DSVM Does not have SQLServer Powershell Module , this will try and install it if it is not present it will work , if it is already there it will error out 
#################################################################

Write-Host " Installing SQLServer Power Shell Module , if it is already installed a warning will be displayed , this is OK........."
Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
Import-Module -Name SQLServer



############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################

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
# If Prompted Install is Invoked, Prompt For SQLServer and dbName
########################################################################



$ServerName = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter SQL Server Name Or SQL InstanceName you are installing on"} else {"LOCALHOST"}


WRITE-HOST " ServerName set to $ServerName"

$dbName = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter Desired Database Base Name"} else {"Hospital"} 


$dbName_R = $dbName + "_R"

WRITE-HOST " Database for R Services set to $dbName_R "

$dbName_Py = $dbName + "_Py"

WRITE-HOST " Database for Py Services set to $dbName_Py "



######################################################################## 
#Decide whether we are using Trusted or Non Trusted Connections. ........Currently this does not work..............
########################################################################

$trustedConnection = "Y"
##$trustedConnection = if ($Prompt -eq 'y' -or $Prompt -eq 'Y') {"Y"} ELSE {Read-Host  -Prompt "Use Trusted Connection? Type in 'Y' or 'N'"}
##$UserName = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter UserName"}
##$Password = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter Password" -AsSecureString} 



##########################################################################
#Set up SQL User Group for R 
##########################################################################
$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)
$si = if ($si -like '*\*') 
{
    $SN, $IN = $si.split('\')
    $SqlUser = $SN + '\SQLRUserGroup' + $IN
    if ((Get-SQLLogin -ServerInstance $si -LoginName $SQLUser -EA SilentlyContinue)) {
        Write-Host -ForegroundColor 'Cyan'  ''$SqlUser 'is already created in the Master Database'
    }
    ELSE { 
        Write-Host -ForegroundColor 'Cyan'  " Setting up SQLRUserGroup for Name Instance "
        $SN, $IN = $si.split('\')
        $Query = 'USE [master] CREATE LOGIN [' + $SN + '\SQLRUserGroup' + $IN + '] FROM WINDOWS WITH DEFAULT_DATABASE=[master]' 
        invoke-sqlcmd -serverinstance $ServerName -database [Master] -Query $Query 
    }
    Write-Host -ForegroundColor 'Cyan' " Giving SQLRUser Group access to  Name $Si "
}
ELSE {
    $SqlUser = $si + '\SQLRUserGroup'
    if ((Get-SQLLogin -ServerInstance $si -LoginName $SQLUser -EA SilentlyContinue)) { 
        Write-Host ''$SqlUser 'has already been given access to the Database' 
    }
    ELSE {
        write-host -ForegroundColor 'Cyan'  " Setting up SQLRUser Group for Default Instance"
        $Query = 'USE [master] CREATE LOGIN [' + $si + '\SQLRUserGroup] FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
        invoke-sqlcmd -serverinstance $ServerName -database [Master]-Query $Query 
    }
}

##########################################################################

# Create Database and BaseTables 

#########################################################################

####################################################################
# Check to see If SQL Version is at least SQL 2017 and Not SQL Express 
####################################################################


$query = 
"select 
        case 
            when 
                cast(left(cast(serverproperty('productversion') as varchar), 4) as numeric(4,2)) >= 14 
                and CAST(SERVERPROPERTY ('edition') as varchar) Not like 'Express%' 
            then 'Yes'
        else 'No' end as 'isSQL17'"

$isCompatible = Invoke-Sqlcmd -ServerInstance $ServerName -Database Master -Query $query
$isCompatible = $isCompatible.Item(0)
if ($isCompatible -eq 'Yes') {
    Write-Host " This Version of SQL is Compatible with SQL Py "

    ## Create Py Database
    Write-Host "  Creating SQL Database for Py "


    Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

    ## Create PY Server DB 
    $SqlParameters = @("dbName=$dbName_Py")

    $CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

    $CreateSQLObjects = "$ScriptPath\CreateSQLObjectsPy.sql"
    Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName_Py database") 
    invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


    Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName_Py Created")
    invoke-sqlcmd "USE $dbName_Py;" 

    Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName_Py database")
    invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName_Py


    Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName_Py Database")

    #### Give SqlUserGroup Acess to Py Database
    $si = if ($si -like '*\*') {
        {
            Write-Host -ForegroundColor 'Cyan' " Giving SQLRUser Group access to  Name $Si "
            $Query = 'USE [' + $dbName_Py + ']' + ' CREATE USER [' + $SN + '\SQLRUserGroup' + $IN + '] FOR LOGIN [' + $SN + '\SQLRUserGroup' + $IN + ']'
            invoke-sqlcmd -serverinstance $ServerName -database $dbName_Py -Query $Query 
        }
        ELSE 
        {
            write-host -ForegroundColor 'Cyan' " Giving SQLRUserGroup access to  $Si Database"
            $Query = 'USE [' + $dbName_Py + '] CREATE USER [SQLRUserGroup] FOR LOGIN [' + $si + '\SQLRUserGroup]'
            invoke-sqlcmd -serverinstance $si -database $dbName_Py -Query $Query }
    } 



}
Else 
{ "This Version of SQL is not compatible with Py , Py Code and DB's will not be Created "}




Write-Host "  Creating SQL Database for R "


Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

## Create RServer DB 
$SqlParameters = @("dbName=$dbName_R")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjectsR.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName_R database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName_R Created")
invoke-sqlcmd "USE $dbName_R;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName_R database")
invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName_R


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName_R Database")

#### Give SqlUserGroup Acess to R Database
$si = if ($si -like '*\*') {
    {
        Write-Host -ForegroundColor 'Cyan' " Giving SQLRUser Group access to  Name $Si "
        $Query = 'USE [' + $dbName_R + ']' + ' CREATE USER [' + $SN + '\SQLRUserGroup' + $IN + '] FOR LOGIN [' + $SN + '\SQLRUserGroup' + $IN + ']'
        invoke-sqlcmd -serverinstance $ServerName -database $dbName_R -Query $Query 
    }
    ELSE 
    {
        write-host -ForegroundColor 'Cyan' " Giving SQLRUserGroup access to  $Si Database"
        $Query = 'USE [' + $dbName_R + '] CREATE USER [SQLRUserGroup] FOR LOGIN [' + $si + '\SQLRUserGroup]'
        invoke-sqlcmd -serverinstance $si -database $dbName_R -Query $Query }
} 




Write-Host -ForeGroundColor cyan " Installing latest Power BI..."
# Download PowerBI Desktop installer
Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

# Silently install PowerBI Desktop
msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

if (!$?) {
    Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
}


##Create Shortcuts and Autostart Help File 
Copy-Item "$ScriptPath\SolutionHelp.url" C:\Users\Public\Desktop\
Copy-Item "$ScriptPath\SolutionHelp.url" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
Write-Host -ForeGroundColor cyan " Help Files Copied to Desktop"


###Copy PowerBI Reportt to Desktop 
Copy-Item  "$ScriptPath\*.pbix"  C:\Users\Public\Desktop\
Write-Host -ForeGroundColor cyan " PowerBI Reports Copied to Desktop"

###Configure Database for R 
Write-Host "  
        Configuring Solution for R
        "
  
#$ActionScipts =  C:\Solutions\Hospital\Resources\ActionScripts\CreateDatabaseR.ps1 -ServerName $ServerName -dbName $dbName_R -Prompt $Prompt 
$ActionScipts =  C:\Solutions\Hospital\SQLR\LoadandTrainData.ps1 -ServerName $ServerName -dbName $dbName_R -Prompt $Prompt 




###Conifgure Database for Py 
if ($isCompatible -eq 'Yes')
{
    Write-Host "  
        Configuring Solution for Py
        "
#$ActionScipts =  C:\Solutions\Hospital\Resources\ActionScripts\CreateDatabasePy.ps1 -ServerName $ServerName -dbName $dbName_Py -Prompt $Prompt 
$ActionScipts =  C:\Solutions\Hospital\SQLR\LoadandTrainData.ps1 -ServerName $ServerName -dbName $dbName_Py -Prompt $Prompt         
}



$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()


$endTime = Get-Date
Write-Host -ForegroundColor 'green'  " End time is:" $endTime


Write-Host -foregroundcolor 'green'(" Length of Stay Development Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 
Stop-Transcript

##Launch HelpURL 
Start-Process "https://microsoft.github.io/r-server-hospital-length-of-stay/Typical.html"

## Close Powershell 
Exit-PSHostProcess
EXIT 