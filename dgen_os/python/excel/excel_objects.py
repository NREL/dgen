import openpyxl as xl
from io import StringIO
import numpy as np
import pandas as pd
import datetime

class ExcelError(Exception):
    pass

class FancyNamedRange(object):
    
    def __init__(self, workbook, range_name):
        
        self.wb = workbook
        
        self.base = self.__base__(range_name)
        
        self.worksheets = self.__worksheets__()
        
        self.count_worksheets = self.__count_destination_components__(self.worksheets)
        if self.count_worksheets > 1:
            raise NotImplementedError("Named Ranges spanning multiple worksheets are not currently supported")
            
        self.worksheet = self.worksheets[0]            
            
        self.cell_ranges = self.__cell_ranges__()
        
        self.count_cell_ranges = self.__count_destination_components__(self.cell_ranges)

        if self.count_cell_ranges > 1:
            raise NotImplementedError("Named Ranges spanning multiple, non-contiguous cell ranges  are not currently supported")
        
        self.cell_range = self.cell_ranges[0]        
        
        self.topleft = self.__topleft__()

        self.bottomright = self.__bottomright__()
        
        self.cells = self.__cells__()
        
        self.cell_array = self.__cell_array__()
        
        self.rec_array = self.__rec_array__()
        
        self.data_frame = self.__data_frame__()

    def __colnames_included__(self):
        self.rec_array = self.__rec_array__(colnames_included = True)
        self.data_frame = self.__data_frame__(colnames_included = True)
    
    def __melt__(self):
        self.__colnames_included__()
        # find the data type for the column names
        dtype = self.data_frame.columns.dtype
        self.data_frame = pd.melt(self.data_frame, self.data_frame.columns[0])
        # set the data type for the variable column
        self.data_frame.loc[:, 'variable'] = self.data_frame['variable'].astype(dtype)

    def __transpose_values__(self):
        
        self.cell_array = self.cell_array.T
        self.rec_array = self.__rec_array__()
        self.data_frame = self.__data_frame__()

    def __base__(self, range_name):
        
        # get the named range object
        base = self.wb.defined_names[range_name]
        
        # raise an error if the named range doesn't exist
        if base == None:
            raise ExcelError('{} named range does not exist.'.format(range_name))
        
        return base    
    
    def __worksheets__(self):
        worksheets = list(np.array([(a, b) for a, b in self.base.destinations])[:,0])
        return worksheets
        
    def __cell_ranges__(self):
        cell_ranges = list(np.array([(a, b) for a, b in self.base.destinations])[:,1])
        return cell_ranges
        
    
    def __count_destination_components__(self, destination_component):
        count = len(list(set(destination_component)))
        return count
    
    def __topleft__(self):
        if ':' in self.cell_ranges[0]:
            coordinates = self.cell_ranges[0].split(':')[0]
        else:
            coordinates = self.cell_ranges[0]
            
        return coordinates
        
    def __bottomright__(self):
        if ':' in self.cell_ranges[0]:
            coordinates = self.cell_ranges[0].split(':')[1]
        else:
            coordinates = self.cell_ranges[0]
        
        return coordinates
    
    def contents_to_array(self):
        pass
    
    def __columns__(self):
        self.topleft.split('$')
        
    def __cells__(self):
        cells = [cell for cell in self.wb[self.worksheet][self.topleft : self.bottomright]]
        return cells
    
    def __cell_array__(self):
        cell_array = np.array(self.cells)
        if cell_array.shape == ():
            cell_array = cell_array.reshape((1,1))
        
        return cell_array
        
    def __cell_value__(self, cell, floats = True):
        if floats == True and cell.data_type == 'n' and type(cell.value) != datetime.datetime:
            if cell.value is None:
                cell_value = float(np.nan)
            else:
                cell_value = float(cell.value)
        else:
            cell_value = cell.value
        
        if cell_value is None:
            cell_value = np.nan
        
        return cell_value
    
    def __rec_array__(self, colnames_included = False):
        cell_values = np.vectorize(self.__cell_value__)
        
        if colnames_included == True:
            i_begin = 1
        else:
            i_begin = 0
        
        cols = []
        for j in range(self.cell_array.shape[1]):
            col = cell_values(self.cell_array[i_begin:, j])
            if col.dtype.kind not in ('S', 'b', 'U', 'O') and np.all(col.astype('int') == col):
                col = col.astype('int')
            cols.append(col)
        
        rec_array = np.rec.fromarrays(cols)
        if colnames_included == True:
            names = cell_values(self.cell_array[0, :], floats = False)
            rec_array.dtype.names = list(map(str, list(names)))
        
        return rec_array
    
    def __data_frame__(self, colnames_included = False):
        df = pd.DataFrame(self.rec_array)
        if colnames_included == False:
            ncols = df.shape[1]
            df.columns = list(range(0, ncols))
        
        return df
        
    def first_value(self):
        first_value = self.data_frame.iloc[0][0]

        return first_value

    def to_stringIO(self, transpose = False, columns = None, index = False, header = False):
        s = StringIO()
        
        if columns == None:
            columns = self.data_frame.columns
        
        if transpose:
            out_df = self.data_frame[columns].T
        else:
            out_df = self.data_frame[columns]

        try:
            out_df.to_csv(s, delimiter = ',', index = index, header = header)
        except:
            out_df.to_csv(s, index=index, header=header)
        s.seek(0)
        
        return s
        
    def to_postgres(self, connection, cursor, schema, table, transpose = False, columns = None, create = False, overwrite = True):
        sql_dict = {'schema': schema, 'table': table }
        
        if create == True:
            raise NotImplementedError('Creation of a new postgres table is not implemented')
        
        s = self.to_stringIO(transpose, columns)        

        connection.commit()           
        if overwrite == True:
            sql = 'DELETE FROM {}.{};'.format(schema, table)
            cursor.execute(sql)
            connection.commit()
 
        f = "COPY {}.{} FROM STDIN WITH DELIMITER AS ',' NULL AS ''".format(schema, table)

        cursor.copy_expert(f, s)
        connection.commit()    
        
        # release the string io object
        s.close()      