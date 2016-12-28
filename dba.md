---
layout: default
title: For the Database Analyst
---

## For the Database Analyst
------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
          <li><a href="#system-requirements">System Requirements</a></li>
          <li><a href="#workflow-automation">Workflow Automation</a></li>
        <li><a href="#step0">Step 0: Creating Tables</a></li>
        <li><a href="#step1">Step 1: Pre-Processing and Cleaning</a></li>
        <li><a href="#step2">Step 2: Feature Engineering</a></li>
        <li><a href="#step3">Step 3: Normalization</a></li>
        <li><a href="#step3a">Step 3a: Splitting the data set</a></li>
        <li><a href="#step3b">Step 3b: Training (Classification)</a></li>
        <li><a href="#step3br">Step 3b: Training (Regression)</a></li>
        <li><a href="#step3c"> Step 3c: Testing and Evaluating (Classification)</a></li>
        <li><a href="#step3cr"> Step 3c: Testing and Evaluating (Regression)</a></li>
        </div>
    </div>
    <div class="col-md-6">
      As businesses are starting to acknowledge the power of data, leveraging machine learning techniques to grow has become a must. XXXDESCRIBE.
          </div>
</div>
<p>
Among the key variables to learn from data are XXXDESCRIBE
</p>

For businesses that prefer an on-prem solution, the implementation with SQL Server R Services is a great option, which takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server). In this template, we implemented all steps in SQL stored procedures: data preprocessing, and feature engineering are implemented in pure SQL, while data cleaning, and the model training, scoring and evaluation steps are implemented with SQL stored procedures calling R (Microsoft R Server) code. 

All the steps can be executed on SQL Server client environment (SQL Server Management Studio). We provide a Windows PowerShell script which invokes the SQL scripts and demonstrates the end-to-end modeling process.

## System Requirements
-----------------------

To run the scripts requires the following:

 * SQL server 2016 with Microsoft R server installed and configured;
 * The SQL user name and password, and the user is configured properly to execute R scripts in-memory;
 * SQL Database for which the user has write permission and can execute stored procedures;
 * For more information about SQL server 2016 and R service, please visit: [What's New in SQL Server R Services](https://msdn.microsoft.com/en-us/library/mt604847.aspx)


## Workflow Automation
-------------------
Follow the [PowerShell instructions](Powershell_Instructions.html) to execute all the scripts described below.  [Click here](tables.html) to view the details all tables created in this solution.

 
<a name="step0"></a>

#### Step 0: Creating Tables
-------------------------

The data set **LengthOfStay.csv** is provided in the Data directory.

In this step, we create a table `LengthOfStay` in a SQL Server database, and the data is uploaded to these tables using bcp command in PowerShell. This is done through either **load_data.ps1** or through running the beginning of **Length_Of_Stay.ps1**. 

### Input:

* Raw data: **LengthOfStay.csv**

### Output:

* 1 Table filled with the raw data: `LengthOfStay` (filled through PowerShell).

### Related files:
* **step0_create_tables.sql**


<a name="step1"></a>

## Step 1: Pre-Processing and Cleaning
-------------------------

In this step, the raw data is cleaned in-place. This assumes that the ID variable (`eid`) does not contain blanks. 
There are two ways to replace missing values:

* The first provided stored procedure, [`fill_NA_explicit`], will replace the missing values with "missing" (character variables) or -1 (numeric variables). It should be used if it is important to know where the missing values were.

* The second stored procedure, [`fill_NA_mode_mean`], will replace the missing values with the mode (categorical variables) or mean (float variables).

If running the stored procedures yourself, or if running **Length_Of_Stay.ps1** with `uninterrupted = "N"`, you will have the opportunity to choose between the two stored procedures. 
If running **Length_Of_Stay.ps1** with `uninterrupted = "Y"`, [`fill_NA_mode_mean`] will be automatically used.

### Input:
* 1 Table filled with the raw data: `LengthOfStay` (filled through PowerShell).

### Output:
* The same table, with missing values replaced.

### Related files:
* **step1_data_processing.sql**

<a name="step2"></a>

## Step 2: Feature Engineering
-------------------------

In this step, we create a stored procedure `[dbo].[feature_engineering]` that designs new features:  

* The continuous laboratory measurements (e.g. hemo, `hematocritic`, `sodium`, `glucose` etc.) are standardized: we substract the mean and divide by the standard deviation. 
* `number_of_issues`: the total number of preidentified medical conditions.
* `lengthofstay_bucket`: bucketed version of the target variable for classification.

### Input:

* `LengthOfStay` table.

### Output:

* `LoS` table containing new features.

### Related files:

* **step2_feature_engineering.sql**

<a name="step3a"></a>

## Step 3a: Splitting the data set
-------------------------

In this step, we create a stored procedure `[dbo].[splitting]` that splits the data into a training set and a testing set. The user has to specify a splitting percentage. For example, if the splitting percentage is 70, 70% of the data will be put in the training set, while the other 30% will be assigned to the testing set. The `eid` that will end in the training set, are stored in the table `Train_Id`.


### Input:

* `LoS` table.

### Output:

* `Train_Id` table containing the eid that will end in the training set.

### Related files:

* **step3a_splitting.sql**

In what follows, the problem can be modeled as a classification or a regression. 
If running the stored procedures yourself, or if running **Length_Of_Stay.ps1** with `uninterrupted = "N"`, you will have the opportunity to choose between the two approaches. 
If running **Length_Of_Stay.ps1** with `uninterrupted = "Y"`, the two approaches will be considered. 


<a name="step3b"></a>

## Step 3b: Training (Classification)
-------------------------

In this step, we create a stored procedure `[dbo].[train_model_class]` that trains a classification Random Forest (RF) on the training set. The models perform a stratified sampling in order to deal with class imbalance. The trained model is serialized then stored in a table called `Models_Class`.


### Input:

* `LoS` and `Train_Id` tables.

### Output:

* `Models_Class` table containing the classification RF trained models. 

### Related files:

* **step3b_training_classification.sql**

<a name="step3br"></a>

## Step 3b: Training (Regression)
-------------------------

In this step, we create a stored procedure `[dbo].[train_model_class]` that trains a regression Random Forest (RF) on the training set. The trained model is serialized then stored in a table called `Models_Reg`. 


### Input:

* `LoS` and `Train_Id` tables.

### Output:

* `Models_Reg` table containing the regression RF trained model. 

### Related files:

* **step3b_training_regression.sql**

<a name="step3c"></a>

## Step 3c: Testing and Evaluating (Classification)
-------------------------

In this step, we create a stored procedure `[dbo].[test_evaluate_model_class]` that scores the trained model on the testing set, and then compute multi-class performance metrics. The performance metrics are written in `Metrics_Class`.


### Input:

* `LoS`, `Train_Id`, and `Models_Class` tables.

### Output:

* `Metrics_Class` table containing the performance metrics of the model.


### Related files:

* **step3c_testing_evaluating_classification.sql**



<a name="step3cr"></a>

### Step 3c: Testing and Evaluating (Regression)
-------------------------

In this step, we create a stored procedure `[dbo].[test_evaluate_model_reg]` that scores the trained model on the testing set, and then compute regression performance metrics written in `Metrics_Reg`.


### Input:

* `LoS` and `Train_Id`, and `Models_Reg` tables.

### Output:

* `Metrics_Reg` table containing the performance metrics of the model.


### Related files:

* ***step3c_testing_evaluating_regression.sql**






