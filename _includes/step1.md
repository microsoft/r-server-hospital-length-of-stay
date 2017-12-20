
## Step 1: Server Setup and Configuration with Danny the DB Analyst
----------------------------------------------------------------

Let me introduce you to  Danny, the Database Analyst. Danny is the main contact for anything regarding the SQL Server database that stores all the patient data at our hospitals.  

Danny was responsible for installing and configuring the SQL Server.  He has added a user with all the necessary permissions to execute R and Python scripts on the server and modify the `{{ site.db_name }}_R` and `{{ site.db_name }}_Py`   databases. 

You can see an example of creating a user in the **Hospital/Resources/exampleuser.sql** query.   
