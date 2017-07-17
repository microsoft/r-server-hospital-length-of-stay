
## Step 3: Operationalize with Debra and Danny
------------------------------------------------

Debra has completed her tasks.  She has connected to the SQL database, executed code from her R IDE that pushed (in part) execution to the SQL machine. She has scored data, created LOS predictions, and also created a summary dashboard which she will hand off to Caroline and Chris - see below.

These models will be used daily on new data as new patients are admitted.  Instead of going back to Debra each time, Danny can operationalize the code in TSQL files which he can then be scheduled to run daily.

Debra hands over her scripts to Danny who adds the code to the database as stored procedures, using embedded R code, or SQL queries.  

Danny also creates a  production pipeline, which uploads the daily data and then cleans it, performs feature engineering, and scores and saves predictions into a new table.

You can create the production pipeline using the following commands in a PowerShell window:

1.	Click on the windows key on your keyboard. Type the words `PowerShell`.  Right click on Windows Powershell to and select `Run as administrator` to open the PowerShell window.


2.	In the Powershell command window, type the following command:
  
    ```
    Set-ExecutionPolicy Unrestricted -Scope Process
    ```

    Answer `y` to the prompt to allow the following scripts to execute.


3.  Now CD to the **{{ site.folder_name }}/SQLR** directory and run one of the two following commands, inserting your server name (or "." if you are on the same machine as the SQL server), database name, username, and password.

    * Run with no prompts: 
    
        ```
        .\{{ site.ps1_name }} -ServerName "Server Name" -DBName "Database Name" -username "" -password "" -is_production "Y" -uninterrupted "Y"  
        ```
    * Run with prompts:

        ```
        .\{{ site.ps1_name }} -ServerName "Server Name" -DBName "Database Name" -username "" -password "" -is_production "Y" -uninterrupted "N"  
        ```

    * For example, uninterrupted mode for some user  "rdemo" user with a password of "D@tascience", the command would be: 

        ```
        .\{{ site.ps1_name }} -ServerName "localhost" -DBName "{{ site.db_name }}" -username "rdemo" -password "D@tascience" -is_production "Y" -uninterrupted "Y"  
        ```

You can explore these stored procedures by logging into SSMS and opening the `Programmability>Stored Procedures` section of the `{{ site.db_name }}` database.


