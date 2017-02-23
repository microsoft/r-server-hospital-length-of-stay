---
layout: default
title: Using R Tools for Visual Studio with R Server
---


## Set Up Visual Studio for R Server

Visual Studio needs to use R Server for the code for this solution.  Follow the instructions below to set up Visual Studio to use R Server. 
<div class = "label label-info">
On the VM deployed from <a href="{{ site.aka_url }}">Cortana Intelligence Gallery</a> you may see an alert that the path for R is no longer found. <strong>Do not agree</strong> to this alert to install R Client, simply update the path as shown below.
</div>
<ol>
<li>Launch Visual Studio.</li>
<li> Update the path to R.</li>
<ol type="a">
<li>From the <code>R Tools</code> menu, choose <code>Options</code>.</li>
<li>In the R Tools section, update the path to R to point to R Server:</li>
<ul>
<li><code>C:\Program Files\Microsoft\R Server\R_SERVER</code></li>
</ul></ol>
<li>Exit Visual Studio.</li>
<li>When you relaunch Visual Studio, R Client will now be the default R engine.</li>
</ol>


 

<a href="CIG_Workflow.html#step2">Return to Typical Workflow for Cortana Intelligence Gallery Deployment<a>