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

LengthOfStay_sql <- RxSqlServerData(table = "LengthOfStay_sql", connectionString = connection_string)


##########################################################################################################################################

## Feature Engineering:
## 1- Standardization: hemo_s, hematocritic_s, neutrophils_s, sodium_s, glucose_s, bloodureanitro_s, 
##                     creatinine_s, bmi_s, pulse_s, respiration_s.
## 2- Number of preidentified medical conditions: number_of_issues.

##########################################################################################################################################

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

# Create new features. 
# We use this opportunity to convert nvarchar(255) variables to char(1) for more efficient storage. 

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists LoS;"
, sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste(
"	SELECT eid, vdate, rcount, CAST(gender as char(1)) AS gender,
         CAST(dialysisrenalendstage as char(1)) AS dialysisrenalendstage, CAST(asthma as char(1)) AS asthma, 
         CAST(irondef as char(1)) AS irondef, CAST(pneum as char(1)) AS pneum, 
         CAST(substancedependence as char(1)) AS substancedependence,
         CAST(psychologicaldisordermajor as char(1)) AS psychologicaldisordermajor,
         CAST(depress as char(1)) AS depress, CAST(psychother as char(1)) AS psychother,
         CAST(fibrosisandother as char(1)) AS fibrosisandother, CAST(malnutrition as char(1)) AS malnutrition,
         (hemo - AVG(hemo) OVER())/(STDEV(hemo) OVER()) AS hemo_s,
         (hematocritic - AVG(hematocritic) OVER())/(STDEV(hematocritic) OVER()) AS hematocritic_s,
         (neutrophils - AVG(neutrophils) OVER())/(STDEV(neutrophils) OVER()) AS neutrophils_s,
         (sodium - AVG(sodium) OVER())/(STDEV(sodium) OVER()) AS sodium_s,
         (glucose - AVG(glucose) OVER())/(STDEV(glucose) OVER()) AS glucose_s,
         (bloodureanitro - AVG(bloodureanitro) OVER())/(STDEV(bloodureanitro) OVER()) AS bloodureanitro_s,
         (creatinine - AVG(creatinine) OVER())/(STDEV(creatinine) OVER()) AS creatinine_s,
         (bmi - AVG(bmi) OVER())/(STDEV(bmi) OVER()) AS bmi_s,
         (pulse - AVG(pulse) OVER())/(STDEV(pulse) OVER()) AS pulse_s,
         (respiration - AVG(respiration) OVER())/(STDEV(respiration) OVER()) AS respiration_s,
         CAST((CAST(dialysisrenalendstage as int) + CAST(asthma as int) + CAST(irondef as int) + CAST(pneum as int) +
          CAST(substancedependence as int) + CAST(psychologicaldisordermajor as int) + CAST(depress as int) +
          CAST(psychother as int) + CAST(fibrosisandother as int) + CAST(malnutrition as int)) as varchar(2)) 
         AS number_of_issues,
         CAST(secondarydiagnosisnonicd9 as varchar(2)) AS secondarydiagnosisnonicd9, discharged, facid,
         CAST(lengthofstay as char(1)) AS lengthofstay
INTO LoS 
FROM LengthOfStay;"
, sep=""))
