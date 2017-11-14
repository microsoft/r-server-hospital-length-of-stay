##########################################################################################################################################

## This Python script will do the following:
## 1. Upload the data set to SQL.
## 2. Determine the variables containing missing values, if any.
## 3. Clean the table: replace NAs with -1 or 'missing' (1st Method) or with the mean or mode (2nd Method).

## Input : CSV file "LengthOfStay.csv".
## Output: Cleaned raw data set LengthOfStay.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages.
import os
from pandas import DataFrame

from revoscalepy import rx_get_var_names, RxSqlServerData, RxTextData
from revoscalepy import rx_set_compute_context, rx_data_step, rx_summary

from SQLConnection import *
from length_of_stay_utils import drop_view

# Set the Compute Context to local.
rx_set_compute_context(local)


##########################################################################################################################################

## Upload the data set to to SQL

##########################################################################################################################################

# Point to the input data set while specifying the classes.
file_path = "..\\Data"
LoS_text = RxTextData(file=os.path.join(file_path, "LengthOfStay.csv"), column_info=col_type_info)

# Upload the table to SQL.
LengthOfStay_sql = RxSqlServerData(table="LengthOfStay", connection_string=connection_string)
rx_data_step(input_data=LoS_text, output_file=LengthOfStay_sql, overwrite=True)

##########################################################################################################################################

## Determine if LengthOfStay has missing values

##########################################################################################################################################

# First, get the names and types of the variables to be treated.
# For rxSummary to give correct info on characters, stringsAsFactors = True should be used.
LengthOfStay_sql2 = RxSqlServerData(table="LengthOfStay", connection_string=connection_string, stringsAsFactors=True)

#col = rxCreateColInfo(LengthOfStay_sql2)    # Not yet available
colnames = rx_get_var_names(LengthOfStay_sql2)

# Then, get the names of the variables that actually have missing values. Assumption: no NA in eid, lengthofstay, or dates.
var = [x for x in colnames if x not in ["eid", "lengthofstay", "vdate", "discharged"]]
f = "+".join(var)
summary = rx_summary(formula=f, data=LengthOfStay_sql2, by_term=True).summary_data_frame
var_with_NA = summary[summary["MissingObs"] > 0]

method = None
if var_with_NA.empty:
    print("No missing values.")
    print("You can move to step 2.")
    missing = False
else:
    print("Variables containing missing values are:")
    print(var_with_NA)
    print("Apply one of the methods below to fill missing values.")
    missing = True
    method = "missing"
    #method = "mean_mode"

##########################################################################################################################################

## 1st Method: NULL is replaced with "missing" (character variables) or -1 (numeric variables)

##########################################################################################################################################

if method == "missing":
    print("Fill with 'missing'")

    # Get the variables types (character vs. numeric)
    char_names = []
    num_names = []
    for index, row in var_with_NA.iterrows():
        nameSeries = var_with_NA["Name"]
        name = nameSeries.to_string().split()[-1]
        if col_type_info[name]["type"] == "numeric" or col_type_info[name]["type"] == "integer":
            num_names.append(name)
        else:
            char_names.append(name)

    # Function to replace missing values with "missing" (character variables) or -1 (numeric variables).
    def fill_NA_explicit(dataset, context):
        data = DataFrame(dataset)
        for name in char_names:
            data.loc[data[name].isnull(),name] = "missing"
        for name in num_names:
            data.loc[data[name].isnull(),name] = -1
        return data

    # Apply this function to LeangthOfStay by wrapping it up in rxDataStep. Output is written to LoS0.
    # We drop the LoS0 view in case the SQL Stored Procedure was executed in the same database before.
    drop_view("LoS0", connection_string)

    LoS0_sql = RxSqlServerData(table="LoS0", connection_string=connection_string)
    rx_data_step(input_data=LengthOfStay_sql, output_file=LoS0_sql, overwrite=True, transform_function=fill_NA_explicit)

##########################################################################################################################################

## 2nd Method: NULL is replaced with the mode (categorical variables: integer or character) or mean (continuous variables)

##########################################################################################################################################
if method == "mean_mode":
    print("Fill with mode and mean")

    # Get the variables types (categortical vs. continuous)
    categ_names = []
    contin_names = []
    for index, row in var_with_NA.iterrows():
        name_series = var_with_NA["Name"]
        name = name_series.to_string().split()[-1]
        if col_type_info[name]["type"] == "numeric":
            contin_names.append(name)
        else:
            categ_names.append(name)

    # Function to replace missing values with the mode (categorical variables) or mean (continuous variables)
    def fill_NA_mode_mean(dataset, context):
        data = DataFrame(dataset)
        for name in categ_names:
            data.loc[data[name].isnull(),name] = data[name].mode().iloc[0]
        for name in contin_names:
            data.loc[data[name].isnull(), name] = data[name].mean()
        return data

    # Apply this function to LengthOfStay by wrapping it up in rxDataStep. Output is written to LoS0.
    # We drop the LoS0 view in case the SQL Stored Procedure was executed in the same database before.
    drop_view("LoS0", connection_string)

    LoS0_sql = RxSqlServerData(table="LoS0", connection_string=connection_string)
    rx_data_step(input_data=LengthOfStay_sql, output_file=LoS0_sql, overwrite=True, transform_function=fill_NA_mode_mean)

