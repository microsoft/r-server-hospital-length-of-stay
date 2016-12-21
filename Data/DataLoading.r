library(RevoScaleR)

####################################################################################################
## This R script will do the following:
## 1. Data uploading into SQL tables;
## 2. Data labeling for raw train and test data;
## 3. Feature engineering for train and test data;
## 4. Feature normalization for train and test data
## Input : The csv files of train, test and truth data
## Output: train-Features and test-Features SQL tables for further model training
####################################################################################################
file_path <- getwd()
####################################################################################################
## Compute context  Integrated Security=SSPI"
####################################################################################################
connection_string <- "Driver=SQL Server;
                      Server=lengthofstayVM;
                      Database=SolutionAcc;
                      Trusted_Connection=True"

sql_share_directory <- paste("c:\\AllShare\\", Sys.getenv("USERNAME"), sep = "")
dir.create(sql_share_directory, recursive = TRUE, showWarnings = FALSE)
sql <- RxInSqlServer(connectionString = connection_string, 
                     shareDir = sql_share_directory)
local <- RxLocalSeq()

####################################################################################################
## Metadata
####################################################################################################

train_columns <- c(eid = "numeric",               
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
                   secondarydiagnosisnonicd9 = "integer",                   
                   lengthofstay = "factor"                  
)

facilities_columns <- c(Id = "numeric",                       
                        Name = "character")

####################################################################################################
## Load train data into SQL table
####################################################################################################

train_file <- "lengthofstay_Classification_Train_Data.csv"
train_file_path <- file.path((file_path), train_file)
train_data_text <- RxTextData(file = train_file_path,                              
                              colClasses = train_columns)
train_table_name <- strsplit(basename(train_file), "\\.")[[1]][1]
train_data_table <- RxSqlServerData(table = train_table_name,                                    
                                    connectionString = connection_string,                                  
                                    colClasses = train_columns)

rxDataStep(inData = train_data_text,          
           outFile = train_data_table,
           overwrite = TRUE)

####################################################################################################
## Load test data into SQL table
####################################################################################################

test_file <- "lengthofstay_Classification_Test_Data.csv"
test_file_path <- file.path(file_path, test_file)
test_data_text <- RxTextData(file = test_file_path,                             
                             colClasses = train_columns)

test_table_name <- strsplit(basename(test_file), "\\.")[[1]][1]
test_data_table <- RxSqlServerData(table = test_table_name,                                   
                                   connectionString = connection_string,                                   
                                   colClasses = train_columns)

rxDataStep(inData = test_data_text,           
           outFile = test_data_table,           
           overwrite = TRUE)

####################################################################################################
## Load facilities data into SQL table
####################################################################################################

facilities_file <- "MetaData_Facilities.csv"
facilities_file_path <- file.path(file_path, facilities_file)

facilities_data_text <- RxTextData(file = facilities_file_path,                                 
                                   colClasses = facilities_columns)

facilities_table_name <- strsplit(basename(facilities_file), "\\.")[[1]][1]
facilities_data_table <- RxSqlServerData(table = facilities_table_name,                                         
                                         connectionString = connection_string,                                        
                                         colClasses = facilities_columns)

rxDataStep(inData = facilities_data_text,        
           outFile = facilities_data_table,          
           overwrite = TRUE)



####################################################################################################

## Cleanup

####################################################################################################

rm(list = ls())