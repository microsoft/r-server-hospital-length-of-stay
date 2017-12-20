import pyodbc
from revoscalepy import RxSqlServerData, rx_import, RxOdbcData, rx_write_object, rx_serialize_model
from collections import OrderedDict
import numpy as np

def display_head(table_name, n_rows):
    table_sql = RxSqlServerData(sql_query = "SELECT TOP({}}) * FROM {}}".format(n_rows, table_name), connection_string = connection_string)
    table = rx_import(table_sql)
    print(table)


def detect_table(table_name, connection_string):
    detect_sql = RxSqlServerData(sql_query="IF EXISTS (select 1 from information_schema.tables where table_name = '{}') SELECT 1 ELSE SELECT 0".format(table_name),
                                 connection_string=connection_string)
    does_exist = rx_import(detect_sql)
    if does_exist.iloc[0,0] == 1: return True
    else: return False


def drop_view(view_name, connection_string):
    pyodbc_cnxn = pyodbc.connect(connection_string)
    pyodbc_cursor = pyodbc_cnxn.cursor()
    pyodbc_cursor.execute("IF OBJECT_ID ('{}', 'V') IS NOT NULL DROP VIEW {} ;".format(view_name, view_name))
    pyodbc_cursor.close()
    pyodbc_cnxn.commit()
    pyodbc_cnxn.close()


def alter_column(table, column, data_type, connection_string):
    pyodbc_cnxn = pyodbc.connect(connection_string)
    pyodbc_cursor = pyodbc_cnxn.cursor()
    pyodbc_cursor.execute("ALTER TABLE {} ALTER COLUMN {} {};".format(table, column, data_type))
    pyodbc_cursor.close()
    pyodbc_cnxn.commit()
    pyodbc_cnxn.close()


def get_num_rows(table, connection_string):
    count_sql = RxSqlServerData(sql_query="SELECT COUNT(*) FROM {};".format(table), connection_string=connection_string)
    count = rx_import(count_sql)
    count = count.iloc[0,0]
    return count


def create_formula(response, features, to_remove=None):
    if to_remove is None:
        feats = [x for x in features if x not in [response]]
    else:
        feats = [x for x in features if x not in to_remove and x not in [response]]
    formula = "{} ~ ".format(response) + " + ".join(feats)
    return formula


def train_test_split(id, table, train_table, p, connection_string):
    pyodbc_cnxn = pyodbc.connect(connection_string)
    pyodbc_cursor = pyodbc_cnxn.cursor()
    pyodbc_cursor.execute("DROP TABLE if exists {};".format(train_table))
    pyodbc_cursor.execute("SELECT {} INTO {} FROM {} WHERE ABS(CAST(BINARY_CHECKSUM(eid, NEWID()) as int)) % 100 < {} ;".format(id, train_table, table, p))
    pyodbc_cursor.close()
    pyodbc_cnxn.commit()
    pyodbc_cnxn.close()


def write_rts_model(model, key, connection_string):
    RTS_odbc = RxOdbcData(connection_string, table="RTS")
    serialized_model = rx_serialize_model(model, realtime_scoring_only=True)
    rx_write_object(RTS_odbc, key=key, value=serialized_model, serialize=False, compress=None, overwrite=True)


def evaluate_model(observed, predicted, model):
    mean_observed = np.mean(observed)
    se = (observed - predicted)**2
    ae = abs(observed - predicted)
    sem = (observed - mean_observed)**2
    aem = abs(observed - mean_observed)
    mae = np.mean(ae)
    rmse = np.sqrt(np.mean(se))
    rae = sum(ae) / sum(aem)
    rse = sum(se) / sum(sem)
    rsq = 1 - rse
    metrics = OrderedDict([ ("model_name", [model]),
				("mean_absolute_error", [mae]),
                ("root_mean_squared_error", [rmse]),
                ("relative_absolute_error", [rae]),
                ("relative_squared_error", [rse]),
                ("coefficient_of_determination", [rsq]) ])
    print(metrics)
    return(metrics)