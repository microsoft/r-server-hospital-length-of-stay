param(
 [string]
 $trainDataPath = ".\lengthofstay_Classification_Test_Data.csv"
)

Write-Host "Loading test data into SQL`r`n" -f Green

$sqlConnection = "Server=lengthofstayvm;Database=SolutionAcc;Trusted_Connection=True"

    
#create test data table if it doesn't exist
try
{
    Invoke-Sqlcmd -InputFile "..\common\CreateTestDataTable.sql" -ServerInstance "lengthofstayvm" -ErrorAction Stop
    Write-Host "Test data table created`r`n" -f Yellow
}
catch
{
    Write-Host "Test data table exists`r`n" -f Red
    $title = "Please Choose"
    $message = "Do you want to [A]ppend to the training data of [T]erminate the loading process?"

    $append = New-Object System.Management.Automation.Host.ChoiceDescription "&Append", `
    "Appends provided data to test data table."

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
$bulkCopy.DestinationTableName = "lengthofstay_Classification_Test_Data"
$bulkCopy.WriteToServer($csvDataTable)
Write-Host "Test data loaded`r`n" -f Green

#Creating predictions table
Write-Host "Creating predictions table `r`n" -f Yellow
Invoke-Sqlcmd -ServerInstance "lengthofstayvm" -InputFile "..\common\CreateTestPredictionsTable.sql" -Database "SolutionAcc"
Write-Host "Predictions table created `r`n" -f Green

Write-Host "Scoring test data`r`n" -f Yellow
$scoreSqlCmd = "exec PredictLengthOfStayForestBatch @inquery = 'select * from lengthofstay_Classification_Test_Data'"
Invoke-Sqlcmd -ServerInstance "lengthofstayvm" -Query $scoreSqlCmd -Database "SolutionAcc"
Write-Host "Data scored. Results in dbo.lengthofstay_Classification_Test_Predictions`r`n" -f Green

