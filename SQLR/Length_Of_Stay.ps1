<#
.SYNOPSIS
Script to predict the length of stay for patients in a hospital, using SQL Server and MRS. 
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

[parameter(Mandatory=$true,ParameterSetName = "LoS")]
[ValidateNotNullOrEmpty()]
[String]
$uninterrupted="",

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
# Check if the SQL server exists
##########################################################################
$query = "IF NOT EXISTS(SELECT * FROM sys.databases WHERE NAME = '$DBName') CREATE DATABASE $DBName"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $username -Password $password -Query $query -ErrorAction SilentlyContinue
if ($? -eq $false)
{
    Write-Host -ForegroundColor Red "Failed the test to connect to SQL server: $ServerName database: $DBName !"
    Write-Host -ForegroundColor Red "Please make sure: `n`t 1. SQL Server: $ServerName exists;
                                     `n`t 2. SQL user: $username has the right credential for SQL server access."
    exit
}

$query = "USE $DBName;"
Invoke-Sqlcmd -ServerInstance $ServerName -Username $username -Password $password -Query $query 

##########################################################################

# Uninterrupted

##########################################################################
$startTime= Get-Date
Write-Host "Start time is:" $startTime  

if ($uninterrupted -eq 'y' -or $uninterrupted -eq 'Y')
{
    if($is_production -eq 'n' -or $is_production -eq 'N')
    {
    
##########################################################################
# Deployment Pipeline
##########################################################################
   try
       {

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

    # create the stored procedures for preprocessing
    $script = $filepath + "step1_data_processing.sql"
    ExecuteSQL $script

    # compute statistics for production and faster NA replacement.
    Write-Host -ForeGroundColor 'Cyan' (" Computing statistics on the input table...")
    $query = "EXEC compute_stats"
    ExecuteSQLQuery $query

    # execute the NA replacement
    Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with the mean and mode...")
    $query = "EXEC fill_NA_mode_mean 'LengthOfStay', 'LoS0'"
    ExecuteSQLQuery $query

    # create the stored procedure for feature engineering and getting column information.
    $script = $filepath + "step2_feature_engineering.sql"
    ExecuteSQL $script

    # execute the feature engineering
    Write-Host -ForeGroundColor 'Cyan' (" Computing new features...")
    $query = "EXEC feature_engineering 'LoS0', 'LoS', 0"
    ExecuteSQLQuery $query

    # get the column information
    Write-Host -ForeGroundColor 'Cyan' (" Getting column information...")
    $query = "EXEC get_column_info 'LoS'"
    ExecuteSQLQuery $query

    # create the stored procedure for splitting into train and test data sets
    $script = $filepath + "step3a_splitting.sql"
    ExecuteSQL $script

    # execute the procedure
    $splitting_percent = 70
    Write-Host -ForeGroundColor 'Cyan' (" Splitting the data set...")
    $query = "EXEC splitting $splitting_percent, 'LoS'"
    ExecuteSQLQuery $query

    # create the stored procedure for training 
    $script = $filepath + "step3b_training.sql"
    ExecuteSQL $script

    # execute the training 
    Write-Host -ForeGroundColor 'Cyan' (" Training Gradient Boosted Trees (rxFastTrees implementation)...")
    $modelName = 'GBT'
    $query = "EXEC train_model $modelName, 'LoS'"
    ExecuteSQLQuery $query
     
    # create the stored procedure for predicting 
    $script = $filepath + "step3c_scoring.sql"
    ExecuteSQL $script

    # execute the scoring 
    Write-Host -ForeGroundColor 'Cyan' (" Scoring Gradient Boosted Trees (rxFastTrees implementation)...")
    $query = "EXEC score $modelName, 'SELECT * FROM LoS WHERE eid NOT IN (SELECT eid FROM Train_Id)', 'Boosted_Prediction'"
    ExecuteSQLQuery $query

    # create the stored procedure for evaluation
    $script = $filepath + "step3d_evaluating.sql"
    ExecuteSQL $script

    # execute the evaluation 
    Write-Host -ForeGroundColor 'Cyan' (" Evaluating Gradient Boosted Trees (rxFastTrees implementation) ...")
    $query = "EXEC evaluate $modelName, 'Boosted_Prediction'"
    ExecuteSQLQuery $query
   
    # create the stored procedure for visualization in PowerBI
    $script = $filepath + "step4_full_table.sql"
    ExecuteSQL $script
   
    $query = "EXEC prediction_results"
    ExecuteSQLQuery $query


    Write-Host -foregroundcolor 'green'("Length of Stay Development Workflow Finished Successfully!")
    }

     if($is_production -eq 'y' -or $is_production -eq 'Y')
    {
##########################################################################
# Production Pipeline
##########################################################################
   try
       {

        # create raw table
        Write-Host -ForeGroundColor 'green' ("Create SQL table.")
        $script = $filePath + "create_tables_prod.sql"
        ExecuteSQL $script
    
        Write-Host -ForeGroundColor 'green' ("Populate Production SQL table.")
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

    # execute the stored procedure to get the Stats, Models, and ColInfo tables. 
    Write-Host -ForeGroundColor 'Cyan' (" Getting the Stats, Models and Column Information from the table used during deployment...")
    $query = "EXEC copy_modeling_tables 'Hospital' "
    ExecuteSQLQuery $query

    # create the stored procedures for preprocessing
    $script = $filepath + "step1_data_processing.sql"
    ExecuteSQL $script

    # execute the NA replacement
    Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with the mean and mode...")
    $query = "EXEC fill_NA_mode_mean 'LengthOfStay_Prod', 'LoS0_Prod'"
    ExecuteSQLQuery $query

    # create the stored procedure for feature engineering
    $script = $filepath + "step2_feature_engineering.sql"
    ExecuteSQL $script

    # execute the feature engineering
    Write-Host -ForeGroundColor 'Cyan' (" Computing new features...")
    $query = "EXEC feature_engineering 'LoS0_Prod', 'LoS_Prod',1"
    ExecuteSQLQuery $query
     
    # create the stored procedure for predicting 
    $script = $filepath + "step3c_scoring.sql"
    ExecuteSQL $script

    # execute the scoring 
    Write-Host -ForeGroundColor 'Cyan' (" Scoring Gradient Boosted Trees (rxFastTrees implementation)...")
    $modelName = 'GBT'
    $query = "EXEC score $modelName, 'SELECT * FROM LoS_Prod', 'Boosted_Prediction_Prod'"
    ExecuteSQLQuery $query


    Write-Host -foregroundcolor 'green'("Length of Stay Production Workflow Finished Successfully!")
    }

}

##########################################################################

# Interrupted

##########################################################################

if ($uninterrupted -eq 'n' -or $uninterrupted -eq 'N')
{

    if($is_production -eq 'n' -or $is_production -eq 'N')
    {
##########################################################################
# Deployment Pipeline
##########################################################################

##########################################################################
# Create input table and populate with data from csv file.
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 0: Create and populate table in Database" -f $dbname)
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    try
    {
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

##########################################################################
# Create and execute the stored procedure for data processing
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 1: Data Processing")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedures for preprocessing
    $script = $filepath + "step1_data_processing.sql"
    ExecuteSQL $script

    # compute statistics for production and faster NA replacement.
    Write-Host -ForeGroundColor 'Cyan' (" Computing statistics on the input table...")
    $query = "EXEC compute_stats"
    ExecuteSQLQuery $query

    # execute the NA replacement
    $output0 = Read-Host 'Missing value treatment: Output table name? Type D or d for default (LoS0)'
    if ($output0 -eq 'D' -or $output1 -eq 'd')
    {
        $output0 = 'LoS0'
    }
    $ans2 = Read-Host 'Replacing missing values with mode and mean [M/m] or with missing and -1 [miss]?'
    if ($ans2 -eq 'M' -or $ans -eq 'm')
    {
        Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with mode and mean ...")
        $query = "EXEC fill_NA_mode_mean 'LengthOfStay', $output0"
        ExecuteSQLQuery $query
    }
    else
    {
        Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with missing and -1 ...")
        $query = "EXEC fill_NA_explicit 'LengthOfStay', $output0"
        ExecuteSQLQuery $query
    }

}

if ($ans -eq 's' -or $ans -eq 'S')
{
 $output0 = 'LoS0'
}
##########################################################################
# Create and execute the stored procedure for feature engineering
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 2a: Feature Engineering")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for feature engineering
    $script = $filepath + "step2_feature_engineering.sql"
    ExecuteSQL $script

    # execute the feature engineering
    $output1 = Read-Host 'Output table name? Type D or d for default (LoS)'
    if ($output1 -eq 'D' -or $output1 -eq 'd')
    {
        $output1 = 'LoS'
    }
    Write-Host -ForeGroundColor 'Cyan' (" Computing new features...")
    $query = "EXEC feature_engineering $output0, $output1, 0"
    ExecuteSQLQuery $query
}

if ($ans -eq 's' -or $ans -eq 'S')
{
    $output1 = 'LoS'
}


##########################################################################
# Create and execute the stored procedure to get column information
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 2b: Column Information Extraction")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
 
    # get the column information
    Write-Host -ForeGroundColor 'Cyan' (" Getting column information...")
    $query = "EXEC get_column_info $output1"
    ExecuteSQLQuery $query

}

##########################################################################
# Create and execute the stored procedure to split data into train/test
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 3a: Split the data into train and test")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for splitting into train and test data sets
    $script = $filepath + "step3a_splitting.sql"
    ExecuteSQL $script

    # execute the procedure
    $splitting_percent = Read-Host 'Split Percent (e.g. Type 70 for 70% in training set) ?'
    Write-Host -ForeGroundColor 'Cyan' (" Splitting the data set...")
    $query = "EXEC splitting $splitting_percent, $output1"
    ExecuteSQLQuery $query
}

##########################################################################
# Create and execute the stored procedure for Training 
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 3b: Models Training")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for training 
    $script = $filepath + "step3b_training.sql"
    ExecuteSQL $script

    # execute the training 
    $ans2 = Read-Host 'Train Random Forest (rxDForest implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans2 -eq 'E' -or $ans2 -eq 'e')
    {
        return
    } 
    if ($ans2 -eq 'y' -or $ans2 -eq 'Y')
    {
    Write-Host -ForeGroundColor 'Cyan' (" Training Random Forest (rxDForest implementation) ...")
    $modelName = 'RF'
    $query = "EXEC train_model $modelName, $output1"
    ExecuteSQLQuery $query
    }

    $ans3 = Read-Host 'Train Gradient Boosted Trees (rxFastTrees implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans3 -eq 'E' -or $ans3 -eq 'e')
    {
        return
    } 
    if ($ans3 -eq 'y' -or $ans3 -eq 'Y')
    {
    Write-Host -ForeGroundColor 'Cyan' (" Training Gradient Boosted Trees (rxFastTrees implementation)  ...")
    $modelName = 'GBT'
    $query = "EXEC train_model $modelName, $output1"
    ExecuteSQLQuery $query
    }
}

##########################################################################
# Create and execute the stored procedure for models scoring
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 3c: Models Scoring")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for predicting 
    $script = $filepath + "step3c_scoring.sql"
    ExecuteSQL $script

    # execute the scoring
    $ans2 = Read-Host 'Score Random Forest (rxDForest implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans2 -eq 'E' -or $ans2 -eq 'e')
    {
        return
    } 
    if ($ans2 -eq 'y' -or $ans2 -eq 'Y')
    {
        $output2 = Read-Host 'Output table name holding predictions? Type D or d for default (Forest_Prediction)'
        if ($output2 -eq 'D' -or $output2 -eq 'd')
        {
        $output2 = 'Forest_Prediction'
        }

        Write-Host -ForeGroundColor 'Cyan' (" Scoring Random Forest (rxDForest implementation) ...")
        $modelName = 'RF'    
        $query = "EXEC score $modelName, 'SELECT * FROM $output1 WHERE eid NOT IN (SELECT eid FROM Train_Id)', $output2"
        ExecuteSQLQuery $query
         }

    if ($ans2 -eq 's' -or $ans2 -eq 'S')
    {
    $output2 = 'Forest_Prediction'
    }


    $ans3 = Read-Host 'Score Boosted Trees (rxFastTrees implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans3 -eq 'E' -or $ans3 -eq 'e')
    {
        return
    } 
    if ($ans3 -eq 'y' -or $ans3 -eq 'Y')
    {
        $output3 = Read-Host 'Output table name holding predictions? Type D or d for default (Boosted_Prediction)'
        if ($output3 -eq 'D' -or $output3 -eq 'd')
        {
        $output3 = 'Boosted_Prediction'
        }

        Write-Host -ForeGroundColor 'Cyan' (" Scoring Boosted Trees (rxFastTrees implementation) ...")
        $modelName = 'GBT'
        $query = "EXEC score $modelName,'SELECT * FROM $output1 WHERE eid NOT IN (SELECT eid FROM Train_Id)', $output3"
        ExecuteSQLQuery $query
         }

    if ($ans3 -eq 's' -or $ans3 -eq 'S')
    {
    $output3 = 'Boosted_Prediction'
    }
}

if ($ans -eq 's' -or $ans -eq 'S')
{
   $output2 = 'Forest_Prediction'
   $output3 = 'Boosted_Prediction'
}


##########################################################################
# Create and execute the stored procedure for models evaluation
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 3d: Models Evaluation")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for evaluation
    $script = $filepath + "step3d_evaluating.sql"
    ExecuteSQL $script

    # execute the evaluation
    $ans2 = Read-Host 'Evaluate Random Forest (rxDForest implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans2 -eq 'E' -or $ans2 -eq 'e')
    {
        return
    } 
    if ($ans2 -eq 'y' -or $ans2 -eq 'Y')
    {
        Write-Host -ForeGroundColor 'Cyan' (" Evaluating Random Forest (rxDForest implementation) ...")
        $modelName = 'RF'
        $query = "EXEC evaluate $modelName, $output2"
        ExecuteSQLQuery $query
         }

    $ans3 = Read-Host 'Evaluate Boosted Trees (rxFastTrees implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans3 -eq 'E' -or $ans3 -eq 'e')
    {
        return
    } 
    if ($ans3 -eq 'y' -or $ans3 -eq 'Y')
    {

        Write-Host -ForeGroundColor 'Cyan' (" Evaluating Boosted Trees (rxFastTrees implementation) ...")
        $modelName = 'GBT'
        $query = "EXEC evaluate $modelName, $output3"
        ExecuteSQLQuery $query
    }

}

Write-Host -foregroundcolor 'green'("Length of Stay Developmentt Workflow Finished Successfully!")
}

 if($is_production -eq 'y' -or $is_production -eq 'Y')
 {
##########################################################################
# Production Pipeline
##########################################################################

##########################################################################
# Create input table and populate with data from csv file.
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 0: Create and populate table in Database" -f $dbname)
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    try
    {
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

    # execute the stored procedure to get the Stats, Models, and ColInfo tables. 
    Write-Host -ForeGroundColor 'Cyan' (" Getting the Stats, Models and Column Information from the table used during deployment...")
    $ans = Read-Host 'Name of the development database to get Stats, Models and Column Information from?'
    $query = "EXEC copy_modeling_tables $ans "
    ExecuteSQLQuery $query

}

##########################################################################
# Create and execute the stored procedure for data processing
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 1: Data Processing")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedures for preprocessing
    $script = $filepath + "step1_data_processing.sql"
    ExecuteSQL $script

    # execute the NA replacement
    $output0 = Read-Host 'Missing value treatment: Output table name? Type D or d for default (LoS0_Prod)'
    if ($output0 -eq 'D' -or $output1 -eq 'd')
    {
        $output0 = 'LoS0_Prod'
    }

    $ans2 = Read-Host 'Replacing missing values with mode and mean [M/m] or with missing and -1 [miss]? WARNING: you should do the same as for deployment database.'
    if ($ans2 -eq 'M' -or $ans -eq 'm')
    {
        Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with mode and mean ...")
        $query = "EXEC fill_NA_mode_mean 'LengthOfStay_Prod', $output0"
        ExecuteSQLQuery $query
    }
    else
    {
        Write-Host -ForeGroundColor 'Cyan' (" Replacing missing values with missing and -1 ...")
        $query = "EXEC fill_NA_explicit 'LengthOfStay_Prod', $output0"
        ExecuteSQLQuery $query
    }

}

if ($ans -eq 's' -or $ans -eq 'S')
{
$output0 = 'LoS0_Prod'
}

##########################################################################
# Create and execute the stored procedure for feature engineering
##########################################################################
Write-Host -foregroundcolor 'green' ("Step 2: Feature Engineering")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
    # create the stored procedure for feature engineering
    $script = $filepath + "step2_feature_engineering.sql"
    ExecuteSQL $script

    # execute the feature engineering
    $output1 = Read-Host 'Output table name? Type D or d for default (LoS_Prod)'
    if ($output1 -eq 'D' -or $output1 -eq 'd')
    {
        $output1 = 'LoS_Prod'
    }
    Write-Host -ForeGroundColor 'Cyan' (" Computing new features...")
    $query = "EXEC feature_engineering $output0, $output1, 1"
    ExecuteSQLQuery $query
}

if ($ans -eq 's' -or $ans -eq 'S')
{
    $output1 = 'LoS_Prod'
}


##########################################################################
# Create and execute the stored procedure for models scoring
##########################################################################

Write-Host -foregroundcolor 'green' ("Step 3: Models Scoring")
$ans = Read-Host 'Continue [y|Y], Exit [e|E], Skip [s|S]?'
if ($ans -eq 'E' -or $ans -eq 'e')
{
    return
} 
if ($ans -eq 'y' -or $ans -eq 'Y')
{
  # create the stored procedure for predicting 
    $script = $filepath + "step3c_scoring.sql"
    ExecuteSQL $script

    # execute the scoring
    $ans2 = Read-Host 'Use Random Forest (rxDForest implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans2 -eq 'E' -or $ans2 -eq 'e')
    {
        return
    } 
    if ($ans2 -eq 'y' -or $ans2 -eq 'Y')
    {
        $output2 = Read-Host 'Output table name holding predictions? Type D or d for default (Forest_Prediction_Prod)'
        if ($output2 -eq 'D' -or $output2 -eq 'd')
        {
        $output2 = 'Forest_Prediction_Prod'
        }

        Write-Host -ForeGroundColor 'Cyan' (" Scoring Random Forest (rxDForest implementation) ...")
        $modelName = 'RF'
        $query = "EXEC score $modelName, 'SELECT * FROM $output1', $output2"
        ExecuteSQLQuery $query
         }

    $ans3 = Read-Host 'Use Boosted Trees (rxFastTrees implementation): Yes [y|Y], Exit [e|E], Skip [s|S]?'
    if ($ans3 -eq 'E' -or $ans3 -eq 'e')
    {
        return
    } 
    if ($ans3 -eq 'y' -or $ans3 -eq 'Y')
    {
        $output3 = Read-Host 'Output table name holding predictions? Type D or d for default (Boosted_Prediction_Prod)'
        if ($output3 -eq 'D' -or $output3 -eq 'd')
        {
        $output3 = 'Boosted_Prediction_Prod'
        }

        Write-Host -ForeGroundColor 'Cyan' (" Scoring Boosted Trees (rxFastTrees implementation) ...")
        $modelName = 'GBT'
        $query = "EXEC score $modelName, 'SELECT * FROM $output1', $output3"
        ExecuteSQLQuery $query
        }

}
Write-Host -foregroundcolor 'green'("Length of Stay Production Workflow Finished Successfully!")
}
}

$endTime =Get-Date
$totalTime = ($endTime-$startTime).ToString()
Write-Host "Finished running at:" $endTime
Write-Host "Total time used: " -foregroundcolor 'green' $totalTime.ToString()