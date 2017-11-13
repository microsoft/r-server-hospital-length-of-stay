<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process. if you want to set the database back to the intial state 
run  Invoke-Expression C:\Solutions\Hospital\Resources\ActionScripts\createdatabase.ps1 from a elevated PS window. 
#>

$solutionTemplateName = "Solutions" #change this back to Solutions after done testing 
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = "Hospital"
$SolutionPath = $solutionTemplatePath +'\' + $checkoutDir

$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append

### DON'T FORGET TO CHANGE TO MASTER LATER...

if (Test-Path $solutionTemplatePath) 
{
Write-Host " Solution has already been cloned"
}
ELSE   
{
    git clone  --branch dev --single-branch https://github.com/Microsoft/r-server-hospital-length-of-stay $solutionPath
}
$ActionScripts = $SolutionPath + "\Resources\ActionScripts\CreateDatabase.ps1"
Invoke-Expression $ActionScripts