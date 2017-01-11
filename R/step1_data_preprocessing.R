##########################################################################################################################################
## This R script will do the following:
## 1. Upload the data set to SQL.
## 2. Determine the variables containing missing values, if any. 
## 3. Clean the table: replace NAs with -1 or 'missing' (1st Method) or with the mean or mode (2nd Method).

## Input : CSV file "LengthOfStay.csv".
## Output: Cleaned raw data set LengthOfStay. 

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

## Upload the data set to to SQL

##########################################################################################################################################

# Specify the desired column types. 
# Character and Factor are converted to nvarchar(255), Integer to Integer and Numeric to Float. 
column_types <-  c(eid = "integer",               
                   vdate = "character",           
                   rcount = "character",        
                   gender = "factor",            
                   dialysisrenalendstage = "factor",             
                   asthma = "factor",                
                   irondef = "factor",                   
                   pneum = "factor",                 
                   substancedependence = "factor",                  
                   psychologicaldisordermajor = "factor",             
                   depress = "factor",           
                   psychother = "factor",        
                   fibrosisandother = "factor",          
                   malnutrition = "factor",                               
                   hemo = "numeric",            
                   hematocritic = "numeric",           
                   neutrophils = "numeric",           
                   sodium = "numeric",          
                   glucose = "numeric",             
                   bloodureanitro = "numeric",                 
                   creatinine = "numeric",                 
                   bmi = "numeric",                 
                   pulse = "numeric",                  
                   respiration = "numeric",                  
                   secondarydiagnosisnonicd9 = "factor",
                   discharged = "character",
                   facid = "factor",
                   lengthofstay = "integer")


# Point to the input data set while specifying the classes.
file_path <- "../Data" 
LoS_text <- RxTextData(file = file.path(file_path, "LengthOfStay.csv"), colClasses = column_types)

# Upload the table to SQL. 
LengthOfStay_sql <- RxSqlServerData(table = "LengthOfStay", connectionString = connection_string)
rxDataStep(inData = LoS_text, outFile = LengthOfStay_sql, overwrite = TRUE)


##########################################################################################################################################

## Determine if LengthOfStay has missing values

##########################################################################################################################################

table <- "LengthOfStay"

# First, get the names and types of the variables to be treated.
data_sql <- RxSqlServerData(table = table, connectionString = connection_string)
col <- rxCreateColInfo(data_sql)

# Then, get the names of the variables that actually have missing values. Assumption: no NA in eid. 
colnames <- names(col)
var <- colnames[!colnames %in% c("eid")]
formula <- as.formula(paste("~", paste(var, collapse = "+")))
summary <- rxSummary(formula, data_sql, byTerm = TRUE)
var_with_NA <- summary$sDataFrame[summary$sDataFrame$MissingObs > 0, 1] 

if(length(var_with_NA) == 0){
  print("No missing values.")
  print("You can move to step 2.")
  missing <- 0
  
} else{
  print("Variables containing missing values are:")
  print(var_with_NA)
  print("Apply one of the methods below to fill missing values.")
  missing <- 1
}


##########################################################################################################################################

## 1st Method: NULL is replaced with "missing" (character variables) or -1 (numeric variables)

##########################################################################################################################################

# Get the variables types (character vs. numeric)
char_names <- c()
num_names <- c()
for(name in var_with_NA){
  if(col[[name]]$type == "numeric" | col[[name]]$type == "integer" ){
    num_names[length(num_names) + 1] <- name
  } else{
    char_names[length(char_names) + 1] <- name
  }
}
  
# Function to replace missing values with "missing" (character variables) or -1 (numeric variables).
fill_NA_explicit <- function(data){
  data <- data.frame(data)
  for(j in 1:length(char)){
    row_na <- which(is.na(data[,char[j]]) == TRUE) 
    if(length(row_na > 0)){
      data[row_na, char[j]] <- "missing"
    }
  }
  for(j in 1:length(num)){
    row_na <- which(is.na(data[,num[j]]) == TRUE) 
    if(length(row_na > 0)){
      data[row_na, num[j]] <- -1
    }
  }
  return(data)
}
  
# Apply this function to LeangthOfStay by wrapping it up in rxDataStep. Output is written to LoS0.   
LoS0_sql <- RxSqlServerData(table = "LoS0", connectionString = connection_string)
rxDataStep(inData = LengthOfStay_sql , outFile = LoS0_sql, overwrite = TRUE, transformFunc = fill_NA_explicit, 
           transformObjects = list(char = char_names, num = num_names))

##########################################################################################################################################

## 2nd Method: NULL is replaced with the mode (categorical variables: integer or character) or mean (continuous variables)  

##########################################################################################################################################

# Get the variables types (categortical vs. continuous) 
categ_names <- c()
contin_names <- c()
  for(name in var_with_NA){
    if(col[[name]]$type == "numeric"){
      contin_names[length(contin_names) + 1] <- name
    } else{
      categ_names[length(categ_names) + 1] <- name
    }
  }
  
  
# For Categoricals: Compute the mode of the variables with SQL queries in table Modes. We then import Modes. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Modes;"
                                              , sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("CREATE TABLE Modes
                                              (name varchar(30),
                                              mode varchar(30));"
                                              , sep=""))

for(name in categ_names){
  rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf("INSERT INTO Modes
                                                  SELECT '%s', mode
                                                  FROM (SELECT TOP(1) %s as mode, count(*) as cnt
                                                  FROM %s
                                                  GROUP BY %s 
                                                  ORDER BY cnt desc) as t;",name, name, table, name))
}
Modes_sql <- RxSqlServerData(table = "Modes", connectionString = connection_string) 
Modes <- rxImport(Modes_sql)

# For Continuous: Compute the mode of the variables with SQL queries in table Means. We then import Means. 
rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("DROP TABLE if exists Means;"
                                              , sep=""))

rxExecuteSQLDDL(outOdbcDS, sSQLString = paste("CREATE TABLE Means
                                              (name varchar(30),
                                              mean float);"
                                              , sep=""))

for(name in contin_names){
  rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf("INSERT INTO Means
                                                  SELECT '%s', mean
                                                  FROM (SELECT AVG(%s) as mean
                                                  FROM %s) as t;",name, name, table))
}
Means_sql <- RxSqlServerData(table = "Means", connectionString = connection_string) 
Means <- rxImport(Means_sql)
 
# Function to replace missing values with the mode (categorical variables) or mean (continuous variables)
fill_NA_mode_mean <- function(data){
  data <- data.frame(data)
  for(j in 1:length(categ)){
    row_na <- which(is.na(data[,categ[j]]) == TRUE) 
    if(length(row_na > 0)){
      data[row_na, categ[j]] <- subset(Mode, name == categ[j])[1,2]
    }
  }
  for(j in 1:length(contin)){
    row_na <- which(is.na(data[,contin[j]]) == TRUE) 
    if(length(row_na > 0)){
      data[row_na, contin[j]] <- subset(Mean, name == contin[j])[1,2]
    }
  }
  return(data)
}

# Apply this function to LeangthOfStay by wrapping it up in rxDataStep. Output is written to LoS0.   
LoS0_sql <- RxSqlServerData(table = "LoS0", connectionString = connection_string)
rxDataStep(inData = LengthOfStay_sql , outFile = LoS0_sql, overwrite = TRUE, transformFunc = fill_NA_mode_mean, 
           transformObjects = list(categ = categ_names, contin = contin_names, Mode = Modes, Mean = Means))

