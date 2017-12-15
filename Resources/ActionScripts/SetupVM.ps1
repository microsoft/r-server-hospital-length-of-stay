

[CmdletBinding()]
param(
[parameter(Mandatory=$false, Position=1)]
[ValidateNotNullOrEmpty()] 
[string]$serverName,

[parameter(Mandatory=$false, Position=2)]
[ValidateNotNullOrEmpty()] 
[string]$username,

[parameter(Mandatory=$false, Position=3)]
[ValidateNotNullOrEmpty()] 
[string]$password,

[parameter(Mandatory=$false, Position=4)]
[ValidateNotNullOrEmpty()] 
[string]$Prompt
)
$startTime = Get-Date



#$Prompt= if ($Prompt -match '^y(es)?$') {'Y'} else {'N'}
$Prompt = 'N'



$SolutionName = "Hospital"
$SolutionFullName = "r-server-hospital-length-of-stay" 
$JupyterNotebook = "Hospital_Length_Of_Stay_Notebook.ipynb"
$odbcName = 'CampOpt'
### DON'T FORGET TO CHANGE TO MASTER LATER...
$Branch = "dev" 
$InstallPy = 'Yes' ## If Solution has a Py Version this should be 'Yes' Else 'No'
$SampleWeb = 'Yes' ## If Solution has a Sample Website  this should be 'Yes' Else 'No'  
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


##$Query = "SELECT SERVERPROPERTY('ServerName')"
##$si = invoke-sqlcmd -Query $Query
##$si = $si.Item(0)


###$serverName = if($serverName -eq $null) {$si}

##WRITE-HOST " ServerName set to $ServerName"



##########################################################################
#Clone Data from GIT
##########################################################################


$clone = "git clone --branch $Branch --single-branch https://github.com/Microsoft/$SolutionFullName $solutionPath"

if (Test-Path $solutionTemplatePath) { Write-Host " Solution has already been cloned"}
ELSE {Invoke-Expression $clone}

#################################################################
##DSVM Does not have SQLServer Powershell Module Install or Update 
#################################################################



Write-Host " Installing SQLServer Power Shell Module or Updating to latest "

if (Get-Module -ListAvailable -Name SQLServer) {Update-Module -Name "SQLServer"}
 else 
    {
    Install-Module -Name SQLServer -Scope AllUsers -AllowClobber -Force
    Import-Module -Name SQLServer
    }



############################################################################################
#Configure SQL to Run our Solutions 
############################################################################################

#Write-Host -ForegroundColor 'Cyan' " Switching SQL Server to Mixed Mode"


### Change Authentication From Windows Auth to Mixed Mode 
Invoke-Sqlcmd -Query "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2;" -ServerInstance "LocalHost" 

Write-Host -ForeGroundColor 'cyan' " Configuring SQL to allow running of External Scripts "
### Allow Running of External Scripts , this is to allow R Services to Connect to SQL
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


$Query = "CREATE LOGIN $username WITH PASSWORD=N'$password', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
Invoke-Sqlcmd -Query $Query

$Query = "ALTER SERVER ROLE [sysadmin] ADD MEMBER $username"
Invoke-Sqlcmd -Query $Query



Write-Host -ForegroundColor 'Cyan' " Done with configuration changes to SQL Server"

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

$WsShell = New-Object -ComObject WScript.Shell
$shortcut = $WsShell.CreateShortcut($desktop + $checkoutDir + ".lnk")
$shortcut.TargetPath = $solutionPath
$shortcut.Save()

$ConfigureSql = "C:\Solutions\Hospital\Resources\ActionScripts\ConfigureSQL.ps1  $ServerName $SolutionName $InstallPy $Prompt"
Invoke-Expression $ConfigureSQL 

#powershell.exe -ExecutionPolicy Unrestricted -File C:\Solutions\Hospital\Resources\ActionScripts\ConfigureSQL.ps1 -serverName $serverName -SolutionName $SolutionName 



## copy Jupyter Notebook files
Move-Item $SolutionPath\R\$JupyterNotebook  c:\tmp\
sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\$JupyterNotebook
sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\$JupyterNotebook
Move-Item  c:\tmp\$JupyterNotebook $SolutionPath\R\




#cp $SolutionData*.csv  c:\dsvm\notebooks
 # substitute real username and password in notebook file
#XXXXXXXXXXChange to NEw NotebookNameXXXXXXXXXXXXXXXXXX# 

if ($InstallPy -eq "Yes")
{
    Move-Item $SolutionPath\Python\$JupyterNotebook  c:\tmp\
    sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\$JupyterNotebook
    sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\$JupyterNotebook
    Move-Item  c:\tmp\$JupyterNotebook $SolutionPath\Python\
}

# install modules for sample website
if($SampleWeb  -eq "Yes")
{
cd $SolutionPath\Website\
npm install
Move-Item $SolutionPath\Website\server.js  c:\tmp\
sed -i "s/XXYOURSQLPW/$password/g" c:\tmp\server.js
sed -i "s/XXYOURSQLUSER/$username/g" c:\tmp\server.js
Move-Item  c:\tmp\server.js $SolutionPath\Website
}

$endTime = Get-Date

Write-Host -foregroundcolor 'green'(" Length of Stay Development Workflow Finished Successfully!")
$Duration = New-TimeSpan -Start $StartTime -End $EndTime 
Write-Host -ForegroundColor 'green'(" Total Deployment Time = $Duration") 

Stop-Transcript


##Launch HelpURL 
Start-Process "https://microsoft.github.io/r-server-hospital-length-of-stay/Typical.html"




## Close Powershell 
Exit-PSHostProcess
EXIT 