[CmdletBinding()]
param(
[parameter(Mandatory=$true, Position=1, ParameterSetName = "DSVM")]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$true, Position=3, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$true, Position=4, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$password

)



$Prompt = 'N'


####Just adding a blank line 

$SolutionName = "Hospital"
$SolutionFullName = "r-server-hospital-length-of-stay" 
$odbcName = 'CampOpt'
### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "dev" 
$InstallPy = 'Yes' ## If Solution has a Py Version this should be 'Yes' Else 'No' 
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
$SolutionData = $SolutionPath + "\Data\"

##########################################################################
#Clone Data from GIT
##########################################################################


$clone = "git clone --branch $Branch --single-branch https://github.com/Microsoft/$SolutionFullName $solutionPath"

if (Test-Path $solutionTemplatePath) { Write-Host " Solution has already been cloned"}
ELSE {Invoke-Expression $clone}