---
layout: default
title: Setup for Local Code Execution
---
## Setup for Local Code Execution

You can execute code on your local computer and push the computations to the SQL Server on the VM  that was created by the Cortana Intelligence Gallery. But first you must perform the following steps. 

## On the VM: Configure VM for Remote Access

Connect to the VM to perform the following steps.

You must open the Windows firewall on the VM to allow a connection to the SQL Server. To open the firewall, execute the following command in a PowerShell window on the VM:

<code class="highlighter-rouge">
netsh advfirewall firewall add rule name="SQLServer" dir=in action=allow protocol=tcp localport=1433 
</code>

## On Your Local Computer 
Now switch to your local computer and perform the following steps to get the code and setup your local environment.

### Obtain code

To copy the solution code to your computer: 
1.  Open a PowerShell window.
2.  Navigate to the directory of your choice, and execute the following command:  

    ```
    git clone {{ site.code_url }} {{ site.folder_name }}
    ```

This will create a folder **{{ site.folder_name }}** containing the full solution package.

###  R

Perform these steps on your local computer.

If you use your local computer you will need to have a copy of R Client on your local machine, <a href="rstudio.html"> installed and configured</a> for your IDE.  

###  Python

Perform these steps on your local computer.

See <a href="https://docs.microsoft.com/en-us/machine-learning-server/install/python-libraries-interpreter">How to install custom Python packages and interpreter locally on Windows</a>.

<a href="CIG_Workflow.html#step2">Return to Typical Workflow for Cortana Intelligence Gallery Deployment<a>