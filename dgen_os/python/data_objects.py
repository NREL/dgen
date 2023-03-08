
import pandas as pd
import numpy as np
from io import StringIO

class FancyDataFrame(pd.DataFrame):
    
    def __init__(self, **kwargs):
        
        pd.DataFrame.__init__(self, **kwargs)
                                   
        
    def to_stringIO(self, transpose = False, columns = None, index = False, header = False):
        
        s = StringIO()
        
        if columns == None:
            columns = self.columns
        
        if transpose:
            out_df = self[columns].T
        else:
            out_df = self[columns]
            
        out_df.to_csv(s, delimiter = ',', index = index, header = header)
        
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