---
layout: default
title: Typical Workflow for Cortana Intelligence Gallery Deployment
---


## Typical Workflow for Cortana Intelligence Gallery Deployment
---------------------------------------------------------------

<div class="row">
    <div class="col-md-6">
        <div class="toc">
        <li><a href="#step1">Step 1: Server Setup and Configuration</a></li>
        <li><a href="#step2">Step 2: Data Prep and Modeling</a></li>
        <li><a href="#step3">Step 3: Operationalize</a></li>
        <li><a href="#step4">Step 4: Deploy and Visualize</a></li>
        </div>
    </div>
    
    <div class="col-md-6">

        {% include typicalintro.md %}

    </div>
</div>

 {% include typicalintro1.md %}

This guide assumes you have deployed the {{ site.solution_name }} solution from the [Cortana Intelligence Gallery]({{ site.aka_url }}).  

*If you are using your own SQL Server for this solution, [use this guide instead](Typical_Workflow.html).*

{% include password.md %}

To demonstrate a typical workflow, we'll introduce you to a few personas.  You can follow along by performing the same steps for each persona.  While each persona would be working on a different computer, for simplicity, your Virtual Machine (VM) has all the tools each persona would use on the same machine.  (Or you can use your own computer with optional instructions below.  If using your computer make sure to follow the instructions above to change the password and add appropriate firewall rules.)

 <a name="step1" id="step1"></a>
        
        {% include step1.md %}

This has already been done on your deployed Cortana Intelligence Gallery VM.

 <a name="step2" id="step2"></a>

## Step 2: Data Prep and Modeling with Debra the Data Scientist (Code from R IDE)
------------------------------------------------------------------

{% include dsintro.md %}


Debra would work on her own machine, using  [R Client](https://msdn.microsoft.com/en-us/microsoft-r/install-r-client-windows) to execute these R scripts. In case you want to run the code from the VM, R Client has already been installed.

Debra uses an IDE to run R.  On your VM, R Tools for Visual Studio is installed.  You will however have to either log in or create a new account for using this tool.  If you prefer, you can <a href="rstudio.html">download and install RStudio</a> on your machine instead. 
  
OPTIONAL: You can execute the R code on your local computer if you wish, but you must first  <a href="local.html">prepare both the VM and your computer</a>.  XXXIF THERE IS A NOTEBOOK: Or you can <a href="jupyter.html">view and execute the R code in a Jupyter Notebook on the VM</a>.

Now that Debra's environment is set up, she  opens her IDE and creates a Project.  To follow along with her, open the **{{ site.folder_name }}/R** directory on the VM desktop, (or the **{{ site.code }}/R** directory on your local machine).  There you will see three files with the name `{{ site.solution_name }}`.

* If you are using Visual Studio, double click on the "Visual Studio SLN" file.
* If you are using RStudio, double click on the "R Project" file.

    {% include step2.md %}

 <a name="step3" id="step3"></a>

    {% include step3.md %}

You can find this script in the **SQLR** directory, and execute it yourself by following the [PowerShell Instructions](Powershell_Instructions.html).  As noted earlier, this was already executed when your VM was first created.  

 <a name="step4" id="step4"></a>

    {% include step4.md %}