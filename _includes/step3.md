
## Step 3: Operationalize with Debra and Danny
------------------------------------------------

Debra has completed her tasks.  She has connected to the SQL database, executed code that pushed (in part) execution to the SQL machine. She has scored data, created LOS predictions, and also created a summary dashboard which she will hand off to Caroline and Chris - see below.

These models will be used daily on new data as new patients are admitted.  Instead of going back to Debra each time, Danny can operationalize the code in TSQL files which he can then be scheduled to run daily.

Debra hands over her scripts to Danny who adds the code to the database as stored procedures, using both SQL queries and embedded R code (in the `{{ site.db_name }}_R` database) or embedded Python code (in the `{{ site.db_name }}_Py` database).  

Danny also creates a  production pipeline, which uploads the daily data and then cleans it, performs feature engineering, and scores and saves predictions into a new table.

You can explore these stored procedures by logging into SSMS and opening the `Programmability>Stored Procedures` section of the `{{ site.db_name }}_R` or `{{ site.db_name }}_Py` database.


