##########################################################################################################################################
## This R script will simulate data for the LengthOfStay table.

##########################################################################################################################################

## Declare the number of Unique leads

##########################################################################################################################################

no_of_unique_leads <- 100000


##########################################################################################################################################

## New eid and rcount

##########################################################################################################################################

# Read the initial data set. 
los <- read.csv("LengthOfStay2.csv")

# Get unique encounter ids (eid)
encounter_id_generator <- function(n = 10000000, p = 10){
  encounter_chunks <- c()
  for(i in 1:p){
    encounter_chunks[[i]] <- paste (sprintf("%08d",((i-1)*(n/p)+1):(i*n/p), sep=''))
  }
  return(data.frame(eid = unlist(encounter_chunks)))
}

los$eid <- encounter_id_generator(n = no_of_unique_leads, p = 10)[,1]

# Generate a new rcount variable randomly.
los$rcount <- sample(c("0", "1", "2", "3", "4", "5+"), no_of_unique_leads, replace = TRUE,
                     prob = c(0.55, 0.15, 0.10, 0.08, 0.07, 0.05 ))

##########################################################################################################################################

##(( Make the continuous variables look normal by using the mean and standard deviation of the original data. ))
## Also generate the absolute value of the z-score; used later for the target variable generation. 

##########################################################################################################################################
continuous <- colnames(los)[16:24]

for(name in continuous){
  mean <- mean(los[[name]])
  sd <- sd(los[[name]])  
  #los[[name]] <- rnorm(no_of_unique_leads, mean = mean, sd = sd) 
  name2 <- paste(name, "_z", sep="")
  los[[name2]] <- abs((los[[name]]-mean)/sd)
}


##########################################################################################################################################

## Compute the number of issues variable so it is used later for the target variable generation. 

##########################################################################################################################################


los$number_of_issues <- los$hemo + los$dialysisrenalendstage + los$asthma + los$irondef + los$pneum + los$substancedependence +
                        los$psychologicaldisordermajor + los$depress + los$psychother + los$fibrosisandother +
                        los$malnutrition 

##########################################################################################################################################

## Generate the target variable.

##########################################################################################################################################


# We first assign a score based on number of issues and rcount, and then tweak it by looking at Z-score.  

## Number of issues: 0-10; Buckets to consider: 0, 1-3, 4-6, 7-10.
## rcount: 0: random, 1 quite random, 2 somehow correlated, 3 somehow correlated, 4 high correlation, 5+ high correlation

los$target <- ifelse(los$number_of_issues == 0 & los$rcount == "0", 1,
                     ifelse(los$number_of_issues == 0 & los$rcount == "1", 2, 
                            ifelse(los$number_of_issues == 0 & los$rcount == "2", 4,
                                   ifelse(los$number_of_issues == 0 & los$rcount == "3", 5,
                                          ifelse(los$number_of_issues == 0 & los$rcount == "4", 6,
                                                 ifelse(los$number_of_issues == 0 & los$rcount == "5+", 7,
                                                        ifelse(los$number_of_issues <= 3 & los$rcount == "0", 3,
                                                               ifelse(los$number_of_issues <= 3 & los$rcount == "1", 4,
                                                                      ifelse(los$number_of_issues <= 3 & los$rcount == "2", 5,
                                                                             ifelse(los$number_of_issues <= 3 & los$rcount == "3", 6,
                                                                                    ifelse(los$number_of_issues <= 3 & los$rcount == "4", 7,
                                                                                           ifelse(los$number_of_issues <= 3 & los$rcount == "5+", 8,
                                                                                                  ifelse(los$number_of_issues <= 6 & los$rcount == "0", 4,
                                                                                                         ifelse(los$number_of_issues <= 6 & los$rcount == "1", 5,
                                                                                                                ifelse(los$number_of_issues <= 6 & los$rcount == "2", 6,
                                                                                                                       ifelse(los$number_of_issues <= 6 & los$rcount == "3", 7,
                                                                                                                              ifelse(los$number_of_issues <= 6 & los$rcount == "4", 8,
                                                                                                                                     ifelse(los$number_of_issues <= 6 & los$rcount == "5+", 9,
                                                                                                                                            ifelse(los$rcount == "0", 5, 
                                                                                                                                                   ifelse(los$rcount == "1", 6, 
                                                                                                                                                          ifelse(los$rcount == "2", 7, 
                                                                                                                                                                 ifelse(los$rcount == "3", 8, 
                                                                                                                                                                        ifelse(los$rcount == "4", 9,
                                                                                                                                                                               10)))))))))))))))))))))))



# Z-score (9 variables): 0 to 1.15 is normal, 1.15 to 1.20, is not very normal,  >1.20 is not normal. 
## 0 to 1.15 : add -0.25 
## 1.15 to 1.20: add 1
## >1.20: add 2


los$normal <- rep(0,no_of_unique_leads)
for(name in colnames(los)[29:38]){
  los$normal <- los$normal + ifelse(los[[name]] < 1.15, 1, 0)
}

los$target <- los$target + ifelse(los$normal <= 2, 9, 
                                  ifelse(los$normal >= 8, 0,
                                         ifelse(los$normal == 3, 7,
                                                ifelse(los$normal == 4, 5,
                                                       ifelse(los$normal == 5 , 3,
                                                              ifelse(los$normal == 6, 2,
                                                                      ifelse(los$normal == 7, 1,0)))))))






# Random Tweaking
#los$target <- los$target + sample(c(0,1), no_of_unique_leads, replace = TRUE, prob = c(0.8, 0.2)) - 
#  sample(c(0,1), no_of_unique_leads, replace = TRUE, prob = c(0.8, 0.2))

##########################################################################################################################################

## Create the discharged date based on target 

##########################################################################################################################################

los$vdate <- as.Date(as.character(los$vdate), format = "%m/%d/%y")
los$discharged <- los$vdate + los$target


##########################################################################################################################################

## Remove the feature engineered variables and write the new data to CSV. 

##########################################################################################################################################
to_keep <- c(colnames(los)[1:24], "secondarydiagnosisnonicd9", "discharged", "facid", "target")
los2 <- los[, to_keep]
colnames(los2)[28] <- c("lengthofstay")

# Bucketing. (Changed the bucketing to make 4 more represented). [Moved to feature engineering]
#los2$lengthofstay_bucket <- ifelse(los2$lengthofstay < 4, "1",
#                                   ifelse(los2$lengthofstay < 7, "2",
#                                          ifelse(los2$lengthofstay < 10, "3",
#                                                 "4")))

# Write the data to a CSV file. 
write.csv(los2, file = "LengthOfStayMod.csv", row.names = FALSE , quote = FALSE)