<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process.

.PARAMETER serverName
Name of the server with SQL Server with R Services (this is the DSVM server)

.PARAMETER baseurl
url from which to download data files (if any)

.PARAMETER username
login username for the server

.PARAMETER password
login password for the server

.PARAMETER sqlUsername
User to create in SQL Server

.PARAMETER sqlPassword
Password for the SQL User

#>
[CmdletBinding()]
param(
[parameter(Mandatory=$true, Position=1, ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$true, Position=2, ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[string]$baseurl,

[parameter(Mandatory=$true, Position=3, ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$true, Position=4, ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[string]$password,

[parameter(Mandatory=$true, Position=5, ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[string]$sqlUsername,

[parameter(Mandatory=$true, Position=6, ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[string]$sqlPassword
)

$startTime= Get-Date
Write-Host "Start time for setup is:" $startTime
$originalLocation = Get-Location
# This is the directory for the data/code download
$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = "Hospital"

New-Item -Path "C:\" -Name $solutionTemplateName -ItemType directory -force

$setupLog = $solutionTemplatePath + "\setup_log.txt"
Start-Transcript -Path $setupLog -Append

cd $solutionTemplatePath
### DON'T FORGET TO CHANGE TO MASTER LATER...
git clone  --branch Dev --single-branch https://github.com/Microsoft/r-server-hospital-length-of-stay $checkoutDir


$solutionBase = $solutionTemplatePath + "\" + $checkoutDir 
$solutionResourcePath = $solutionBase + "\Resources\ActionScripts"
$helpShortCutFilePath = $solutionResourcePath + "\SolutionHelp.url"

cd $solutionResourcePath

$passwords = $password | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$serverName\$username", $passwords)
$configure = "configureSolution.ps1"
$shortcuts ="createShortcuts.ps1"

Enable-PSRemoting -Force
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $configure -ArgumentList $solutionBase, $sqlUsername, $sqlPassword, $checkoutDir
Invoke-Command  -Credential $credential -ComputerName $serverName -FilePath $shortcuts -ArgumentList $helpShortCutFilePath, $solutionBase, $checkoutDir
Disable-PSRemoting -Force

Write-Host -ForeGroundColor magenta "Installing latest Power BI..."
# Download PowerBI Desktop installer
Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

# Silently install PowerBI Desktop
msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

if (!$?)
{
    Write-Host -ForeGroundColor Red "Error installing Power BI Desktop. Please install latest Power BI manually."
}
cd $originalLocation.Path
$endTime= Get-Date
$totalTime = $endTime - $startTime
Write-Host "Finished running setup at " $endTime
Write-Host "Total time for setup:" $totalTime
Stop-Transcript

