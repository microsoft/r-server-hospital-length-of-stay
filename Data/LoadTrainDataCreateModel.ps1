param(
 [string]
 $trainDataPath = ".\lengthofstay_Classification_Train_Data.csv"
)

Write-Host "Loading training data into SQL`r`n" -f Green

$sqlConnection = "Server=lengthofstayvm;Database=SolutionAcc;Trusted_Connection=True"

    
#create training data table if it doesn't exist
try
{
    Invoke-Sqlcmd -InputFile "..\common\CreateTrainingDataTable.sql" -ServerInstance "lengthofstayvm" -ErrorAction Stop
    Write-Host "Training data table created`r`n" -f Yellow
}
catch
{
    Write-Host "Training data table exists`r`n" -f Red
    $title = "Please Choose"
    $message = "Do you want to [A]ppend to the training data of [T]erminate the loading process?"

    $append = New-Object System.Management.Automation.Host.ChoiceDescription "&Append", `
    "Appends provided data to training data table."

    $terminate = New-Object System.Management.Automation.Host.ChoiceDescription "&Terminate", `
    "Terminates the loading process."

    $options = [System.Management.Automation.Host.ChoiceDescription[]]($append, $terminate)

    $result = $host.ui.PromptForChoice($title, $message, $options, 1) 

    switch ($result)
        {
            0 {
                "Appending to data."
              }
            1 {
                Write-Host "Terminating Load."
                exit
              }
        }
}

#convert .csv to DataTable and loads to sql
. ..\Common\OutTable.ps1
$csvDataTable = Import-CSV -Path $trainDataPath | Out-DataTable
$bulkCopy = new-object ("Data.SqlClient.SqlBulkCopy") $sqlConnection
$bulkCopy.DestinationTableName = "lengthofstay_Classification_Train_Data"
$bulkCopy.WriteToServer($csvDataTable)

# Timeouts set to 0 (no timeout) in case of long train time
Write-Host "Training Forest Moel`r`n" -f Yellow
$trainingForestSqlCmd = "exec TrainLengthOfStayForestModel"
Invoke-Sqlcmd -Query $trainingForestSqlCmd -ServerInstance "lengthofstayvm" -ErrorAction Stop -Database "SolutionAcc" -QueryTimeout 0
Write-Host "Forest Model trained`r`n" -f Green

Write-Host "Training Boosted Tree Model `r`n" -f Yellow
$trainingBoostedTreeSqlCmd = "exec TrainLengthOfStayBoostedTreeModel"
Invoke-Sqlcmd -Query $trainingBoostedTreeSqlCmd -ServerInstance "lengthofstayvm" -ErrorAction Stop -Database "SolutionAcc" -QueryTimeout 0
Write-Host "Boosted tree Model trained`r`n" -f Green