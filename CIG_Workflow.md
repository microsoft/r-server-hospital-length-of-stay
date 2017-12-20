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
        <li><a href="#step5">Step 5: Use the Model during Admission</a></li>
        </div>
    </div>
    
    <div class="col-md-6">

        {% include typicalintro.md %}

    </div>
</div>

 {% include typicalintro1.md %}
 
<div class="alert alert-warning" role="alert"> 
This guide assumes you have deployed the {{ site.solution_name }} solution from the <a href="{{ site.aka_url }}">Cortana Intelligence Gallery</a>.  

<li>If you are using your own SQL Server for this solution, <a href="Typical_Workflow.html">use this guide instead</a>.</li>
</div>

To demonstrate a typical workflow, we'll introduce you to a few personas.  You can follow along by performing the same steps for each persona.  While each persona would be working on a different computer, for simplicity, your Virtual Machine (VM) has all the tools each persona would use on the same machine.

 <a name="step1" id="step1"></a>
        
        {% include step1.md %}

This has already been done on your deployed Cortana Intelligence Gallery VM.

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
