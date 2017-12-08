$Prompt = 'N'
$SolutionName = "Hospital"

$Query = "SELECT SERVERPROPERTY('ServerName')"
$si = invoke-sqlcmd -Query $Query
$si = $si.Item(0)



$ServerName = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter SQL Server Name Or SQL InstanceName you are installing on"} else {$si}


WRITE-HOST " ServerName set to $ServerName"

$db = if ($Prompt -eq 'Y') {Read-Host  -Prompt "Enter Desired Database Base Name"} else {$SolutionName} 








##########################################################################

# Create Database and BaseTables 

#########################################################################

####################################################################
# Check to see If SQL Version is at least SQL 2017 and Not SQL Express 
####################################################################


$query = 
"select 
        case 
            when 
                cast(left(cast(serverproperty('productversion') as varchar), 4) as numeric(4,2)) >= 14 
                and CAST(SERVERPROPERTY ('edition') as varchar) Not like 'Express%' 
            then 'Yes'
        else 'No' end as 'isSQL17'"

$isCompatible = Invoke-Sqlcmd -ServerInstance $ServerName -Database Master -Query $query
$isCompatible = $isCompatible.Item(0)
if ($isCompatible -eq 'Yes' -and $InstallPy -eq 'Yes') {
    Write-Host " This Version of SQL is Compatible with SQL Py "

    ## Create Py Database
    Write-Host "  Creating SQL Database for Py "


    Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

    ## Create PY Server DB
    $dbName = $db + "_Py"
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

 ## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $odbcName -DriverName "SQL Server Native Client 11.0" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru




}
Else 
{ "This Version of SQL is not compatible with Py , Py Code and DB's will not be Created "}




Write-Host "  Creating SQL Database for R "


Write-Host -ForeGroundColor 'cyan' (" Using $ServerName SQL Instance") 

$dbName = $db + "_R"


## Create RServer DB 
$SqlParameters = @("dbName=$dbName")

$CreateSQLDB = "$ScriptPath\CreateDatabase.sql"

$CreateSQLObjects = "$ScriptPath\CreateSQLObjectsR.sql"
Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the  $dbName database") 
invoke-sqlcmd -inputfile $CreateSQLDB -serverinstance $ServerName -database master -Variable $SqlParameters


Write-Host -ForeGroundColor 'cyan' (" SQLServerDB $dbName Created")
invoke-sqlcmd "USE $dbName;" 

Write-Host -ForeGroundColor 'cyan' (" Calling Script to create the objects in the $dbName database")
invoke-sqlcmd -inputfile $CreateSQLObjects -serverinstance $ServerName -database $dbName


Write-Host -ForeGroundColor 'cyan' (" SQLServerObjects Created in $dbName Database")


###Configure Database for R 
Write-Host "  
Configuring $SolutionName Solution for R
"

$dbName = $db + "_R" 

## Create ODBC Connection for PowerBI to Use 
Add-OdbcDsn -Name $odbcName -DriverName "SQL Server Native Client 11.0" -DsnType 'System' -Platform '64-bit' -SetPropertyValue @("Server=$ServerName", "Trusted_Connection=Yes", "Database=$dbName") -ErrorAction SilentlyContinue -PassThru

##########################################################################
# Deployment Pipeline
##########################################################################


try
{

Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
$dataList = "LengthOfStay"


# upload csv files into SQL tables
foreach ($dataFile in $dataList)
{
$destination = $SolutionData + $dataFile + ".csv" 
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

Write-Host -ForeGroundColor 'Cyan' (" Scoring and Training Data...")
$query = "EXEC Exec_Inital_RScoring"
#SqlServer\Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0
SqlServer\Invoke-Sqlcmd -ServerInstance LocalHost -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0





###Conifgure Database for Py 
if ($isCompatible -eq 'Yes'-and $InstallPy -eq 'Yes')
{
Write-Host "  
Configuring $SolutionName Solution for Py
# "
$dbname = $db + "_Py"
# $ActionScript = $solutionPath + "\SQLPy\LoadandTrainData.ps1 -ServerName $ServerName -dbName $dbName -Prompt $Prompt"
# Invoke-Expression $ActionScript 

##########################################################################
# Deployment Pipeline
##########################################################################


try
{

Write-Host -ForeGroundColor 'cyan' (" Import CSV File(s).")
$dataList = "LengthOfStay"


# upload csv files into SQL tables
foreach ($dataFile in $dataList)
{
    $destination = $SolutionData + $dataFile + ".csv" 
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

Write-Host -ForeGroundColor 'Cyan' (" Scoring and Training Data...")
$query = "Exec Exec_Inital_PyScoring"
SqlServer\Invoke-Sqlcmd -ServerInstance LocalHost -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0
#SqlServer\Invoke-Sqlcmd -ServerInstance $ServerName -Database $dbName -Query $query -ConnectionTimeout  0 -QueryTimeout 0

##SqlServer\Invoke-Sqlcmd  -Database $DbName -Query "EXEC Execute_Yourself" -QueryTimeout 0 -ServerInstance $ServerName


}