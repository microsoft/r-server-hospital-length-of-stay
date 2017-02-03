<#
.SYNOPSIS
Script to load the data into SQL Server for the Hospital Length of Stay prediction. 
#>

[CmdletBinding()]
param(

[parameter(Mandatory=$true,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[String]    
$is_production = "",

[parameter(Mandatory=$true,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()] 
[String]    
$ServerName = "",

[parameter(Mandatory=$true,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()]
[String]
$DBName = "",

[parameter(Mandatory=$true,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()]
[String]
$username ="",


[parameter(Mandatory=$true,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()]
[String]
$password ="",

[parameter(Mandatory=$false,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()]
[String]
$dataPath = ""
)

$scriptPath = Get-Location
$filePath = $scriptPath.Path+ "\"
$error = $scriptPath.Path + "\output.log"

if ($dataPath -eq "")
{
$parentPath = Split-Path -parent $scriptPath
$dataPath = $parentPath + "/Data/"
}

##########################################################################
# Function wrapper to invoke SQL command
##########################################################################
function ExecuteSQL
{
param(
[String]
$sqlscript
)
    Invoke-Sqlcmd -ServerInstance $ServerName  -Database $DBName -Username $username -Password $password -InputFile $sqlscript -QueryTimeout 200000
}

##########################################################################
# Function wrapper to invoke SQL query
##########################################################################
function ExecuteSQLQuery
{
param(
[String]
$sqlquery
)
    Invoke-Sqlcmd -ServerInstance $ServerName  -Database $DBName -Username $username -Password $password -Query $sqlquery -QueryTimeout 200000
}

##########################################################################
# Check if the SQL server or database exists
##########################################################################
$query = "IF NOT EXISTS(SELECT * FROM sys.databases WHERE NAME = '$DBName') CREATE DATABASE $DBName"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $username -Password $password -Query $query -ErrorAction SilentlyContinue
if ($? -eq $false)
{
    Write-Host -ForegroundColor Red "Failed the test to connect to SQL server: $ServerName database: $DBName !"
    Write-Host -ForegroundColor Red "Please make sure: `n`t 1. SQL Server: $ServerName exists;
                                     `n`t 2. SQL database: $DBName exists;
                                     `n`t 3. SQL user: $username has the right credential for SQL server access."
    exit
}

$query = "USE $DBName;"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $username -Password $password -Query $query 


if($is_production -eq 'n' -or $is_production -eq 'N')
{

##########################################################################
# Loading the deployment data
##########################################################################
$startTime= Get-Date
Write-Host "Start time is:" $startTime
try{

        # create raw table
        Write-Host -ForeGroundColor 'green' ("Create SQL table.")
        $script = $filePath + "step0_create_table.sql"
        ExecuteSQL $script
    
        Write-Host -ForeGroundColor 'green' ("Populate SQL table.")
        $dataList = "LengthOfStay"
		
		# upload csv files into SQL tables
        foreach ($dataFile in $dataList)
        {
            $destination = $dataPath + $dataFile + ".csv"
            $tableName = $DBName + ".dbo." + $dataFile
            $tableSchema = $dataPath + $dataFile + ".xml"
            bcp $tableName format nul -c -x -f $tableSchema  -U $username -S $ServerName -P $password  -t ',' -e $error
            bcp $tableName in $destination -t ',' -S $ServerName -f $tableSchema -F 2 -C "RAW" -b 50000 -U $username -P $password -e $error
        }
    }
    catch
    {
        Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
        Write-Host -ForegroundColor Red $Error[0].Exception 
        throw
    }

    $query = "ALTER TABLE LengthOfStay ALTER COLUMN  vdate Date"
    ExecuteSQLQuery $query

    $query = "ALTER TABLE LengthOfStay ALTER COLUMN  discharged Date"
    ExecuteSQLQuery $query

}

    
  if($is_production -eq 'y' -or $is_production -eq 'Y')
{

##########################################################################
# Loading the production data
##########################################################################
$startTime= Get-Date
Write-Host "Start time is:" $startTime
try{

        # create raw table
        Write-Host -ForeGroundColor 'green' ("Create SQL table.")
        $script = $filePath + "create_tables_prod.sql"
        ExecuteSQL $script
    
        Write-Host -ForeGroundColor 'green' ("Populate SQL table.")
        $dataList = "LengthOfStay_Prod"
		
		# upload csv files into SQL tables
        foreach ($dataFile in $dataList)
        {
            $destination = $dataPath + $dataFile + ".csv"
            $tableName = $DBName + ".dbo." + $dataFile
            $tableSchema = $dataPath + $dataFile + ".xml"
            bcp $tableName format nul -c -x -f $tableSchema  -U $username -S $ServerName -P $password  -t ',' -e $error
            bcp $tableName in $destination -t ',' -S $ServerName -f $tableSchema -F 2 -C "RAW" -b 50000 -U $username -P $password -e $error
        }
    }
    catch
    {
        Write-Host -ForegroundColor DarkYellow "Exception in populating database tables:"
        Write-Host -ForegroundColor Red $Error[0].Exception 
        throw
    }

    $query = "ALTER TABLE LengthOfStay_Prod ALTER COLUMN  vdate Date"
    ExecuteSQLQuery $query

    $query = "ALTER TABLE LengthOfStay_Prod ALTER COLUMN  discharged Date"
    ExecuteSQLQuery $query

}


$endTime =Get-Date
$totalTime = ($endTime-$startTime).ToString()
Write-Host "Finished running at:" $endTime
Write-Host "Total time used: " -foregroundcolor 'green' $totalTime.ToString()

