---
layout: default
title: PowerShell Instructions
---


## PowerShell Instructions
---------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
            <li> <a href="#setup">Setup</a></li>
            <li> <a href="#execute-powershell-script">Execute PowerShell Script</a></li>
            <li> <a href="#score-production-data">Score Production Data</a></li>
            <li> <a href="#review-data">Review Data</a></li>
            <li> <a href="#visualizing-results">Visualizing Results</a> </li>
            <li> <a href="#other-steps">Other Steps</a></li>
        </div>
    </div>
    <div class="col-md-6">
        If you have deployed a VM through the  
        <a href="{{ site.aka_url }}">Azure AI Gallery</a>, all the steps below have already been performed and your database on that machine has all the resulting tables and stored procedures.  Skip to the <a href="CIG_Workflow.html">Typical Workflow</a> for a description of how these files were first created in R by a Data Scientist and then deployed to SQL stored procedures.
    </div>
</div>
If you are configuring your own server, or if you want to reset your VM to its initial state, continue with the steps below to run the PowerShell script.

## Setup 
-----------

First, make sure you have set up your SQL Server by  <a href="SetupSQL.html">following these instructions</a>.  Then proceed with the steps below to run the solution template using the automated PowerShell file. 

## Create Data and Train Model
----------------------------

Running this PowerShell script will create the data tables and stored procedures for the the operationalization of this solution, both in R (in the `{{ site.db_name }}_R` database) and Python (in the `{{ site.db_name }}_Py` database).  It will also execute these procedures to create full database with results of the steps  – dataset creation, modeling, and scoring as described  [here](dba.html).

1. Log onto the computer that contains the SQL Server you wish to use.

1. Install [Git](https://gitforwindows.org/) if it is not already present.  During the install, check the box to add LFS support.

1. If you wish to install the sample website to demonstrate using the model, install [node.js](https://nodejs.org/en/) if it is not already present.

1. Download  <a href="https://raw.githubusercontent.com/Microsoft/r-server-hospital-length-of-stay/master/Resources/ActionScripts/HospitalSetup.ps1" download>HospitalSetup.ps1</a> to your computer.

1. Open a command or PowerShell window as Administrator.

1. CD to the directory where you downloaded the above .ps1 file and execute the command:

    .\HospitalSetup.ps1

1. Answer the prompts.  Make sure to accept installation of NuGet if prompted.

1. This will make the following modification to your SQL Server:
    * Installs the SQL Server PowerShell module. If this is already installed, it will update it if necessary.
    * Changes Authentication Method to Mixed Mode, which is needed in this version of the solution.
    * Creates the SLQRUserGroup for running R and Python code.
    * Reconfigures SQL Server to allow running of external scripts.
    * Creates a user with provided username and password
    * Elevates user's credentials to SA.
    * Clones the solution code and data into the c:\Solutions\{{ site.folder_name }} directory
    * Creates the solution database `{{ site.db_name }}_R` and configures an ODBC connection to the database.
    * Executes the stored procedure `Initial_Run_Once_R` to run the entire workflow with R for this solution.
    * If SQL Server 2017: creates the solution database `{{ site.db_name }}_Py` and configures an ODBC connection to the database.
    * If SQL Server 2017: Executes the stored procedure `Initial_Run_Once_Py` to run the entire workflow with Python for this solution.
    * Installs the sample website if [node.js](https://nodejs.org/en/) is installed.


    
## Review Data
--------------

Once the PowerShell script has completed successfully, log into the SQL Server Management Studio to view all the datasets that have been created in the `{{ site.db_name }}_R` and `{{ site.db_name }}_Py` databases.
Hit `Refresh` if necessary.
<br/>

[Click here](tables.html) to view more information about each of these tables.

Right click `Boosted_Prediction` and select `View Top 1000 Rows` to preview the scored regression results.  

[Click here](tables.html) to view the details all tables created in this solution.

## Visualizing Results 
---------------------

You've now  created and processed data, created models, and predicted LOS as described  [here](data-scientist.html). This PowerShell script also created the stored procedures that can be used to score new data in the future.  

Let's look at our current results. Proceed to <a href="Visualize_Results.html">Visualizing Results with PowerBI</a>.

## Sample Website for Native Scoring
---------
[This sample website](web-developer.html) shows how you might use the solution to show an estimate of the patient's length of stay during the admission process.  


## Other Steps
----------------

You've just completed the fully automated solution that simulates the data, trains and scores the models by executing PowerShell scripts.  

See the [Typical Workflow](Typical.html) for a description of how these files were first created in R by a Data Scientist and then incorporated into the SQL stored procedures that you just deployed.