---
layout: default
title: Template Contents
---

## Template Contents
--------------------

The following is the directory structure for this template:

- [**Data**](#copy-of-input-datasets)  This contains the copy of the input data.
- [**R**](#model-development-in-r)  This contains the R code to simulate the input datasets, pre-process them, create the analytical datasets, train the models, and score the data.
- [**Python**](#model-development-in-python)  This contains the Python code to simulate the input datasets, pre-process them, create the analytical datasets, train the models, and score the data.
- [**Resources**](#resources-for-the-solution-packet) This directory contains other resources for the solution package.
- [**SQLR**](#operationalize-in-sql-r) This contains the T-SQL code with R to pre-process the datasets, train the models, identify the champion model and provide recommendations. It also contains a PowerShell script to automate the entire process, including loading the data into the database (not included in the T-SQL code).
- [**SQLPy**](#operationalize-in-sql-python) This contains the T-SQL code with Python to pre-process the datasets, train the models, identify the champion model and provide recommendations. It also contains a PowerShell script to automate the entire process, including loading the data into the database (not included in the T-SQL code).



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
<tr><td>step2_feature_engineering.R </td><td> Measures standardized </td></tr>
<tr><td>step3_training_evaluation.R  </td><td>Trains and Scores regression Random Forest (rxDForest) and a gradient boosted trees model (rxFastTrees)</td></tr>
</table>


* See [For the Data Scientist](data_scientist.html) for more details about these files.
* View [Typical Workflow](Typical.html)  for more information about executing these scripts.

### Model Development in Python
-------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> {{ site.jupyter_name}}  </td><td> Contains the Jupyter Notebook file that runs all the .R scripts. </td></tr>
<tr><td>SQL_connection.py </td><td> Contains details of connection to SQL Server used in all other scripts. </td></tr>
<tr><td>step1_data_preprocessing.py </td><td> Data loaded and missing values handled </td></tr>
<tr><td>step2_feature_engineering.py </td><td> Measures standardized </td></tr>
<tr><td>step3_training_evaluation.py  </td><td>Trains and Scores regression Random Forest (rxDForest) and a gradient boosted trees model (rxFastTrees)</td></tr>
</table>


* See [For the Data Scientist](data_scientist.html) for more details about these files.
* View [Typical Workflow](Typical.html)  for more information about executing these scripts.


### Operationalize in SQL R 
-------------------------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> .\SQLR\Length_Of_Stay.ps1  </td><td> Automates execution of all .sql files and creates stored procedures </td></tr>
<tr><td> .\SQLR\execute_yourself.sql  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLR\load_data.ps1  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLR\step0_create_table.sql  </td><td> Creates initial <code>LengthOfStay</code> table </td></tr>
<tr><td> .\SQLR\step1_data_processing.sql  </td><td> Handles missing data </td></tr>
<tr><td> .\SQLR\step2_feature_engineering.sql  </td><td> Standardizes measures and creates <code>number_of_issues</code> and <code>lengthofstay_bucket</code> </td></tr>
<tr><td> .\SQLR\step3a_splitting.sql  </td><td> Splits data into train and test </td></tr>
<tr><td> .\SQLR\step3b_training.sql  </td><td> Trains and scores a gradient boosted trees model (rxFastTrees) or Random Forest (rxDForest)  </td></tr>
<tr><td> .\SQLR\step3c_testing_evaluating.sql  </td><td> Scores and evaluates regression RF </td></tr>


</table>

* See [ For the Database Analyst](dba.html) for more information about these files.
* Follow the [PowerShell Instructions](Powershell_Instructions.html) to execute the PowerShell script which automates the running of all these .sql files.

### Operationalize in SQL Python 
-------------------------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> .\SQLPy\Length_Of_Stay.ps1  </td><td> Automates execution of all .sql files and creates stored procedures </td></tr>
<tr><td> .\SQLPy\execute_yourself.sql  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLPy\load_data.ps1  </td><td> used in Length_Of_Stay.sql </td></tr>
<tr><td> .\SQLPy\step0_create_table.sql  </td><td> Creates initial <code>LengthOfStay</code> table </td></tr>
<tr><td> .\SQLPy\step1_data_processing.sql  </td><td> Handles missing data </td></tr>
<tr><td> .\SQLPy\step2_feature_engineering.sql  </td><td> Standardizes measures and creates <code>number_of_issues</code> and <code>lengthofstay_bucket</code> </td></tr>
<tr><td> .\SQLPy\step3a_splitting.sql  </td><td> Splits data into train and test </td></tr>
<tr><td> .\SQLPy\step3b_training.sql  </td><td> Trains and scores a gradient boosted trees model (rx_btrees) or Random Forest (rx_dforest)  </td></tr>
<tr><td> .\SQLPy\step3c_testing_evaluating.sql  </td><td> Scores and evaluates models </td></tr>


</table>

* See [ For the Database Analyst](dba.html) for more information about these files.
* Follow the [PowerShell Instructions](Powershell_Instructions.html) to execute the PowerShell script which automates the running of all these .sql files.

### Resources for the Solution Package
------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>

<tr><td> .\Resources\create_user.sql </td><td> Used during initial SQL Server setup to create the user and password and grant permissions. </td></tr>
<tr><td> .\Resources\Data_Dictionary.xlsx   </td><td> Description of all variables in the LengthOfStay.csv data file</td></tr>
<tr><td> .\Resources\Images\ </td><td> Directory of images used for the  Readme.md  in this package. </td></tr>
</table>




[&lt; Home](index.html)
