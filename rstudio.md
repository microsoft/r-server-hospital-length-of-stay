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
<ul><li>On the VM deployed from <a href="{{ site.aka_url }}">Cortana Intelligence Gallery</a> the path is <code>C:\Program Files\Microsoft SQL Server\130\R_SERVER</code></li>
<li>If you installed R Server on your own computer, the path is <code>C:\Program Files\Microsoft\R Client\R_SERVER\bin\x6b</code></li></ul>
</ol>
<li>Exit RStudio.</li>
<li>When you relaunch RStudio, R Client will now be the default R engine.</li>
</ol>


 

<a href="CIG_Workflow.html#step2">Return to Typical Workflow for Cortana Intelligence Gallery Deployment<a>