# End to end validation tests for Python Hospital Length of Stay.

import os
import numpy as np
from pandas import DataFrame, to_numeric

from revoscalepy import RxOdbcData, RxSqlServerData, RxTextData, rx_import, rx_read_object

from SQLConnection import connection_string


def test_step1_check_output():
    col_info = {"eid": {'type': 'integer'},
                "vdate": {'type': 'character'},
                "rcount": {'type': 'character'},
                "gender": {'type': 'factor'},
                "dialysisrenalendstage": {'type': 'factor'},
                "asthma": {'type': 'factor'},
                "irondef": {'type': 'factor'},
                "pneum": {'type': 'factor'},
                "substancedependence": {'type': 'factor'},
                "psychologicaldisordermajor": {'type': 'factor'},
                "depress": {'type': 'factor'},
                "psychother": {'type': 'factor'},
                "fibrosisandother": {'type': 'factor'},
                "malnutrition": {'type': 'factor'},
                "hemo": {'type': 'factor'},
                "hematocrit": {'type': 'numeric'},
                "neutrophils": {'type': 'numeric'},
                "sodium": {'type': 'numeric'},
                "glucose": {'type': 'numeric'},
                "bloodureanitro": {'type': 'numeric'},
                "creatinine": {'type': 'numeric'},
                "bmi": {'type': 'numeric'},
                "pulse": {'type': 'numeric'},
                "respiration": {'type': 'numeric'},
                "secondarydiagnosisnonicd9": {'type': 'factor'},
                "discharged": {'type': 'character'},
                "facid": {'type': 'factor'},
                "lengthofstay": {'type': 'integer'}}

    # Point to the input data set while specifying the classes.
    file_path = "..\\Data"
    LoS_text = RxTextData(file=os.path.join(file_path, "LengthOfStay.csv"),
                          column_info=col_info)
    table_text = rx_import(LoS_text)

    LengthOfStay_sql = RxSqlServerData(sql_query="SELECT * FROM [Hospital_Py].[dbo].[LengthOfStay] ORDER BY eid",
                                       connection_string=connection_string,
                                       column_info=col_info)
    table_sql = rx_import(LengthOfStay_sql)

    assert table_text.equals(table_sql)


def test_step2_check_output():
    LoS_sql = RxSqlServerData(sql_query="SELECT TOP (5) * FROM [Hospital_Py].[dbo].[LoS] ORDER BY eid",
                              connection_string=connection_string)
    LoS = rx_import(input_data=LoS_sql)
    LoS[["number_of_issues"]] = LoS[["number_of_issues"]].apply(to_numeric)

    bmi = [0.312740, -0.671356, -0.48006, -0.921639, 0.226158]
    lengthofstay = [3.0, 7.0, 3.0, 1.0, 4.0]
    number_of_issues = [0, 0, 0, 0, 2]
    d = {"bmi": bmi, "lengthofstay": lengthofstay, "number_of_issues": number_of_issues}
    df = DataFrame(d, index = [0,1,2,3,4])

    assert(LoS.loc[4,'number_of_issues'] == 2)
    assert(LoS.loc[1, 'bmi'] == -0.67135640398687824)
    assert(LoS.loc[3,'lengthofstay'] == 1.0)


def test_step3_check_output():
    # Check that all RTS models have been created
    RTS_odbc = RxOdbcData(connection_string, table="RTS")
    forest_serialized = rx_read_object(RTS_odbc, key="RF", deserialize=False, decompress=None)
    boosted_serialized = rx_read_object(RTS_odbc, key="GBT", deserialize=False, decompress=None)
    fast_serialized = rx_read_object(RTS_odbc, key="FT", deserialize=False, decompress=None)
    NN_serialized = rx_read_object(RTS_odbc, key="NN", deserialize=False, decompress=None)

    assert forest_serialized.__str__()[:6] == "b'blob"
    assert boosted_serialized.__str__()[:6] == "b'blob"
    assert fast_serialized.__str__()[:6] == "b'blob"
    assert NN_serialized.__str__()[:6] == "b'blob"

    # Check that predictions have been made for for all models
    forest_prediction_sql = RxSqlServerData(
        sql_query="SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Forest_Prediction'",
        connection_string=connection_string)
    forest_prediction = rx_import(input_data=forest_prediction_sql)
    boosted_prediction_sql = RxSqlServerData(
        sql_query="SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Boosted_Prediction'",
        connection_string=connection_string)
    boosted_prediction = rx_import(input_data=boosted_prediction_sql)
    fast_prediction_sql = RxSqlServerData(
        sql_query="SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Fast_Prediction'",
        connection_string=connection_string)
    fast_prediction = rx_import(input_data=fast_prediction_sql)
    NN_prediction_sql = RxSqlServerData(
        sql_query="SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'NN_Prediction'",
        connection_string=connection_string)
    NN_prediction = rx_import(input_data=NN_prediction_sql)

    assert isinstance(forest_prediction, DataFrame)
    assert isinstance(boosted_prediction, DataFrame)
    assert isinstance(fast_prediction, DataFrame)
    assert isinstance(NN_prediction, DataFrame)