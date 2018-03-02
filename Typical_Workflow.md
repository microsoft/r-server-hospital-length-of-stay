---
layout: default
title: Typical Workflow for for On-Prem Deployment
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
        <li><a href="#step5">Step 5: Use the Model during Admission</a></li>

        </div>
    </div>

    <div class="col-md-6">

        {% include typicalintro.md %}

    </div>
</div>

 {% include typicalintro1.md %}

<div class="alert alert-warning" role="alert"> 
This guide assumes you are using an on premises SQL Server for this solution.  

<li>f you have deployed the {{ site.solution_name }} solution from the<a href="{{ site.aka_url }}">Azure AI Gallery</a> you should instead <a href="CIG_Workflow.html">use this guide</a>.</li>
</div>

To demonstrate a typical workflow, we'll introduce you to a few personas.  You can follow along by performing the same steps for each persona.  

NOTE: If you’re just interested in the outcomes of this process we have also created a fully automated solution that simulates the data, trains and scores the models by executing PowerShell scripts. This is the fastest way to deploy the solution on your machine. See [PowerShell Instructions](Powershell_Instructions.html) for this deployment.

If you want to follow along and have *not* run the PowerShell script, you will need to first create a database table in your SQL Server.  You will then need to replace the connection_string at the top of each R file with your database and login information.

 <a name="step1" id="step1"></a>

     {% include step1.md %} 
     
You can perform these steps in your environment by using the instructions in <a href="START_HERE.html">START HERE</a>. 


 <a name="step2" id="step2"></a>

## Step 2: Data Prep and Modeling with Debra the Data Scientist (Code from R IDE)
------------------------------------------------------------------

{% include dsintro.md %}


<!-- R/Python Text -->
<div>
    <div class="panel panel-default">
        <div class="panel-heading">
            <!-- Nav tabs -->
            <ul class="nav nav-tabs" role="tablist">
                <li class="active"><a href="#r1" aria-controls="R" role="tab" data-toggle="tab">R</a></li>
                <li><a href="#python1" aria-controls="Python" role="tab" data-toggle="tab">Python</a></li>
            </ul>
            <!-- Tab panes -->
            <br/>
            <div class="tab-content">
                <div role="tabpanel" class="tab-pane active" id="r1">
                    {% include rsetup2.html %}
                    <br/>
                    {% include step2.html %}
                </div>
                <div role="tabpanel" class="tab-pane" id="python1">
                    {% include pysetup.html %}
                    <br/>
                    {% include step2py.html %}
                </div>
            </div>
        </div>
    </div>
</div>
<!-- END R/Python Text -->




 <a name="step3" id="step3"></a>

   {% include step3.md %}


You can find this script in the **SQLR** or **SQLPY** directory, and execute it yourself by following the [PowerShell Instructions](Powershell_Instructions.html).   As noted earlier, this is the fastest way to execute all the code included in this solution.  (This will re-create the same set of tables and models as the above R/Python scripts.)

<a name="step4" id="step4"></a>

    {% include step4.md %}

<a name="step5" id="step5"></a>

    {% include step5.md %}
