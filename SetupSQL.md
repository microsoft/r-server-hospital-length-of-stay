---
layout: default
title: "On-Prem: Setup SQL Server 2017"
---

## On-Prem: Setup SQL Server
--------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
            <li><a href="#prepare-your-sql-server-installation">Prepare your SQL Server 2017 Installation</a></li>
            <li><a href="#ready-to-run-code">Ready to Run Code</a></li>
        </div>
    </div>
    <div class="col-md-6">
        The instructions on this page will help you to add this solution to your on premises SQL Server 2017.  
        <p>
        If you instead would like to try this solution out on a virtual machine, visit <a href="https://github.com/Microsoft/r-server-hospital-length-of-stay">GitHub</a> and use the <b>Deploy to Azure</b> button. <br/>Click the button below to deploy it now:<br/>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoft%2Fr-server-hospital-length-of-stay%2Fmaster%2FArmTemplates%2Fhospital_arm.json"><image src="https://raw.githubusercontent.com/Azure/Azure-CortanaIntelligence-SolutionAuthoringWorkspace/master/docs/images/DeployToAzure.PNG" alt="Deploy to Azure"/></a>
<br/>
All the configuration described below will be done for you, as well as the initial deployment of the solution. </p>
    </div>
</div>

## Prepare your SQL Server Installation
-------------------------------------------

The rest of this page assumes you are configuring your on premises SQL Server 2016 or higher for this solution.

If you need a trial version of SQL Server 2016, see [What's New in SQL Server 2016](https://msdn.microsoft.com/en-us/library/bb500435.aspx) for download or VM options. 

For more information about SQL server 2017 and R service, please visit: <a href="https://msdn.microsoft.com/en-us/library/mt604847.aspx">https://msdn.microsoft.com/en-us/library/mt604847.asp</a>

Complete the steps in the Set up SQL Server R Services (In-Database) Instructions. The set up instructions file can found at  <a href="https://msdn.microsoft.com/en-us/library/mt696069.aspx" target="_blank"> https://msdn.microsoft.com/en-us/library/mt696069.aspx</a>

* If you are using SQL Server 2016, make sure R Services (In-Database) is installed. 
* If you are using SQL Server 2017, make sure Machine Learning Services (In-Database) is installed.

## Ready to Run Code 
---------------------

* See <a href="Powershell_Instructions.html">PowerShell Instructions</a> to install and run the code for this solution.
