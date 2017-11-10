<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

.WARNING: This script is only meant to be run from the solution template deployment process.
#>

$solutionTemplateName = "Solutions" #change this back to Solutions after done testing 
$solutionTemplatePath = "C:\" + $solutionTemplateName
$solutionTemplatePath

$checkoutDir = "Hospital"

### DON'T FORGET TO CHANGE TO MASTER LATER...
git clone  --branch dev --single-branch https://github.com/Microsoft/r-server-hospital-length-of-stay $solutionTemplatePath

#git clone https://github.com/Microsoft/r-server-hospital-length-of-stay $solutionTemplatePath

Invoke-Expression C:\Solutions\Hospital\Resources\ActionScripts\createdatabase.ps1