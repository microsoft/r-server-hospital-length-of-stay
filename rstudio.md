---
layout: default
title: Using RStudio with R Server
---

## Install RStudio

If you don't have RStudio installed yet, <a href="https://www.rstudio.com/products/rstudio/download2/" target="_blank">get it here</a>.

## Set Up RStudio for R Client
RStudio needs to use R Server in order for the code for this solution.  Follow the instructions below to set up RStudio to use R Server. 
<ol>
<li>Launch RStudio.</li>
<li> Update the path to R.</li>
<ol type="a">
<li>From the <code>Tools</code> menu, choose <code>Global Options</code>.</li>
<li>In the General tab, update the path to R to point to R Server:</li>
<ul><li>On the VM deployed from <a href="{{ site.aka_url }}">Azure AI Gallery</a> the path is <code>C:\Program Files\Microsoft\ML Server\R_SERVER</code></li>
</ol>
<li>Exit RStudio.</li>
<li>When you relaunch RStudio, R Client will now be the default R engine.</li>
</ol>


 

<a href="CIG_Workflow.html#step2">Return to Typical Workflow for Azure AI Gallery Deployment<a>