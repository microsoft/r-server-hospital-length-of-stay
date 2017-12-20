##########################################################################################################################################
## This Python script will do the following :
## 1. Standardize the continuous variables (Z-score).
## 2. Create the variable number_of_issues: the number of preidentified medical conditions.

## Input : Data set before feature engineering LengthOfStay.
## Output: Data set with new features LoS.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

from pandas import DataFrame
from pandas import to_numeric

from revoscalepy import rx_get_var_names, RxSqlServerData, rx_summary, rx_set_compute_context, rx_data_step

from SQLConnection import *
from length_of_stay_utils import detect_table, drop_view, alter_column

# Set the Compute Context to local.
rx_set_compute_context(local)


##########################################################################################################################################

## Input: Point to the SQL table with the cleaned raw data set

##########################################################################################################################################

table_name = None
missing = detect_table("LoS0", connection_string)
if missing is False:
    table_name = "LengthOfStay"
else:
    table_name = "LoS0"

LengthOfStay_cleaned_sql = RxSqlServerData(table=table_name, connection_string=connection_string)


##########################################################################################################################################

## Feature Engineering:
## 1- Standardization: hematocrit, neutrophils, sodium, glucose, bloodureanitro, creatinine, bmi, pulse, respiration.
## 2- Number of preidentified medical conditions: number_of_issues.

##########################################################################################################################################

# Get the mean and standard deviation of those variables.
col_list = rx_get_var_names(LengthOfStay_cleaned_sql)
f = "+".join(col_list)
summary = rx_summary(formula=f, data=LengthOfStay_cleaned_sql, by_term=True).summary_data_frame

names = ["hematocrit", "neutrophils", "sodium", "glucose", "bloodureanitro", "creatinine", "bmi", "pulse", "respiration"]
statistics = summary[summary["Name"].isin(names)]
statistics = statistics[["Name", "Mean", "StdDev"]]

# standardization transform function
def standardize(data, context):
    for n, row in statistics.iterrows():
        data[[row["Name"]]] = (data[[row["Name"]]] - row["Mean"])/row["StdDev"]
    return data

# number_of_issues transform function
def calculate_number_of_issues(data, context):
    data["number_of_issues"] = to_numeric(data["hemo"]) + to_numeric(data["dialysisrenalendstage"]) + to_numeric(data["asthma"])\
                               + to_numeric(data["irondef"]) + to_numeric(data["pneum"]) + to_numeric(data["substancedependence"])\
                               + to_numeric(data["psychologicaldisordermajor"]) + to_numeric(data["depress"])\
                               + to_numeric(data["psychother"]) + to_numeric(data["fibrosisandother"]) + to_numeric(data["malnutrition"])
    return data

# Combine transform functions into one overarching transform
def transform(dataset, context):
    data = DataFrame(dataset)
    data = standardize(data, context)
    data = calculate_number_of_issues(data, context)
    return data

# We drop the LoS view in case the SQL Stored Procedure was executed in the same database before.
drop_view("LoS", connection_string)

# Standardize the cleaned table by wrapping it up in rx_data_step. Output is written to LoS.
LengthOfStay_cleaned_sql = RxSqlServerData(sql_query="SELECT * FROM [{}]".format(table_name),
                                           connection_string=connection_string)
LoS_sql = RxSqlServerData(table="LoS", connection_string=connection_string)
rx_data_step(input_data=LengthOfStay_cleaned_sql, output_file=LoS_sql, overwrite=True, transform_function=transform)

alter_column("LoS", "number_of_issues", "varchar(2)", connection_string)
alter_column("LoS", "lengthofstay", "float", connection_string)    # int -> float for regression