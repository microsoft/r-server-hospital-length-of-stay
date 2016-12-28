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
<tr><td> .\Data\XXXFILENAME.csv </td><td> XXXDESCRIPTION </td></tr>
</table>

### Model Development in R
-------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> {{ site.jupyter_name}}  </td><td> Contains the Jupyter Notebook file that runs all the .R scripts. </td></tr>
<tr><td>SQL_connection.R </td><td> Contains details of connection to SQL Server used in all other scripts. </td></tr>
<tr><td>XXNAMEX.R </td><td> XXXDESCRIPTION </td></tr>
  
</table>


* See the [Typical Workflow](Typical.html) documentation to execute these scripts.


### Operationalize in SQL 2016 
-------------------------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>
<tr><td> .\SQLR\XXXFILENAME.sql </td><td> XXXDESCRIPTION </td></tr>

</table>


* Follow the [PowerShell Instructions](Powershell_Instructions.html) to execute the PowerShell script which automates the running of all these .sql files.





### Resources for the Solution Package
------------------------------------

<table class="table table-striped table-condensed">
<tr><th> File </th><th> Description </th></tr>

<tr><td> .\Resources\createuser.sql </td><td> Used during initial SQL Server setup to create the user and password and grant permissions. </td></tr>
<tr><td> .\Resources\XXXFILENAME.xlsx  </td><td> XXXDESCRIPTION.</td></tr>
<tr><td> .\Resources\Images\ </td><td> Directory of images used for the  Readme.md  in this package. </td></tr>
</table>




[&lt; Home](index.html)
