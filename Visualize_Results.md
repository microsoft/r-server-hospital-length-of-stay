---
layout: default
title: Visualizing Results with PowerBI
---



## Visualizing Results with PowerBI
-----------------------------------

These instructions show you how to replace the cached data in the PowerBI dashboard with data from your SQL Server solution, by using an ODBC connection to the SQL Database table. 

Steps 1-10 only need to be performed once. After you have performed this once, you can simply <a href="#laststep">
skip to step 11</a> to see new results after any new model scoring. 


1.	Open the `{{ site.pbi_name }}` file in the {{ site.folder_name }} folder. Click on `Edit Queries` in the toolbar.  
 <br/>
 <img src="images/vis1.png" >

2.	In the Query Editor, with the first Query selected (Metadata_Facilities), click on the `Advanced Editor`.
 <br/>
 <img src="images/vis2.png" >


3. In the dialog, replace the pathname with the the path from your computer.  If you are on a VM deployed from Cortana Intelligence Gallery, replace the user name with the name you used to login to the VM. Click `Done` on the dialog.
 <br/>
 <img src="images/vis3.png" >

4.	9.	Next, click on `Close` and `Apply`. If prompted, select `Yes`.
 <br/>
 <img src="images/vis4.png" >

5.	Now in the Dashboard window, click on `Refresh`.
 <br/>
 <img src="images/vis5.png"  > 


6.	You may be prompted one or more times for permission to Run Native Database QUeries.  Select Run.  
 <br/>
 <img src="images/vis6.png"  > 

7.	If prompted to login, select Database in the dialog and enter your login details.  (The default if you have not changed it is user `rdemo`, password `D@tabase`).
 <br/>
 <img src="images/vis7.png"  > 

8. Finally select `OK` to the encription alert.
 <br/>
 <img src="images/vis8.png"  >

9.	You are now viewing data from your SQL Database, rather than the imported data that was part of the initial solution package.  Updates from the SQL Database will be reflected each time you hit `Refresh`. 


[&lt; Home](index.html)