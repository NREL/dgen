# -*- coding: utf-8 -*-
"""
Created on Thu Jan  8 13:14:32 2015

@author: mgleason
"""

import time
from functools import wraps

def shared(f):
    f.shared = True
    return f  


def unshared(f):
    f.shared = False
    return f  

    
class fid(object):
    
    def __init__(self, i):
        self.fid = i

    def __call__(self, f):
        f.fid = self.fid
        return f
  
        
class fn_timer(object):
    
    def __init__(self, logger = None, verbose = True, tab_level = 0, prefix = ''):
        self.verbose = verbose
        self.tabs = '\t' * tab_level
        self.prefix = prefix
        self.logger = logger

    def __call__(self, f):
            @wraps(f)
            def function_timer(*args, **kwargs):
                t0 = time.time()
                result = f(*args, **kwargs)
                t1 = time.time()
                if self.verbose:
                    duration = round(t1 - t0, 2)
                    msg = '{0}{1}{2} completed in: {3} seconds'.format(self.tabs, self.prefix, f.__name__, duration)
                    if self.logger is not None:
                        self.logger.info(msg)
                    else:
                        print(msg)
                return result
            return function_timer        


class fn_info(object):
    
    def __init__(self, info, logger = None, tab_level = 0):
        self.info = info
        self.tabs = '\t' * tab_level
        self.logger = logger

    def __call__(self, f):
            @wraps(f)
            def function_status_info(*args, **kwargs):
                msg = '{0}{1}'.format(self.tabs, self.info)
                if self.logger is not None:
                    self.logger.info(msg)
                else:
                    print(msg)
                result = f(*args, **kwargs)
                return result
            return function_status_info    
