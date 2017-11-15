<#

This Script will install the Database and do the First run of scoring the data.
This can be run at anytime and will refresh teh Database to the initial state 
It is conifgured for default settings ie Creating the Hospital Database in the SQL Server 
If you want to choose a different database name , you can call this script from a ps cmd line using this cmd  ./CreateDatabase.ps1 -PromptedInstall Y
or run the script from this window.
Created on 10.5.2017 Bob White  
#>

param 
(
[Parameter(Mandatory=$false)] [String] $PromptedInstall  =  "",

[Parameter(Mandatory=$false)] [String] $ServerName  =  "",

[Parameter(Mandatory=$false)] [String] $dbName  =  ""
)




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
#Check Install Type Prompted Or Not Prompted, Not Prompted is Default
########################################################################
$Prompt = $PromptedInstall

#$Prompt = 'Y'
$Prompt = 
        if ($Prompt -eq 'Y' -or $Prompt -eq 'y') {'Y'} 
        elseif ([string]::IsNullOrEmpty($Prompt) -or $Prompt -eq 'N' -or $Prompt -eq 'n' ) {'N'}  
######################################################################## 
# If Prompted Install is Invoked, Prompt For SQLServer and dbName
########################################################################

$ServerName = if ([string]::IsNullOrEmpty($ServerName) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {Read-Host  -Prompt "Enter Desired SQL Server Name"} 
                elseif ((![string]::IsNullOrEmpty($ServerName)) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {$ServerName}
                else {"LOCALHOST"}

$dbName = if ([string]::IsNullOrEmpty($dbName) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {Read-Host  -Prompt "Enter Desired Database Name"} 
            elseif ((![string]::IsNullOrEmpty($dbName)) -and ($Prompt -eq 'Y' -Or $Prompt -eq 'y')) {$dbName}
            else {"Hospital"} 


$dbName = $dbName + "_py" 

######################################################################## 
#Decide whether we are using Trusted or Non Trusted Connections. ........Currently this does not work..............
########################################################################

$trustedConnection = "Y"
##$trustedConnection = if ($Prompt -eq 'y' -or $Prompt -eq 'Y') {"Y"} ELSE {Read-Host  -Prompt "Use Trusted Connection? Type in 'Y' or 'N'"}
##$UserName = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter UserName"}
##$Password = if ($trustedConnection -eq 'n' -or $trustedConnection -eq 'N') {Read-Host  -Prompt "Enter Password" -AsSecureString} 
 

 


 ##$ServerName = "LOCALHOST"
 $basePath = "c:\Solutions\Hospital\"
 $dataPath = $basePath+ "Data"
 $scriptPath =  $basePath + "Resources\ActionScripts\"
 $SqlPath = $basePath + "SQLR\"
 

##########################################################################

# Create Database and BaseTables 

#########################################################################

Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

## Create py DB 
$SqlParameters = @("dbName=$dbName")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjectsPy.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName Created")
invoke-sqlcmd "USE $dbName;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName database")
invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName Database")






#########################################################################
### Enable implied Authentication for the Launchpad group
#########################################################################

    Write-Host -ForeGroundColor cyan " Installing latest Power BI..."
    # Download PowerBI Desktop installer
    Start-BitsTransfer -Source "https://go.microsoft.com/fwlink/?LinkId=521662&clcid=0x409" -Destination powerbi-desktop.msi
    
    # Silently install PowerBI Desktop
    msiexec.exe /i powerbi-desktop.msi /qn /norestart  ACCEPT_EULA=1
    
    if (!$?)
    {
        Write-Host -ForeGroundColor Red " Error installing Power BI Desktop. Please install latest Power BI manually."
    }

    write-host -ForegroundColor 'Green' " SQL Server has been configured, now load and train data...." 
    
##########################################################################
# Deployment Pipeline
##########################################################################
##Create Shortcuts and Autostart Help File 
    Copy-Item "$ScriptPath\SolutionHelp.url" C:\Users\Public\Desktop\
    Copy-Item "$ScriptPath\SolutionHelp.url" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\"
    Write-Host -ForeGroundColor cyan " Help Files Copied to Desktop"

    


###Copy PowerBI Reportt to Desktop 
  Copy-Item  "$ScriptPath\*.pbix"  C:\Users\Public\Desktop\
  Write-Host -ForeGroundColor cyan " PowerBI Reports Copied to Desktop"


   try
       {
    
        Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
        $dataList = "LengthOfStay"

		
		# upload csv files into SQL tables
        foreach ($dataFile in $dataList)
        {
            $destination = $dataPath + "\" + $dataFile + ".csv" 
            $tableName = $DBName + ".dbo." + $dataFile
            $tableSchema = $dataPath + "\" + $dataFile + ".xml"
            $dataSet = Import-Csv $destination
         Write-Host -ForegroundColor 'cyan' ("         Loading $dataFile.csv into SQL Table, this will take about 30 seconds per file....") 
            Write-SqlTableData -InputData $dataSet  -DatabaseName $dbName -Force -Passthru -SchemaName dbo -ServerInstance $ServerName -TableName $dataFile
 
            
         Write-Host -ForeGroundColor 'cyan' (" $datafile table loaded from CSV File(s).")
        }
    }
    catch
    {
        Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
        Write-Host -ForegroundColor Red $Error[0].Exception 
        throw
    }
    Write-Host -ForeGroundColor 'cyan' (" Finished loading .csv File(s).")
   

    # compute statistics for production and faster NA replacement.
    Write-Host -ForeGroundColor 'Cyan' (" Computing statistics on the input table...")
    $query = "EXEC compute_stats"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
        #ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Credential $Credential  -Query $query}
    

    # execute the NA replacement
    $Replace = if ($Prompt -eq 'y' -or $Prompt -eq 'Y') 
        {Read-Host -Prompt " Replacing missing values with mode and mean [M/m] or with missing and -1 [miss]?' Type in 'Y' or 'N' "}
        ELSE {"N"}
    if ($Replace -eq 'Y' -or $Replace -eq 'y') {Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with the mean and mode...")}
                    ELSE {Write-Host -ForeGroundColor 'Cyan' (" Not Replacing missing values with the mean and mode...")}
            
    $query = if ($Replace -eq 'N' -or $Replace -eq 'n') {"EXEC fill_NA_mode_mean 'LengthOfStay', 'LoS0'"}  ELSE {"EXEC fill_NA_explicit 'LengthOfStay', 'LoS0'"} 
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
  

    # execute the feature engineering
    Write-Host -ForeGroundColor 'Cyan' (" Computing new features...")
    $query = "EXEC feature_engineering 'LoS0', 'LoS', 0"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}

    # get the column information
    Write-Host -ForeGroundColor 'Cyan' (" Getting column information...")
    $query = "EXEC get_column_info 'LoS'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
    

    # execute the procedure
    #$splitting_percent = 70
    $splitting_percent = if ($Prompt -eq 'n' -or $Prompt -eq 'N') {"70"} ELSE {Read-Host ' Split Percent (e.g. Type 70 for 70% in training set) ?'}
    Write-Host -ForeGroundColor 'Cyan' (" Splitting the data set at $splitting_percent%...")
    $query = "EXEC splitting $splitting_percent, 'LoS'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}


    ### Gradient Boosted Training  

    # execute the training 
    Write-Host -ForeGroundColor 'Cyan' (" Training Gradient Boosted Trees (rxFastTrees implementation)...")
    $modelName = 'GBT'
    $query = "EXEC train_model $modelName, 'LoS'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
     

   # execute the scoring 
   Write-Host -ForeGroundColor 'Cyan' (" Scoring Gradient Boosted Trees (rxFastTrees implementation)...")
   $query = "EXEC score $modelName, 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)', 'Boosted_Prediction'"
   if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
       {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
       ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database  $dbName -User $UserName -Password $Password  -Query $query}


    # execute the evaluation 
    Write-Host -ForeGroundColor 'Cyan' (" Evaluating Gradient Boosted Trees (rxFastTrees implementation)... ...")
    $query = "EXEC evaluate $modelName, 'Boosted_Prediction'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
   

   
    Write-Host -ForeGroundColor 'Cyan' (" Execute Prediction Results ...")
    $query = "EXEC prediction_results"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}


        ### Forrest Prediction  

    # execute the training 
    Write-Host -ForeGroundColor 'Cyan' (" Training Forrest Prediction  ...")
    $modelName = 'RF'
    $query = "EXEC train_model $modelName, 'LoS'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
     

   # execute the scoring 
   Write-Host -ForeGroundColor 'Cyan' (" Scoring Forrest Prediction ...")
   $query = "EXEC score $modelName, 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)', 'Boosted_Prediction'"
   if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
       {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
       ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database  $dbName -User $UserName -Password $Password  -Query $query}


    # execute the evaluation 
    Write-Host -ForeGroundColor 'Cyan' (" Evaluating Forrest Prediction... ...")
    $query = "EXEC evaluate $modelName, 'Forest_Prediction'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}


            ### Fast Prediction  

    # execute the training 
    Write-Host -ForeGroundColor 'Cyan' (" Training Fast Prediction   ...")
    $modelName = 'FT'
    $query = "EXEC train_model $modelName, 'LoS'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
     

   # execute the scoring 
   Write-Host -ForeGroundColor 'Cyan' (" Scoring Fast Prediction  ...")
   $query = "EXEC score $modelName, 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)', 'Boosted_Prediction'"
   if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
       {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
       ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database  $dbName -User $UserName -Password $Password  -Query $query}


    # execute the evaluation 
    Write-Host -ForeGroundColor 'Cyan' (" Evaluating Fast Prediction ... ...")
    $query = "EXEC evaluate $modelName, 'Fast_Prediction'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
 
        
        
            ### NN_Prediction 

    # execute the training 
    Write-Host -ForeGroundColor 'Cyan' (" Training NN Prediction    ...")
    $modelName = 'NN'
    $query = "EXEC train_model $modelName, 'LoS'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}
     

   # execute the scoring 
   Write-Host -ForeGroundColor 'Cyan' (" Scoring NN Prediction  ...")
   $query = "EXEC score $modelName, 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)', 'Boosted_Prediction'"
   if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
       {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
       ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database  $dbName -User $UserName -Password $Password  -Query $query}


    # execute the evaluation 
    Write-Host -ForeGroundColor 'Cyan' (" Evaluating NN Prediction ... ...")
    $query = "EXEC evaluate $modelName, 'NN_Prediction'"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}

   
    Write-Host -ForeGroundColor 'Cyan' (" Execute Prediction Results ...")
    $query = "EXEC prediction_results"
    if($trustedConnection -eq 'Y' -or $trustedConnection -eq 'y') 
        {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query}
        ELSE {Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -User $UserName -Password $Password  -Query $query}


    
 
