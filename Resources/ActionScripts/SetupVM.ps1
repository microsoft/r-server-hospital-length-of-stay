<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process. if you want to set the database back to the intial state 
run  Invoke-Expression C:\Solutions\Hospital\Resources\ActionScripts\createdatabase.ps1 from a elevated PS window. 
#>
$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime= Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time:" $startTime 


$solutionTemplateName = "Solutions" #change this back to Solutions after done testing 
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = "Hospital"
$SolutionPath = $solutionTemplatePath +'\' + $checkoutDir



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


$endTime= Get-Date
Write-Host -ForegroundColor 'green'  " End time is:" $endTime


Write-Host -foregroundcolor 'green'(" Length of Stay Development Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 
Stop-Transcript