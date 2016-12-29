---
layout: default
title: For the Business Manager
---

## For the Business Manager
------------------------------

This solution predicts length of stay in a hospital upon patient admission.  This information is intended to cater to the needs of two user personas:

### Chief Medical Information Officer (CMIO)

The CMIO in a healthcare organization straddles the the divide between informatics/technology and healthcare professionals. Their duties may include using analytics to determine if resources are being allocated appropriately in a hospital network. As part of this, the CMIO needs to be able to not only make determinations about what facilities are being overtaxed, but also what resources at those facilities may need to be bolstered.

By predicting the length of stay of individual patients, the CMIO can make these judgements. For example, using the dashboard provided in this solution, the CMIO is able to determine which facilities will not be discharging patients at the rate that they are coming in. Using this knowledge, the CMIO can then make recommendations to others to transfer and or re-route incoming patients to facilities that are experiencing less burden.

Additionally, the CMIO will need to make recommendations on re-routing specific resources and personnel given demands. By using length of stay predictions, the CMIO is able to see which disease conditions are most prevalent in patients that will be staying in care facilities long term. For example, in seeing that heart failure patients are being predicted to spend a longer amounts of time in a specific facility, the CMIO can recommend additional heart failure resources be diverted to that facility.

### Care Line Manager

A Care Line Manager is directly involved with the care of patients. This role requires monitoring individual patient statuses as well as ensuring that staff is avilable to meet their patients' specific care requirements. Additionally, a Care Line Manager plans for the discharge of their patients; determining if the patient will be discharged during a low staff time (such as weekends).

Length of stay prediction allows the care line manager to better plan for their patients' care. In the provided dashboard, the user is able to see the number of patients under their care that are projected to be discharged over a weekend. This would indicate that either additional resources must be made available to ensure discharge occurs, or to plan for additional days of care in the inpatient setting. Additionally, the vitals and condition breakdowns allow the care line manager to closely monitor the status of those patients projected to be in their care for longer periods of time in order to ensure additional complications do not arise during their stay.

![Visualize](images/XXvisualize.png?raw=true)


You can try out this dashboard in either of the following ways:

* Visit the [online version]({{ site.pbi_url }}).

*  <a href="https://powerbi.microsoft.com/en-us/desktop/" target="_blank">Install PowerBI Desktop</a> and <a href="{{ site.code_url}}/blob/master/{{ site.pbi_name }}" target="_blank">download and open {{ site.pbi_name }}</a> to view and interact with the cached results.

To understand more about the entire process of modeling and deploying this example, see [For the Data Scientist](data-scientist.html).
 

[&lt; Home](index.html)