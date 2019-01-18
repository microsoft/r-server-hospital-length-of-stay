---
layout: default
title: Typical Workflow for GitHub Deployment
---


## Typical Workflow for GitHub Deployment
---------------------------------------------------------------

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
This guide assumes you have deployed the {{ site.solution_name }} solution to Azure using the <b>Deploy to Azure</b> button on <a href="https://github.com/Microsoft/r-server-hospital-length-of-stay">GitHub</a>.<br/>Click the button below to deploy it now:<br/>
<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FMicrosoft%2Fr-server-hospital-length-of-stay%2Fmaster%2FArmTemplates%2Fhospital_arm.json"><image src="https://raw.githubusercontent.com/Azure/Azure-CortanaIntelligence-SolutionAuthoringWorkspace/master/docs/images/DeployToAzure.PNG" alt="Deploy to Azure"/></a>
<br/>
<em>If you are using your own SQL Server for this solution, <a href="Typical_Workflow.html">use this guide instead</a>.</em>
</div>

To demonstrate a typical workflow, we'll introduce you to a few personas.  You can follow along by performing the same steps for each persona.  While each persona would be working on a different computer, for simplicity, your Virtual Machine (VM) has all the tools each persona would use on the same machine.

 <a name="step1" id="step1"></a>
        
        {% include step1.md %}

This has already been done on your GitHub deployed VM.

 <a name="step2" id="step2"></a>

## Step 2: Data Prep and Modeling with Debra the Data Scientist (Code from R IDE)
------------------------------------------------------------------

{% include dsintro.md %}

<!-- R/Python Text -->
<div>
    <div class="card ">
        <div class="card-block">
            <!-- Nav tabs -->
            <ul class="nav nav-tabs" role="tablist">
                <li class="nav-item "><a class="nav-link active" href="#r1" aria-controls="R" data-toggle="tab">R</a></li>
                <li class="nav-item"><a class="nav-link" href="#python1" aria-controls="Python" data-toggle="tab">Python</a></li>
            </ul>
            <!-- Tab panes -->
            <br/>
            <div class="tab-content">
                <div role="tabpanel" class="tab-pane active" id="r1">
                    {% include rsetup.html %}
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


 <a name="step4" id="step4"></a>

    {% include step4.md %}

<a name="step5" id="step5"></a>

{% include step5.md %}
