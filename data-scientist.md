---
layout: default
title: For the Data Scientist
---

## For the Data Scientist - Develop with R
----------------------------


<div class="row">
    <div class="col-md-6">
        <div class="toc">
            <li><a href="#first">{{ site.solution_name }}</a></li>
            <li><a href="#system-requirements">System Requirements</a></li>
            <li><a href="#step1">Step1: Pre-Processing and Cleaning</a></li>
            <li><a href="#step2">Step2: Feature Engineering</a></li>
            <li><a href="#step3r">Step3: Splitting, Training, Testing and Evaluating</a></li>
             <li><a href="#step4">Deploy and Visualize Results</a></li>
            <li><a href="#template-contents">Template Contents</a></li>
        </div>
    </div>
    <div class="col-md-6">
        Microsoft Machine Learning Services provide an extensible, scalable platform for integrating machine learning tasks and tools with the applications that consume machine learning services. It includes a database service that runs outside the SQL Server process and communicates securely with  R and Python. 
        <p>
       This solution package shows how to pre-process data (cleaning and feature engineering), train prediction models, and perform scoring on the SQL Server machine using either R or Python code.  </p>
    </div>
</div>

Data scientists who are testing and developing solutions can work from the convenience of their preferred IDE on their client machine, while <a href="https://msdn.microsoft.com/en-us/library/mt604885.aspx">setting the computation context to SQL</a> (see **R** or **Python** folder for code).  They can also deploy the completed solutions to SQL Server 2017 by embedding calls to R or Python in stored procedures (see **SQLR** or **SQLPy** folder for code). These solutions can then be further automated by the use of SQL Server Integration Services and SQL Server agent: a PowerShell script (.ps1 file) automates the running of the SQL code.

<a name="first"></a>

## {{ site.solution_name }}
--------------------------

In order for hospitals to optimize resource allocation, it is important to predict accurately how long a newly admitted patient will stay in the hospital.

In this template, we implemented all steps in SQL stored procedures: data preprocessing, and feature engineering are implemented in pure SQL, while data cleaning, and the model training, scoring and evaluation steps are implemented with SQL stored procedures calling either R (Microsoft R Server) or Python code. 

All these steps can be executed in an R or Python IDE, and are also presented in R/Python Jupyter notebooks. 

Among the key variables to learn from data are number of previous admissions as well as various diagnostic codes and lab results.  (View the [full data set description.](input_data.html) )

In this template, the final scored data is stored in SQL Server -  (`Boosted_Prediction`) model.  This data is then visualized in PowerBI. 

To try this out yourself, see the [Quick Start](START_HERE.html) section on the main page.  

This page describes what happens in each of the steps: dataset creation, model development, prediction, and deployment in more detail.


## System Requirements
--------------------------

    {% include requirements.md %}


<a name="step1"></a>

##  Step1: Pre-Processing and Cleaning
-------------------------

In this step, the raw data is loaded into SQL in a table called `LengthOfStay`. Then, if there are missing values, the data is cleaned in-place. This assumes that the ID variable (eid) does not contain blanks. 
There are two ways to replace missing values:

* The first provided function, `fill_NA_explicit`, will replace the missing values with "missing" (character variables) or -1 (numeric variables). It should be used if it is important to know where the missing values were.

* The second function, `fill_NA_mode_mean`, will replace the missing values with the mode (categorical variables) or mean (float variables).

The user can run the one he prefers. 

### Input:
* Raw data **LengthOfStay.csv**.

### Output:
* A SQL Table `LengthOfStay`, with missing values replaced.

### Related files:
* R: **step1_data_preprocessing.R**
* Python: **step1_data_preprocessing.Py**

<a name="step2"></a>

## Step2: Feature Engineering
-------------------------

In this step, we design new features:  

* The continuous laboratory measurements (e.g. `hemo`, `hematocritic`, `sodium`, `glucose` etc.) are standardized: we substract the mean and divide by the standard deviation. 
* `number_of_issues`: the total number of preidentified medical conditions.

### Input:

* `LengthOfStay` table.

### Output:

* `LoS` table containing new features.

### Related files:

* R: **step2_feature_engineering.R**
* Python: **step2_feature_engineering.py**

<img src="images/ds1.png">

<a name="step3r"></a>

## Step3:  Splitting, Training, Testing and Evaluating (Regression)
-------------------------

In this step, we split the data into a training set and a testing set. The user has to specify a splitting percentage. For example, if the splitting percentage is 70, 70% of the data will be put in the training set, while the other 30% will be assigned to the testing set. The `eid` that will end in the training set are stored in the table `Train_Id`.  Then we train a regression Random Forest (rxDForest in R, rx_dforest in Python) and a gradient boosted trees model (rxFastTrees in R, rx_btrees in Python) on the training set. The trained models are uploaded to SQL if needed later. Finally, we score the trained models on the testing set, and then compute regression performance metrics.

### Input:

* `LoS` table.

### Output:

* Performance metrics and trained models.

### Related files:

* R: **step3_training_evaluation.R**
* Python: **step3_training_evaluation.py**

<img src="images/ds2.png">
<br/>
<img src="images/ds3.png">

<a name="step4"></a>
  
##  Step 4: Deploy and Visualize Results
--------------------------------

See [For the Business Manager](business-manager.html) for a description of the personas who will be interested in using these predictions to aid them in their jobs.


Explore the  [online version]({{ site.dashboard_url}}) of the dashboard.



## Template Contents 
---------------------

[View the contents of this solution template](contents.html).


To try this out yourself: 

* View the [Quick Start](START_HERE.html).

[&lt; Home](index.html)
