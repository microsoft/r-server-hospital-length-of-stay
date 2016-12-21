# Hospital Length of Stay Prediction Template in SQL Server with R sevices
--------------------------
 * **Introduction**
 * **System Requirements**
 * **Workflow Automation**
 * **Step 0: Creating Tables**
 * **Step 1: Pre-Processing and Cleaning**
 * **Step 2: Feature Engineering**
 * **Step 3a: Splitting the data set**
 * **Step 3b: Training (Classification)**
 * **Step 3c: Testing and Evaluating (Classification)**
 * **Step 3b: Training (Regression)**
 * **Step 3c: Testing and Evaluating (Regression)**
 
### Introduction
-------------------------

In order for hospitals to optimize resource allocation, it is important to predict accurately how long a newly admitted patient will stay in the hospital.

For businesses that prefers an on-prem solution, the implementation with SQL Server R Services is a great option, which takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server). In this template, we implemented all steps in SQL stored procedures: data preprocessing, and feature engineering are implemented in pure SQL, while data cleaning, and the model training, scoring and evaluation steps are implemented with SQL stored procedures calling R (Microsoft R Server) code. 

All the steps can be executed on SQL Server client environment (such as SQL Server Management Studio). We provide a Windows PowerShell script, Length_Of_Stay.ps1, which invokes the SQL scripts and demonstrates the end-to-end modeling process.

### System Requirements
-----------------------

To run the scripts, it requires the following:
 * SQL server 2016 with Microsoft R server installed and configured;
 * The SQL user name and password, and the user is configured properly to execute R scripts in-memory;
 * SQL Database for which the user has write permission and can execute stored procedures;
 * For more information about SQL server 2016 and R service, please visit: https://msdn.microsoft.com/en-us/library/mt604847.aspx


### Workflow Automation
-------------------

We provide a Windows PowerShell script to demonstrate the end-to-end workflow. To learn how to run the script, open a PowerShell command prompt, navigate to the directory storing the PowerShell script and type:

    Get-Help .\SQLR-Length_Of_Stay.ps1

To invoke the PowerShell script, type:
(
    .\SQLR-Length_Of_Stay.ps1 -ServerName "Server Name" -DBName "Database Name" -username "" -password "" -uninterrupted "Y/N" -dataPath                           
With the uninterrupted argument, you can choose whether to run all the steps without interruption ("Y" or "y"), or with interruptions ("N" or "n"). With the latter, you will then be able to execute each step or not. The dataPath argument lets the user specify the path for the folder containing the 4 csv files. If not specified, the default path links to the Data folder in the parent directory. 

### Step 0: Creating Tables
-------------------------

The data set LengthOfStay.csv is provided in the Data directory.

In this step, we create a table “LengthOfStay” in a SQL Server database, and the data is uploaded to these tables using bcp command in PowerShell. This is done through either load_data.ps1 or through running the beginning of Length_Of_Stay.ps1. 

Input:

* Raw data: LengthOfStay.csv 

Output:

* 1 Table filled with the raw data: "LengthOfStay"(filled through PowerShell).

Related files:
* step0_create_tables.sql

### Step 1: Pre-Processing and Cleaning
-------------------------

In this step, the raw data is cleaned in-place. This assumes that the ID variable (eid) does not contain blanks. 
There are two ways to replace missing values:

The first provided stored procedure, [fill_NA_explicit], will replace the missing values with "missing" (character variables) or -1 (numeric variables). It should be used if it is important to know where the missing values were.

The second stored procedure, [fill_NA_mode_mean], will replace the missing values with the mode (categorical variables) or mean (float variables).

If running the stored procedures yourself, or if running Length_Of_Stay.ps1 with uninterrupted = "N", you will have the opportunity to choose between the two stored procedures. 
If running Length_Of_Stay.ps1 with uninterrupted = "Y", [fill_NA_mode_mean] will be automatically used.

Input:
* 1 Table filled with the raw data: "LengthOfStay"(filled through PowerShell).

Output:
* The same table, with missing values replaced.

Related files:
* step1_data_processing.sql

### Step 2: Feature Engineering
-------------------------

In this step, we create a stored procedure [dbo].[feature_engineering] that designs new features:  

* The continuous laboratory measurements (e.g. hemo, hematocritic, sodium, glucose etc.) are standardized: we substract the mean and divide by the standard deviation. 
* number_of_issues: the total number of preidentified medical conditions.

Input:

* "LengthOfStay" table.

Output:

* "LoS" table containing new features.

Related files:

* step2_feature_engineering.sql

### Step 3a: Splitting the data set
-------------------------

In this step, we create a stored procedure [dbo].[splitting] that splits the data into a training set and a testing set. The user has to specify a splitting percentage. For example, if the splitting percentage is 70, 70% of the data will be put in the training set, while the other 30% will be assigned to the testing set. The eid that will end in the training set, are stored in the table “Train_Id”.


Input:

* "LoS" table.

Output:

* "Train_Id" table containing the eid that will end in the training set.
_
Related files:

* step3a_splitting.sql

In what follows, the problem can be modeled as a classification or a regression. 
If running the stored procedures yourself, or if running Length_Of_Stay.ps1 with uninterrupted = "N", you will have the opportunity to choose between the two approaches. 
If running Length_Of_Stay.ps1 with uninterrupted = "Y", the two approaches will be considered. 

### Step 3b: Training (Classification)
-------------------------

In this step, we create a stored procedure [dbo].[train_model_class] that trains a classification Random Forest (RF) or a classification Gradient Boosted Trees (GBT) on the training set. The trained models are serialized then stored in a table called “Models_Class”. The PowerShell script automatically calls the procedure twice in order to train both models. 


Input:

* "LoS" and "Train_Id" tables.

Output:

* "Models_Class" table containing the classification RF and GBT trained models. 

Related files:

* step3b_training_classification.sql

### Step 3c: Testing and Evaluating (Classification)
-------------------------

In this step, we create a stored procedure [dbo].[test_evaluate_models_class] that scores the two trained models on the testing set, and then compute multi-class performance metrics. The performance metrics are written in “Metrics_Class”.


Input:

* "LoS", "Train_Id", and "Models_Class" tables.

Output:

* "Metrics_Class" table containing the performance metrics of the two models.


Related files:

* step3c_testing_evaluating_classification.sql

### Step 3b: Training (Regression)
-------------------------

In this step, we create a stored procedure [dbo].[train_model_class] that trains a regression Random Forest (RF) or a regression Gradient Boosted Trees (GBT) on the training set. The trained models are serialized then stored in a table called “Models_Reg”. The PowerShell script automatically calls the procedure twice in order to train both models. 


Input:

* "LoS" and "Train_Id" tables.

Output:

* "Models_Reg" table containing the regression RF and GBT trained models. 

Related files:

* step3b_training_regression.sql

### Step 3c: Testing and Evaluating (Regression)
-------------------------

In this step, we create a stored procedure [dbo].[test_evaluate_models_reg] that scores the two trained models on the testing set, and then compute regressiom performance metrics as well as multi-class classification metrics obtained after rounding the prediction. The performance metrics are written in “Metrics_Reg”.


Input:

* "LoS" and "Train_Id", and "Models_Reg" tables.

Output:

* "Metrics_Reg" table containing the performance metrics of the two models.


Related files:

* step3c_testing_evaluating_regression.sql



