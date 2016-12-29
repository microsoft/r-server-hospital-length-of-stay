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
    <td>Models_Class</td>
    <td>Table storing the trained classification model</td>
  </tr>
    <tr>
    <td>Forest_Prediction_Class</td>
    <td>Prediction results when testing the trained classification random forest</td>
  </tr>
    <tr>
    <td>Metrics_Class</td>
    <td>Performance metrics of the classification model tested</td>
  </tr>
    <tr>
    <td>Models_Reg</td>
    <td>Table storing the trained regression model</td>
  </tr>
    <tr>
    <td>Forest_Prediction_Reg</td>
    <td>Prediction results when testing the trained regression random forest</td>
  </tr>
    <tr>
    <td>Metrics_Reg</td>
    <td>Performance metrics of the regression model tested</td>
  </tr>
</table>
