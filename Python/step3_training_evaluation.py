##########################################################################################################################################
## This Python script will do the following:
## 1. Split LoS into a Training LoS_Train, and a Testing set LoS_Test.
## 2. Train Random Forest (rx_dforest implementation) and Boosted Trees (rxFastTrees [work in progress] implementation) and save them to SQL.
## 3. Score the models on LoS_Test.
## 4. Evalaute the scored models.

## Input : Data set LoS
## Output: Regression Random forest and Boosted Trees saved to SQL.

##########################################################################################################################################

## Compute Contexts and Packages

##########################################################################################################################################

# Load packages.
import sys
from math import sqrt

from revoscalepy import rx_dforest, rx_btrees, rx_predict, RxSqlServerData, rx_get_var_names
from revoscalepy import rx_set_compute_context, rx_import, rx_data_step

from microsoftml import rx_fast_trees, rx_neural_network, adadelta_optimizer
from microsoftml import rx_predict as ml_predict

from length_of_stay_utils import train_test_split, evaluate_model, create_formula, get_num_rows, write_rts_model
from SQLConnection import *

# Set the Compute Context to local.
rx_set_compute_context(local)

##########################################################################################################################################

## Input: Point to the SQL table with the data set for modeling

##########################################################################################################################################

LoS = RxSqlServerData(table="LoS", connection_string=connection_string, strings_as_factors=True)

##########################################################################################################################################

##	Split the data set into a training and a testing set

##########################################################################################################################################

# Randomly split the data into a training set and a testing set, with a splitting % p.
# p % goes to the training set, and the rest goes to the testing set. Default is 70%.

p = 70

## Create the Train_Id table containing Lead_Id of training set.
train_test_split("eid", "LoS", "Train_Id", p, connection_string)

## Point to the training set. It will be created on the fly when training models.
variables_all = rx_get_var_names(LoS)
variables_to_remove = ["eid", "vdate", "discharged", "facid"]
training_variables = [x for x in variables_all if x not in variables_to_remove]
LoS_Train = RxSqlServerData(sql_query="SELECT eid, {} FROM LoS WHERE eid IN (SELECT eid from Train_Id)".format(
    ', '.join(training_variables)), connection_string=connection_string, column_info=col_type_and_factor_info
)

## Point to the testing set. It will be created on the fly when testing models.
LoS_Test = RxSqlServerData(sql_query="SELECT eid, {} FROM LoS WHERE eid NOT IN (SELECT eid from Train_Id)".format(
    ', '.join(training_variables)), connection_string=connection_string, column_info=col_type_and_factor_info
)

##########################################################################################################################################

##	Specify the variables to keep for training

##########################################################################################################################################

# Write the formula after removing variables not used in the modeling.
formula = create_formula("lengthofstay", variables_all, variables_to_remove)
print("Formula: ", formula)

##########################################################################################################################################

## Functions to automate hyperparameter tuning. They use internal oob error estimates as the basis for tuning.
## NOTE: When it comes to tuning, Cross Validation or a Train-Validate-Test split would be better than using OOB error.

##########################################################################################################################################

num_rows = get_num_rows("Train_Id", connection_string)

def tune_rx_dforest(formula, data, n_tree_list, cp_list, cc):
    print("Tuning rx_dforest")
    best_error = sys.maxsize
    best_model = None
    for nt in n_tree_list:
        for cp in cp_list:
            model = rx_dforest(formula=formula,
                               data=data,
                               n_tree=nt,
                               cp=cp,
                               min_split=int(sqrt(num_rows)),
                               max_num_bins=int(sqrt(num_rows)),
                               seed=5,
                               compute_context=cc)
            error = model.oob_err['oob.err'][model.ntree - 1]
            print("OOB Error: {} \t n_tree: {} \t cp: {}".format(error, nt, cp))
            if error < best_error:
                best_error = error
                best_model = model
    return best_model


def tune_rx_btrees(formula, data, n_tree_list, lr_list, cp_list, cc):
    print("Tuning rx_btrees")
    best_error = sys.maxsize
    best_model = None
    for nt in n_tree_list:
        for lr in lr_list:
            for cp in cp_list:
                model = rx_btrees(formula=formula,
                                  data=data,
                                  n_tree=nt,
                                  learning_rate=lr,
                                  cp=cp,
                                  loss_function="gaussian",
                                  min_split=int(sqrt(num_rows)),
                                  max_num_bins=int(sqrt(num_rows)),
                                  seed=9,
                                  compute_context=cc)
                error = model.oob_err['oob.err'][model.ntree - 1]
                print("OOB Error: {} \t n_tree: {} \t learning_rate: {} \t cp: {}".format(error, nt, lr, cp))
                if error < best_error:
                    print("^^^ New best model!")
                    best_error = error
                    best_model = model
    return best_model

##########################################################################################################################################

##	Random Forest (rx_dforest implementation) Training and saving the model to SQL

##########################################################################################################################################

# Tune the Random Forest. This tunes on the basis of minimizing oob error. Compute context is set to sql for model training.
forest_model = tune_rx_dforest(formula, LoS_Train, n_tree_list=[40], cp_list=[0.00005], cc=sql)

# serialize and write for Real Time Scoring
write_rts_model(forest_model, "RF", connection_string)

##########################################################################################################################################

##	Boosted Trees (rx_btrees implementation) Training and saving the model to SQL

##########################################################################################################################################

# Train the Boosted Trees model. This tunes on the basis of minimizing oob error.
boosted_model = tune_rx_btrees(formula, LoS_Train, n_tree_list=[40], lr_list=[0.3], cp_list=[0.00005], cc=sql)

# serialize and write for Real Time Scoring
write_rts_model(boosted_model, "GBT", connection_string)

##########################################################################################################################################

##	Fast Trees (rx_fast_trees implementation) Training and saving the model to SQL

##########################################################################################################################################

# Train the Fast Trees model.
print("Training Fast Trees")
fast_model = rx_fast_trees(formula=formula,
                          data=LoS_Train,
                          method="regression",
                          num_trees=40,
                          learning_rate=0.2,
                          split_fraction=5/24,
                          min_split=10,
                          compute_context=sql)

write_rts_model(fast_model, "FT", connection_string)

##########################################################################################################################################

##	Neural Network (rx_neural_network implementation) Training and saving the model to SQL

##########################################################################################################################################

# Train the Fast Trees model.
print("Training Neural Network")
NN_model = rx_neural_network(formula=formula,
                            data=LoS_Train,
                            method="regression",
                            num_hidden_nodes=128,
                            num_iterations=100,
                            optimizer=adadelta_optimizer(),
                            mini_batch_size=20,
                            compute_context=sql)

write_rts_model(NN_model, "NN", connection_string)

##########################################################################################################################################

## Regression model evaluation metrics

##########################################################################################################################################

# Write a function that computes regression performance metrics.


##########################################################################################################################################

##	Random Forest Scoring

##########################################################################################################################################

# Make Predictions, then import them into Python.
forest_prediction_sql = RxSqlServerData(table="Forest_Prediction", strings_as_factors=True, connection_string=connection_string)
rx_predict(forest_model,
           data=LoS_Test,
           output_data=forest_prediction_sql,
           type="response",
           extra_vars_to_write=["lengthofstay", "eid"],
           overwrite=True)

# Compute the performance metrics of the model.
forest_prediction = rx_import(input_data=forest_prediction_sql)
forest_metrics = evaluate_model(observed=forest_prediction['lengthofstay'], predicted=forest_prediction['lengthofstay_Pred'], model="RF")

##########################################################################################################################################

##	Boosted Trees Scoring

##########################################################################################################################################

# Make Predictions, then import them into Python.
boosted_prediction_sql = RxSqlServerData(table="Boosted_Prediction", strings_as_factors=True, connection_string=connection_string)
rx_predict(boosted_model,
           data=LoS_Test,
           output_data=boosted_prediction_sql,
           extra_vars_to_write=["lengthofstay", "eid"],
           overwrite=True)

# Compute the performance metrics of the model.
boosted_prediction = rx_import(input_data=boosted_prediction_sql)
boosted_metrics = evaluate_model(observed=boosted_prediction['lengthofstay'], predicted=boosted_prediction['lengthofstay_Pred'], model="GBT")

##########################################################################################################################################

##	Fast Trees Scoring

##########################################################################################################################################

# Make Predictions, then write them to a table.
LoS_Test_import = rx_import(input_data=LoS_Test)
fast_prediction = ml_predict(fast_model, data=LoS_Test_import, extra_vars_to_write=["lengthofstay", "eid"], overwrite=True)
fast_prediction_sql = RxSqlServerData(table="Fast_Prediction", strings_as_factors=True, connection_string=connection_string)
rx_data_step(input_data=fast_prediction, output_file=fast_prediction_sql, overwrite=True)

# Compute the performance metrics of the model.
fast_metrics = evaluate_model(observed=fast_prediction['lengthofstay'], predicted=fast_prediction['Score'], model="FT")

##########################################################################################################################################

##	Neural Networks Scoring

##########################################################################################################################################

# Make Predictions, then write them to a table.
NN_prediction = ml_predict(NN_model, data=LoS_Test_import, extra_vars_to_write=["lengthofstay", "eid"], overwrite=True)
NN_prediction_sql = RxSqlServerData(table="NN_Prediction", strings_as_factors=True, connection_string=connection_string)
rx_data_step(input_data=NN_prediction, output_file=NN_prediction_sql, overwrite=True)

# Compute the performance metrics of the model.
NN_metrics = evaluate_model(observed=NN_prediction['lengthofstay'], predicted=NN_prediction['Score'], model="NN")

##########################################################################################################################################

##	Write to Master Predictions Table (LoS_Predictions)

##########################################################################################################################################

print("Writing LoS_Predictions")
query = """SELECT LengthOfStay.eid, CONVERT(DATE, LengthOfStay.vdate, 110) as vdate, LengthOfStay.rcount, LengthOfStay.gender,
               LengthOfStay.dialysisrenalendstage, LengthOfStay.asthma, LengthOfStay.irondef, LengthOfStay.pneum, LengthOfStay.substancedependence,
               LengthOfStay.psychologicaldisordermajor, LengthOfStay.depress, LengthOfStay.psychother, LengthOfStay.fibrosisandother,
               LengthOfStay.malnutrition, LengthOfStay.hemo, LengthOfStay.hematocrit, LengthOfStay.neutrophils, LengthOfStay.sodium,
               LengthOfStay.glucose, LengthOfStay.bloodureanitro, LengthOfStay.creatinine, LengthOfStay.bmi, LengthOfStay.pulse,
               LengthOfStay.respiration, number_of_issues, LengthOfStay.secondarydiagnosisnonicd9,
               CONVERT(DATE, LengthOfStay.discharged, 110) as discharged, LengthOfStay.facid, LoS.lengthofstay,
               CONVERT(DATE, CONVERT(DATETIME, LengthOfStay.vdate, 110) + CAST(ROUND(Score, 0) as int), 110) as discharged_Pred,
               CAST(ROUND(Score, 0) as int) as lengthofstay_Pred
         FROM LoS JOIN Fast_Prediction ON LoS.eid = Fast_Prediction.eid JOIN LengthOfStay ON LoS.eid = LengthOfStay.eid;"""
results_sql = RxSqlServerData(sql_query=query, connection_string=connection_string)
los_pred_sql = RxSqlServerData(table="LoS_Predictions", connection_string=connection_string)
rx_data_step(results_sql, los_pred_sql, overwrite=True)