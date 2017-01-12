---
layout: default
title: Description of Database Tables
---

## SQL Database Tables
--------------------------

Below are the different data sets that you will find in your database after deployment. 

<table class="table table-striped table-condensed">
   <tr>
    <th>Table</th>
    <th>Description</th>
  </tr>
  <tr>
    <td>LengthOfStay</td>
    <td>Raw data about each hospital admission with missing values replaced by the mode or mean </td>
  </tr>
  <tr>
    <td>LoS </td>
    <td>Analytical data set: cleaned data with new features</td>
  </tr>
  <tr>
    <td>Train_Id</td>
    <td>List of encounter IDs that will go to the training set</td>
  </tr>
    <tr>
    td>Models</td>
    <td>Table storing the trained models</td>
  </tr>
    <tr>
    <td>Boosted_Prediction</td>
    <td>Prediction results when testing the trained boosted trees (rxFastTrees)</td>
  </tr>
    <tr>
    <td>Metrics</td>
    <td>Performance metrics of the models tested</td>
  </tr>
  <tr>
    <td>LoS_Predictions</td>
    <td>Testing set with the predicted dates of the two trained models for discharge</td>
  </tr>

</table>
