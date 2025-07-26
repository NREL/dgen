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
        # 1) sanity checks
        if not os.path.exists(xls_file):
            raise ExcelError(f'The specified input worksheet ({xls_file}) does not exist')

        mapping_file = os.path.join(path, 'table_range_lkup.csv')
        if not os.path.exists(mapping_file):
            raise ExcelError(f'The mapping file ({mapping_file}) does not exist')
        
        # 2) read & filter mappings
        mappings = pd.read_csv(mapping_file)
        mappings = mappings[mappings.run == True]

        # 3) Monkey‐patch this cursor *after* mappings is defined
        if not hasattr(cur, "copy_expert"):
            def _copy_expert(sql, file_obj):
                # pg8000’s COPY via execute(..., stream=...)
                return cur.execute(sql, stream=file_obj)
            cur.copy_expert = _copy_expert

        # 4) open workbook
        with warnings.catch_warnings():
            warnings.filterwarnings("ignore", message="Discarded range with reserved name")
            wb = xl.load_workbook(xls_file, data_only=True, read_only=True)

        # 5) iterate & load
        for run, table, range_name, transpose, melt in mappings.itertuples(index=False):
            fnr = FancyNamedRange(wb, range_name)
            if transpose:
                fnr.__transpose_values__()
            if melt:
                fnr.__melt__()
            fnr.to_postgres(con, cur, schema, table)

    except ExcelError as e:
        raise ExcelError(e)
