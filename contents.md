---
layout: default
title: Template Contents
---

## Template Contents
--------------------

The following is the directory structure for this template:

- [**Data**](#copy-of-input-datasets)  This contains the copy of the input data XXXDESCRIBE A LITTLE IF YOU WISH. 
- [**R**](#model-development-in-r)  This contains the R code to simulate the input datasets, pre-process them, create the analytical datasets, train the models, and score the data.
- [**Resources**](#resources-for-the-solution-packet) This directory contains other resources for the solution package.
- [**SQLR**](#operationalize-in-sql-2016) This contains the T-SQL code to pre-process the datasets, train the models, identify the champion model and provide recommendations. It also contains a PowerShell script to automate the entire process, including loading the data into the database (not included in the T-SQL code).

In this template with SQL Server R Services, two versions of the implementation:

1. [**Model Development in R IDE**](#model-development-in-r)  . Run the R code in R IDE (e.g., RStudio, R Tools for Visual Studio).
2. [**Operationalize in SQL**](#operationalize-in-sql-2016). Run the SQL code in SQL Server using SQLR scripts from SSMS or from the PowerShell script.


### Copy of Input Datasets
----------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description</th></tr>
<tr><td> .\Data\LengthOfStay.csv  </td><td> Synthetic data modeled after real world hospital inpatient records </td></tr>
</table>

### Model Development in R
-------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> {{ site.jupyter_name}}  </td><td> Contains the Jupyter Notebook file that runs all the .R scripts. </td></tr>
<tr><td>SQL_connection.R </td><td> Contains details of connection to SQL Server used in all other scripts. </td></tr>
<tr><td>step1_data_preprocessing.R </td><td> Data loaded and missing values handled </td></tr>
<tr><td>step2_feature_engineering.R </td><td> Measures standardized and classification buckets created </td></tr>
<tr><td>step3_training_evaluation_classification.R  </td><td>Trains and scores a classification Random Forest (RF) </td></tr>
<tr><td>step3_training_evaluation_regression.R  </td><td>Trains and scores a regression Random Forest (RF) </td></tr>
</table>


* See [For the Data Scientist](data_scientist.html) for more details about these files.
* View [Typical Workflow](Typical.html)  for more information about executing these scripts.


### Operationalize in SQL 2016 
-------------------------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> .\SQLR\Length_Of_Stay.ps1  </td><td> Automates execution of all .sql files and creates stored procedures </td></tr>
<tr><td> .\SQLR\execute_yourself.sql  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLR\load_data.ps1  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLR\step0_create_table.sql  </td><td> Creates initial `LengthOfStay` table </td></tr>
<tr><td> .\SQLR\step1_data_processing.sql  </td><td> Handles missing data </td></tr>
<tr><td> .\SQLR\step2_feature_engineering.sql  </td><td> Standardizes measures and creates `number_of_issues` and `lengthofstay_bucket` </td></tr>
<tr><td> .\SQLR\step3a_splitting.sql  </td><td> Splits data into train and test </td></tr>
<tr><td> .\SQLR\step3b_training_classification.sql  </td><td> Trains and stores classification Random Forest (RF) </td></tr>
<tr><td> .\SQLR\step3b_training_regression.sql  </td><td> Trains and stores classification Random Forest (RF) </td></tr>
<tr><td> .\SQLR\step3c_testing_evaluating_classification.sql  </td><td> Scores and evaluates classification RF </td></tr>
<tr><td> .\SQLR\step3c_testing_evaluating_regression.sql  </td><td> Scores and evaluates regression RF </td></tr>


</table>

* See [ For the Database Analyst](dba.html) for more information about these files.
* Follow the [PowerShell Instructions](Powershell_Instructions.html) to execute the PowerShell script which automates the running of all these .sql files.

### Resources for the Solution Package
------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>

<tr><td> .\Resources\createuser.sql </td><td> Used during initial SQL Server setup to create the user and password and grant permissions. </td></tr>
<tr><td> .\Resources\Data_Dictionary.xlsx   </td><td> Description of all variables in the LengthOfStay.csv data file</td></tr>
<tr><td> .\Resources\Images\ </td><td> Directory of images used for the  Readme.md  in this package. </td></tr>
</table>




[&lt; Home](index.html)
