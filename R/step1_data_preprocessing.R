##########################################################################################################################################
## This R script will do the following:
## 1. Upload the data set to SQL.
## 2. Clean the table: replace NAs with -1 or 'missing' (1st Method) or with the mean or mode (2nd Method).

## Input : CSV file "LengthOfStay.csv".
## Output: Cleaned raw data set LengthOfStay. 

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages. 
library(RevoScaleR)

# Load the connection string and compute context definitions.
source("sql_connection.R")

# Set the Compute Context to Local, to load files in-memory.
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

## Upload the data set to to SQL

##########################################################################################################################################

# Specify the desired column types. 
# Character and Factor are converted to nvarchar(255), Integer to Integer and Numeric to Float. 
column_types <-  c(eid = "integer",               
                   vdate = "character",           
                   rcount = "integer",        
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
                   lengthofstay = "factor")


# Point to the input data set while specifying the classes.
file_path <- "../Data" 
LoS_text <- RxTextData(file = file.path(file_path, "LengthOfStay.csv"), colClasses = column_types)

# Upload the table to SQL. 
LengthOfStay_sql <- RxSqlServerData(table = "LengthOfStay", connectionString = connection_string)
rxDataStep(inData = LoS_text, outFile = LengthOfStay_sql, overwrite = TRUE)

# Open a connection with SQL Server to be able to write queries with the rxExecuteSQLDDL function.
outOdbcDS <- RxOdbcData(table = "NewData", connectionString = connection_string, useFastRead=TRUE)
rxOpen(outOdbcDS, "w")

##########################################################################################################################################


## 1st Method: NULL is replaced with "missing" (character variables) or -1 (numeric variables)

##########################################################################################################################################

fill_NA_explicit <- function(table = "LengthOfStay"){
  
  # Get the variables names and types. Assumption: no NA in eid. 
  data_sql <- RxSqlServerData(table = table, connectionString = connection_string)
  col <- rxCreateColInfo(data_sql)
  colnames <- names(col)
  var <- colnames[!colnames %in% c("eid")]
  
  char_names <- c()
  num_names <- c()
  for(name in var){
    if(col[[name]]$type == "numeric" | col[[name]]$type == "integer" ){
      num_names[length(num_names) + 1] <- name
    } else{
      char_names[length(char_names) + 1] <- name
    }
  }
  
  
  # For Characters: replace the missing values with "missing". 
  for(name in char_names){
    rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf("UPDATE %s
                                                    SET %s = ISNULL(%s, 'missing' )
                                                    ;",table, name, name))
  }
  
  # For Numerics: replace the missing values with -1.
  for(name in num_names){
    rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf("UPDATE %s
                                                    SET %s = ISNULL(%s, -1)
                                                    ;",table, name, name))
  }
  
}

# Apply the function to LengthOfStay. 
fill_NA_explicit()  

##########################################################################################################################################


## 2nd Method: NULL is replaced with the mode (categorical variables) or mean (continuous variables)  

##########################################################################################################################################

fill_NA_mode_mean <- function(table = "LengthOfStay"){
  
  # Get the variables names and types. Assumption: no NA in eid. 
  data_sql <- RxSqlServerData(table = table, connectionString = connection_string)
  col <- rxCreateColInfo(data_sql)
  colnames <- names(col)
  var <- colnames[!colnames %in% c("eid")]
  
  categ_names <- c()
  contin_names <- c()
  for(name in var){
    if(col[[name]]$type == "numeric"){
      contin_names[length(contin_names) + 1] <- name
    } else{
      categ_names[length(categ_names) + 1] <- name
    }
  }
  
  
  # For Categoricals: Compute the mode of the variables with SQL queries. We insert them in a table called Modes. 
  
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
 ## Import the Modes table.   
  Modes_sql <- RxSqlServerData(table = "Modes", connectionString = connection_string) 
  Modes <- rxImport(Modes_sql)
    
 ## Replace the NULL with the modes. 
  for(name in categ_names){
    mode <- Modes[Modes$name == name ,2]
    rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf("UPDATE %s
			                                               SET %s = ISNULL(%s, '%s' )
                                                      ;",table, name, name, mode))
  }
  
  
  # For Continuous: Compute the mean of the variables with SQL queries. We insert them in a table called Means. 
  
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
  ## Import the Means table.   
  Means_sql <- RxSqlServerData(table = "Means", connectionString = connection_string) 
  Means <- rxImport(Means_sql)
  
  ## Replace the NULL with the means. 
  for(name in contin_names){
    mean <- Means[Means$name == name ,2]
    rxExecuteSQLDDL(outOdbcDS, sSQLString = sprintf("UPDATE %s
                                                    SET %s = ISNULL(%s, %s )
                                                    ;",table, name, name, mean))
  }

}
  
# Apply the function to LengthOfStay. 
fill_NA_mode_mean()  
  
