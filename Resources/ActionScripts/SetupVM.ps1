<#
.SYNOPSIS
Powershell script for setting up the solution template. 

.DESCRIPTION
This script checks out the solution from github and deploys it to SQL Server on the local Data Science VM (DSVM).

#>
$setupLog = "c:\tmp\setup_log.txt"
Start-Transcript -Path $setupLog -Append
$startTime= Get-Date
Write-Host -ForegroundColor 'Green'  "  Start time:" $startTime 


$solutionTemplateName = "Solutions"
$solutionTemplatePath = "C:\" + $solutionTemplateName
$checkoutDir = "Hospital"
$SolutionPath = $solutionTemplatePath +'\' + $checkoutDir
$desktop = "C:\Users\Public\Desktop\"
$scriptPath =  $SolutionPath + "Resources\ActionScripts\"



### DON'T FORGET TO CHANGE TO MASTER LATER...

if (Test-Path $solutionTemplatePath) 
{
Write-Host " Solution has already been cloned"
}
ELSE   
{
    git clone  --branch dev --single-branch https://github.com/Microsoft/r-server-hospital-length-of-stay $solutionPath
}

##DSVM Does not have SQLServer Powershell Module , this will try and install it if it is not present it will work , if it is already there it will error out 
Write-Host " Installing SQLServer Power Shell Module , if it is already installed a warning will be displayed , this is OK........."
Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
Import-Module -Name SQLServer


Write-Host -ForeGroundColor cyan " Installing latest Power BI..."
# Download PowerBI Desktop installer
Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi

# Silently install PowerBI Desktop
msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1

if (!$?)
{
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
$ActionScripts = $SolutionPath + "\Resources\ActionScripts\CreateDatabase.ps1"
Invoke-Expression $ActionScripts

###Conifgure Database for Py 
Write-Host "  
        Configuring Solution for Py
        "
$ActionScripts = $SolutionPath + "\Resources\ActionScripts\CreateDatabasePy.ps1"
Invoke-Expression $ActionScripts

$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()


$endTime= Get-Date
Write-Host -ForegroundColor 'green'  " End time is:" $endTime


Write-Host -foregroundcolor 'green'(" Length of Stay Development Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 
Stop-Transcript

## Close Powershell 
Exit-PSHostProcess
EXIT 