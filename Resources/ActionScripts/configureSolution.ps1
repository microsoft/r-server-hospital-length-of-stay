<#
.SYNOPSIS 
Script to invoke the solution workflow

.DESCRIPTION
is script creates the SQL Server user and uses it to create the database.

.WARNING
This script should only be run once through the template deployment process. It is
not meant to be run by users as it assumes database and users don't already exist.

.PARAMETER scriptdir
directory where scripts are checked out from github

.PARAMETER sqlUsername
User to create in SQL Server

.PARAMETER sqlPassword
Password for the SQL User

.PARAMETER dbname
Name of the database to create in SQL Server
#>
[CmdletBinding()]
Param(
[parameter(Mandatory=$true, Position=1, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$basedir,

[parameter(Mandatory=$true, Position=2, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$sqlUsername,

[parameter(Mandatory=$true, Position=3, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$sqlPassword,

[parameter(Mandatory=$false, Position=4, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$dbname="Fraud"
)

$scriptdir = $basedir + '/SQLR'
# Change SQL Server to mixed mode authentication
### Check and see if SQL Service is Running , if not start it 

Write-Host -ForegroundColor 'Cyan' "Switch SQL Server to Mixed Mode"
$ServiceName = 'MSSQLSERVER'
$arrService = Get-Service -Name $ServiceName
if ($arrService.Status -ne "Running"){
    Start-Service $ServiceName}

### Change Authentication From Windows Auth to Mixed Mode 
Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 

### Stop the SQL Service 
Stop-Service -Force $ServiceName

### Start the SQL Service 
Start-Service $ServiceName

### Start SQL Launch Pad and SQL Server Agent as this is Dependent on the SQL Service and is stopped with -force
Start-Service MSSQLLaunchpad
Start-Service SQLSERVERAGENT
Write-Host -ForegroundColor 'Cyan' "Done switching SQL Server to Mixed Mode"

cd $scriptdir
# create the database user
Write-Host -ForegroundColor 'Cyan' "Creating database user"

# Variables to pass to createuser.sql script
# Cannot use -v option as sqlcmd does not like special characters which maybe part of the randomly generated password.
$sqlcmdvars = @{"username" = "$sqlUsername"; "password" = "$sqlPassword"}
$old_env = @{}

foreach ($var in $sqlcmdvars.GetEnumerator()) {
    # Save Environment
    $old_env.Add($var.Name, [Environment]::GetEnvironmentVariable($var.Value, "User"))
    [Environment]::SetEnvironmentVariable($var.Name, $var.Value)
}
try {
    #sqlcmd -S $env:COMPUTERNAME -b -i .\createuser.sql
    Invoke-Sqlcmd -ServerInstance $env:COMPUTERNAME -InputFile .\createuser.sql
} catch {
    Write-Host -ForegroundColor 'Yellow' "Error creating database user, see error message output"
    Write-Host -ForegroundColor 'Red' $Error[0].Exception 
} finally {
    # Restore Environment
    foreach ($var in $old_env.GetEnumerator()) {
        [Environment]::SetEnvironmentVariable($var.Name, $var.Value)
    }
}
Write-Host -ForegroundColor 'Cyan' "Done creating database user"


# Run the solution.\Length_Of_Stay.ps1 -ServerName localhost -DBName $dbname -username $sqlUsername -password $sqlPassword
.\Length_of_Stay.ps1 -ServerName $env:COMPUTERNAME -DBName $dbname -username $sqlUsername -password sqlPassword  -uninterrupted "Y" -is_production "N"
 

# copy Jupyter Notebook files
cp $basedir\R\*.ipynb  c:\dsvm\notebooks
cp $basedir\Data\*.csv  c:\dsvm\notebooks
#  substitute real username and password in notebook file
#XXXXXXXXXXChange to NEw NotebookNameXXXXXXXXXXXXXXXXXX# 
sed -i "s/XXYOURSQLPW/$sqlPassword/g" c:\dsvm\notebooks\Hospital_Length_Of_Stay_Notebook.ipynb
sed -i "s/XXYOURSQLUSER/$sqlUsername/g" c:\dsvm\notebooks\Hospital_Length_Of_Stay_Notebook.ipynb

