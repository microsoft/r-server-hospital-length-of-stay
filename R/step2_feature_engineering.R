##########################################################################################################################################
## This R script will do the following :
## 1. Standardize the continuous variables (Z-score).
## 2. Create the variable number_of_issues: the number of preidentified medical conditions.

## Input : Data set before feature engineering LengthOfStay.
## Output: Data set with new features LoS.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the Compute Context to local.
rxSetComputeContext(local)

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w") 


##########################################################################################################################################

## Function to get the top n rows of a table stored on SQL Server.
## You can execute this function at any time during  your progress by removing the comment "#", and inputting:
##  - the table name.
##  - the number of rows you want to display.

##########################################################################################################################################

display_head <- function(table_name, n_rows){
  table_sql <- RxSqlServerData(sqlQuery = sprintf("SELECT TOP(%s) * FROM %s", n_rows, table_name), connectionString = connection_string)
  table <- rxImport(table_sql)
  print(table)
}

# table_name <- "insert_table_name"
# n_rows <- 10
# display_head(table_name, n_rows)


##########################################################################################################################################

## Input: Point to the SQL table with the cleaned raw data set

##########################################################################################################################################

if(missing == 0){
  LengthOfStay_cleaned_sql <- RxSqlServerData(table = "LengthOfStay", connectionString = connection_string)
} else{
  LengthOfStay_cleaned_sql <- RxSqlServerData(table = "LoS0", connectionString = connection_string)
}


##########################################################################################################################################

## Feature Engineering:
## 1- Standardization: hematocrit, neutrophils, sodium, glucose, bloodureanitro, 
##                     creatinine, bmi, pulse, respiration.
## 2- Number of preidentified medical conditions: number_of_issues.

##########################################################################################################################################

# Get the mean and standard deviation of those variables.
names <- c("hematocrit", "neutrophils", "sodium", "glucose", "bloodureanitro",
           "creatinine", "bmi", "pulse", "respiration")
summary <- rxSummary(formula = ~., LengthOfStay_cleaned_sql, byTerm = TRUE)$sDataFrame
Statistics <- summary[summary$Name %in% names,c("Name", "Mean", "StdDev")]

# Function to standardize
standardize <- function(data){
  data <- data.frame(data)
  for(n in 1:nrow(Stats)){
    data[[Stats[n,1]]] <- (data[[Stats[n,1]]] - Stats[n,2])/Stats[n,3]
    }
  return(data)
}

# Apply this function to the cleaned table by wrapping it up in rxDataStep. Output is written to LoS.  
# At the same time, we create number_of_issues as the number of preidentified medical conditions.
# We also create lengthofstay_bucket as the bucketed version of lengthofstay for classification. 
LoS_sql <- RxSqlServerData(table = "LoS", connectionString = connection_string)
rxDataStep(inData = LengthOfStay_cleaned_sql , outFile = LoS_sql, overwrite = TRUE, transformFunc = standardize, 
           transformObjects = list(Stats = Statistics), transforms = list(
             number_of_issues = as.numeric(hemo) + as.numeric(dialysisrenalendstage) + as.numeric(asthma) + as.numeric(irondef) + 
                                as.numeric(pneum) + as.numeric(substancedependence) +
                                as.numeric(psychologicaldisordermajor) + as.numeric(depress) + as.numeric(psychother) + 
                                as.numeric(fibrosisandother) + as.numeric(malnutrition) 
             
           ))

           
# Converting number_of_issues to character with a SQL query because as.character in rxDataStep is crashing.           
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("ALTER TABLE LoS ALTER COLUMN number_of_issues varchar(2);", sep=""))

