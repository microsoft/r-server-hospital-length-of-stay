# Hospital Length of Stay Prediction Template in SQL Server with R sevices using R IDE. 
--------------------------
 * **Introduction**
 * **System Requirements**
 * **Step 1: Pre-Processing and Cleaning**
 * **Step 2: Feature Engineering**
 * **Step 3: Splitting, Training, Testing and Evaluating (Classification)**
 * **Step 3: Splitting, Training, Testing and Evaluating (Regression)**

### Introduction
-------------------------

In order for hospitals to optimize resource allocation, it is important to predict accurately how long a newly admitted patient will stay in the hospital.

For businesses that prefers an on-prem solution, the implementation with SQL Server R Services is a great option, which takes advantage of the power of SQL Server and RevoScaleR (Microsoft R Server). In this template, we implemented all steps in SQL stored procedures: data preprocessing, and feature engineering are implemented in pure SQL, while data cleaning, and the model training, scoring and evaluation steps are implemented with SQL stored procedures calling R (Microsoft R Server) code. 

All these steps can be executed in an R IDE. 

### System Requirements
-----------------------

To run the scripts, it requires the following:
 * R IDE with Microsoft R server installed and configured;
 * SQL server 2016 with Microsoft R server installed and configured;
 * The SQL user name and password;
 * SQL Database for which the user has write permission;
 * For more information about SQL server 2016 and R service, please visit: https://msdn.microsoft.com/en-us/library/mt604847.aspx


### Step 1: Pre-Processing and Cleaning
-------------------------

In this step, the raw data is loaded into SQL in a table called LengthOfStay. Then, the data is cleaned in-place. This assumes that the ID variable (eid) does not contain blanks. 
There are two ways to replace missing values:

The first provided function, fill_NA_explicit, will replace the missing values with "missing" (character variables) or -1 (numeric variables). It should be used if it is important to know where the missing values were.

The second function, fill_NA_mode_mean, will replace the missing values with the mode (categorical variables) or mean (float variables).

The user can run the one he prefers. 

Input:
* Raw data LengthOfStay.csv.

Output:
* A SQL Table "LengthOfStay", with missing values replaced.

Related files:
* step1_data_preprocessing.R

### Step 2: Feature Engineering
-------------------------

In this step, we design new features:  

* The continuous laboratory measurements (e.g. hemo, hematocritic, sodium, glucose etc.) are standardized: we substract the mean and divide by the standard deviation. 
* number_of_issues: the total number of preidentified medical conditions.

Input:

* "LengthOfStay" table.

Output:

* "LoS" table containing new features.

Related files:

* step2_feature_engineering.R

In what follows, the problem can be modeled as a classification or a regression. 

### Step 3: Splitting, Training, Testing and Evaluating (Classification)
-------------------------

In this step, we split the data into a training set and a testing set. The user has to specify a splitting percentage. For example, if the splitting percentage is 70, 70% of the data will be put in the training set, while the other 30% will be assigned to the testing set. The eid that will end in the training set, are stored in the table “Train_Id”.
Then we train a classification Random Forest (RF) or a classification Gradient Boosted Trees (GBT) on the training set. The trained models are uploaded to SQL if needed later. 
Finally, we score the two trained models on the testing set, and then compute multi-class performance metrics. 

Input:

* "LoS" table.

Output:

* Performance metrics.
_
Related files:

* step3_training_evaluation_classification

### Step 3: Splitting, Training, Testing and Evaluating (Regression)
-------------------------

In this step, we split the data into a training set and a testing set. The user has to specify a splitting percentage. For example, if the splitting percentage is 70, 70% of the data will be put in the training set, while the other 30% will be assigned to the testing set. The eid that will end in the training set, are stored in the table “Train_Id”.
Then we train a regression Random Forest (RF) or a regression Gradient Boosted Trees (GBT) on the training set. The trained models are uploaded to SQL if needed later. 
Finally, we score the two trained models on the testing set, and then compute regression performance metrics as well as multi-class performance metrics obtained after rounding the predictions to the nearest integer. 

Input:

* "LoS" table.

Output:

* Performance metrics.
_
Related files:

* step3_training_evaluation_regression



