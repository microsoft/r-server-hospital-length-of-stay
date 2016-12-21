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
        <li><a href="#step3b">Step 3b: Training</a></li>
        <li><a href="#step3c">Step 3c: Testing and Evaluating</a></li>
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

 
<a name="step0">

## Step 0: Creating Tables
--------------------------


The following data are provided in the Data directory:

<table class="table table-compressed table-striped">
  <tr>
    <th>File</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>FILENAME</td>
    <td>DESCRIPTION</td>
  </tr>

</table>

XXXDESCRIBE

### Input:

* Raw data: XXXFILENAMES 

### Output:

* XXXTABLES

### Related files:

* step0_create_tables.sql

<a name="step1">

## Step 1: Pre-Processing and Cleaning
----------------------------------------

XXXDESCRIBE

### Input:

* XXXTABLES

### Output:

* XXXTABLES

### Related files:
* step1_data_processing.sql

<a name="step2">

## Step 2: Feature Engineering
-------------------------------

XXXDESCRIBE

### Input:

* XXXTABLES

### Output:

* XXXTABLES

### Related files:

* step2_feature_engineering.sql

<a name="step3">

## Step 3: Normalization
---------------------------

XXXDESCRIBE

### Input:

* XXXTABLES

### Output:

* XXXTABLES

* step3_normalization.sql

<a name="step3a">

## Step 3a: Splitting the data set
-----------------------------------

XXXDESCRIBE

### Input:

* XXXTABLES

### Output:

* XXXTABLES

### Related files:

* step3a_splitting.sql

<a name="step3b">

## Step 3b: Training
----------------------

XXXDESCRIBE

### Input:

* XXXTABLES

### Output:

* XXXTABLES

### Related files:

* step3b_train_model.sql

<a name="step3c">

## Step 3c: Predicting (Scoring)
---------------------------------

XXXDESCRIBE

### Input:

* XXXTABLES

### Output:

* XXXTABLES

### Related files:

* step3c_test_evaluate_models.sql

<a name="step4">






