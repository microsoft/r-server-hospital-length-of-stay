---
layout: default
title: ODBC Setup
---


<h2>Set up Connection between SQL Server and PowerBI  </h2>

Follow the instructions below to set up a connection between your SQL Server database and PowerBI.  Perform these steps after you have created the <code>{{ site.db_name }}</code> database.

<ol>
<li>	Push the <code>Windows</code> key on your keyboard</li>
<li>	Type <code>ODBC</code> </li>
<li>	Open the correct app depending on what type of computer you are using (64 bit or 32 bit). To find out if your computer is running 32-bit or 64-bit Windows, do the following:</li>
<ul><li>	Open System by clicking the <code>Start</code> button, clicking <code>Control Panel</code>, clicking <code>System and Maintenance</code>, and then clicking <code>System</code>.</li>
<li>.	Under System, you can view the system type</li></ul>
<li>	Click on <code>Add</code>
  <br/>
<img src="images/odbc1.png" width="50%" >
</li>
<li>	Select <code>Server Native Client 11.0</code> and click finish
   <br/>
<img src="images/odbc2.png" width="50%" >
 </li>
<li>	Under Name, Enter <code>{{ site.db_name }}</code>. Under Server enter the MachineName from the SQL Server logins set up section. Press <code>Next</code>.
   <br/>
<img src="images/odbc3.png" width="50%" >
</li>
<li>	Select <code>SQL Server authentication</code> and enter the credentials you created in the SQL Server set up section. Press <code>Next</code>
   <br/>
<img src="images/odbc4.png" width="50%" >
</li>
 

<li>	Check the box for <code>Change the default database to</code> and enter <code>{{ site.db_name }}</code>. Press 
<code>Next</code>.
   <br/>
<img src="images/odbc5.png" width="50%" >
</li>
<li>Press <code>Finish</code>
  <br/>
<img src="images/odbcfinish.png" width="50%" > 
</li>
<li>Press <code>Test Data Source</code>
  <br/>
<img src="images/odbc6.png" width="50%" >
</li> 
<li>	Press <code>OK</code> in the new popover. This will close the popover and return to the previous popovers.
   <br/>
<img src="images/odbc7.png" width="50%" >
</li>
<li>	Now that the Data Source is tested. Press <code>OK</code>
   <br/>
<img src="images/odbc8.png" width="50%" >
</li>
<li>	Finally, click <code>OK</code> and close the window 
   <br/>
<img src="images/odbc9.png" width="50%">
</li>
</ol>

You are now ready to use this connection in PowerBI by following the [instructions here](Visualize_Results.html).
	