---
layout: default
title: Visualizing Results with PowerBI
---


## Visualizing Results with PowerBI
-----------------------------------

This page explains how the data in PowerBI is filtered to show "today's" patient population, and shows how to update the cached data with data from your SQL Server. 

### Dashboard Details

This dashboard uses data for the hospital over the course of a year. For planning purposes, there would be new data incoming each day from the production pipeline.  We have simulated this in the current file by selecting a date in our static data to represent "today".  The variable `ScoredData[Today]` represents this arbitrary date: `Today = DATEVALUE("4/1/2012")`. If you were instead using live data, the calculation would use the TODAY() function: `Today = TODAY()`.

Once `Today` has been created, a second variable is calculated.  A patient is in the hospital today if they have been admitted and have not yet been discharged:  `HereToday = ([admitdt] < [Today] ) && ([dischargedt] > [Today])`. 

Finally, the dashboard pages are filtered to display only data for patients that are here today.
 <br/>
 <img src="images/vis9.png"  >

### Configure PowerBI to Access Data 
In order to replace the cached data with data from your SQL Server, follow the steps below.

First, try refreshing the data using the <code>Refresh</code> button on the toolbar.
Use your Windows credentials and allow an insecure connection if prompted.

If this does not work, you may need to modify the connection information by using the steps below.

1.	Open the `{{ site.pbi_name }}` file in the {{ site.folder_name }} folder. Click on `Edit Queries` in the toolbar.  
 <br/>
 <img src="images/vis1.png" >

2.	 In the Query Editor, with the first Query selected (Metadata_Facilities), if the data table does not appear, click on the `Advanced Editor`.
 <br/>
 <img src="images/vis2.png" >
 In the dialog, replace the pathname with the the path from your computer.  Click `Done` on the dialog.
 <br/>
 <img src="images/vis3.png" >

4. (Skip this step if your SQL Server is on the same machine as your PowerBI file.) If you are connecting to a SQL Server on a different machine, in the next three queries replace "localhost" with the SQL Server IP address.  For now, ignore the permission alerts.
 <img src="images/vis3b.png">

5.	Next, click on `Close` and `Apply`. If prompted, select `Yes`.
 <br/>
 <img src="images/vis4.png" >

6.	You may be prompted one or more times for permission to Run Native Database Queries. If you don't see this, select `Refresh` in the Dashboard window.
 <br/>
 <img src="images/vis5.png"  > 


7.	Once you see the Run Native Database Queries, select `Run`.    
 <br/>
 <img src="images/vis6.png"  > 

8.	If prompted to login, select Database in the dialog and enter your login details.
 <br/>
 <img src="images/vis7.png"  > 

9. Finally select `OK` to the encription alert.
 <br/>
 <img src="images/vis8.png"  >

10.	You may see more than on of the Run Database Queries dialogs.  Continue to select `Run` on each; you will no longer have to supply login information.

11.  You are now viewing data from your SQL Database, rather than the imported data that was part of the initial solution package.  Updates from the SQL Database will be reflected each time you hit `Refresh`. 





[&lt; Home](index.html)