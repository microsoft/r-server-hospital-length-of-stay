
## Step 3: Operationalize with Debra and Danny
------------------------------------------------

Debra has completed her tasks.  She has connected to the SQL database, executed code from her R IDE that pushed (in part) execution to the SQL machine to XXXDESCRIBE. She has scored data, created recommendations, and also created a summary dashboard which she will hand off to Bernie - see below.

While this task is complete for the current set of leads, our company will want to perform these actions XXXDESCRIBE WHEN.  Instead of going back to Debra each time, Danny can operationalize the code in TSQL files which he can then run himself XXXDESCRIBE WHEN.

Debra hands over her scripts to Danny who adds the code to the database as stored procedures, using embedded R code, or SQL queries.  You can see these procedures by logging into SSMS and opening the `Programmability>Stored Procedures` section of the `{{ site.db_name }}` database.

Log into SSMS using the `rdemo` user with SQL Server Authentication - the default password upon creating the solution was `D@tascience`, unless you changed this password.