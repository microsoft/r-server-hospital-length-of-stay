<#

.SYNOPSIS
 Script to create help short cut and solution folder shortcut.

 .PARAMETER helpfile
 path to the help url file.
 
.PARAMETER solutionPath
path to the solution folder with data and source.

#>
[CmdletBinding()]
param(
[parameter(Mandatory=$true, Position=1, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$helpfile,

[parameter(Mandatory=$true, Position=2, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$solutionPath,

[parameter(Mandatory=$true, Position=3, ParameterSetName = "LCR")]
[ValidateNotNullOrEmpty()] 
[string]$checkoutDir
)

# find the desktop 
$desktop = [Environment]::GetFolderPath("Desktop")

$desktop = $desktop + '\'


#create the help link in startup program 

$startmenu = [Environment]::GetFolderPath("StartMenu")
$startupfolder = $startmenu + '\Programs\Startup\'
# We create this since the user startup folder is only created after first login 
# Alternative is to add is to all user startup
mkdir $startupfolder
#copy 
$down = $helpfile
Write-Host $down
Write-Host $startmenu
ls $startmenu
Write-Host $startupfolder
ls $startupfolder
cp -Verbose $down $startupfolder
cp -Verbose $down $desktop

#create shortcut to solution folder on desktop
$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()