SQL Server on the VM has been set up with a user `rdemo` and a default password of `D@tascience`.  If you wish to change the password, connect to the VM, log into SSMS with Windows Authentication and execute the following query:

```  
        ALTER LOGIN rdemo WITH PASSWORD = 'newpassword';  
```     
