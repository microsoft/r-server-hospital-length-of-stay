---
layout: default
title: Typical Workflow for for On-Premises Deployment
---


## Typical Workflow for On-Premises Deployment
--------------------------------------------------------------

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


This guide assumes you are using your own SQL Server for this solution.  

*If you have deployed the {{ site.solution_name }} solution from the [Cortana Intelligence Gallery]({{ site.aka_url }}) you should instead [use this guide](CIG_Workflow.html).*


To demonstrate a typical workflow, we'll introduce you to a few personas.  You can follow along by performing the same steps for each persona.  

NOTE: If you’re just interested in the outcomes of this process we have also created a fully automated solution that simulates the data, trains and scores the models by executing PowerShell scripts. This is the fastest way to deploy the solution on your machine. See [PowerShell Instructions](Powershell_Instructions.html) for this deployment.

If you want to follow along and have *not* run the PowerShell script, you will need to first create a database table in your SQL Server.  You will then need to replace the connection_string at the top of each R file with your database and login information.

 <a name="step1" id="step1"></a>

     {% include step1.md %} 
     
You can perform these steps by using the instructions in <a href="START_HERE.html">START HERE</a>. 


 <a name="step2" id="step2"></a>

## Step 2: Data Prep and Modeling with Debra the Data Scientist
-----------------------------------------------------------------

{% include dsintro.md %}

Debra will work on her own machine, using  [R Client](https://msdn.microsoft.com/en-us/microsoft-r/install-r-client-windows) to execute these R scripts. She will need to [install and configure an R IDE](https://msdn.microsoft.com/en-us/microsoft-r/r-client-get-started#configure-ide) to use with R Client.  

<img src="images/project.png">

Now that Debra's environment is set up, she  opens her IDE and creates a Project.  To follow along with her, open the **{{ site.code }}/R** directory.  There you will see three files with the name `{{ site.solution_name }}`.

* If you use Visual Studio, double click on the Visual Studio SLN file.
* If you use RStudio, double click on the "R Project" file.

    {% include step2.md %}


 <a name="step3" id="step3"></a>

   {% include step3.md %}


You can find this script in the **SQLR** directory, and execute it yourself by following the [PowerShell Instructions](Powershell_Instructions.html).   As noted earlier, this is the fastest way to execute all the code included in this solution.  (This will re-create the same set of tables and models as the above R scripts.)

<a name="step4" id="step4"></a>

    {% include step4.md %}
