import openpyxl as xl
import sys
import os
from .excel_objects import FancyNamedRange, ExcelError
import pandas as pd

import warnings


path = os.path.dirname(os.path.abspath(__file__))
par_path = os.path.dirname(path)
sys.path.append(par_path)
import utility_functions as utilfunc
import decorators
#==============================================================================
# Load logger
logger = utilfunc.get_logger()
#==============================================================================

@decorators.fn_timer(logger=logger, tab_level=1, prefix='')
def load_scenario(xls_file, schema, con, cur):

    logger.info('Loading Input Scenario Worksheet')

    try:

        if os.path.exists(xls_file) == False:
            raise ExcelError('The specified input worksheet ({}) does not exist'.format(xls_file))

        # get the table to named range lookup from csv
        mapping_file = os.path.join(path, 'table_range_lkup.csv')
        if os.path.exists(mapping_file) == False:
            raise ExcelError('The required file that maps from named ranges to postgres tables ({}) does not exist'.format(mapping_file))
        mappings = pd.read_csv(mapping_file)
        # only run the mappings that are marked to run
        mappings = mappings[mappings.run == True]

        # open the workbook
        with warnings.catch_warnings():
            # ignore meaningless warning
            warnings.filterwarnings(
                "ignore", message="Discarded range with reserved name")
            wb = xl.load_workbook(xls_file, data_only=True, read_only=True)

        for run, table, range_name, transpose, melt in mappings.itertuples(index=False):
            fnr = FancyNamedRange(wb, range_name)
            if transpose == True:
                fnr.__transpose_values__()
            if melt == True:
                fnr.__melt__()
           
            fnr.to_postgres(con,cur, schema, table)
           
    except ExcelError as e:
        raise ExcelError(e)
