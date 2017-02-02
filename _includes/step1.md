
## Step 1: Server Setup and Configuration with Danny the DB Analyst
----------------------------------------------------------------

Let me introduce you to  Danny, the Database Analyst. Danny is the main contact for anything regarding the SQL Server database that stores all the patient data at our hospitals.  

Danny was responsible for installing and configuring the SQL Server.  He has added a user named 'rdemo' with all the necessary permissions to execute R scripts on the server and modify the `{{ site.db_name }}` database. This was done through the **create_user.sql** file.  
