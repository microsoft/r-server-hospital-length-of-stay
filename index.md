---
layout: default
title: HOME
---


This solution enables a predictive model for Length of Stay for in-hospital admissions. Length of Stay (LOS) is defined in number of days from the initial admit date to the date that the patient is discharged from any given hospital facility. There can be significant variation of LOS across various facilities and across disease conditions and specialties even within the same healthcare system. Advanced LOS prediction at the time of admission can greatly enhance the quality of care as well as operational workload efficiency and help with accurate planning for discharges resulting in lowering of various other quality measures such as readmissions.

For customers who prefer an on-premise solution, the implementation with Microsoft Machine Learning Services is a great option that takes advantage of the powerful combination of SQL Server and the R or Python languages. We have modeled the steps in the template after a realistic team collaboration on a data science process. Data scientists do the data preparation, model training, and evaluation from their favorite IDE. DBAs can take care of the deployment using SQL stored procedures with embedded code. Power BI is also available for analysts to visualize the deployed results. We also show how each of these steps can be executed on a SQL Server client environment such as SQL Server Management Studio. A Windows PowerShell script that invokes the SQL scripts that execute the end-to-end modeling process is provided for convenience. 

This solution starts with data stored in SQL Server.  The data scientist works from the convenience of an IDE on her client machine, while <a href="https://msdn.microsoft.com/en-us/library/mt604885.aspx">setting the computation context to SQL</a>.  When she is done, her code is operationalized as stored procedures in the SQL Database. Finally, the data, along with the predicted LOS are then visualized with PowerBI.  
<img src="images/diagram.png">

An example website is also provided to show the use of native scoring in SQL.  

