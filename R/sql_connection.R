##########################################################################################################################################
## This R script configures the compute context used in all the rest of the scripts.
## The connection string below is pre-poplulated with the default values created for a VM 
## from the Cortana Intelligence Gallery.
## Change the values accordingly for your implementation.
##
## NOTE: The database named in this string must exist on your server. 
##       If you will be using the R IDE scripts from scratch,  first go to SSMS 
##       and create a New Database with the name you wish to use.
##########################################################################################################################################

connection_string <- "Driver=SQL Server;Server=localhost;Database=Hospital_R;Trusted_Connection=Yes"
sql <- RxInSqlServer(connectionString = connection_string)
local <- RxLocalSeq()
