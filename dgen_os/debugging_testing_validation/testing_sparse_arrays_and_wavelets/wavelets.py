# -*- coding: utf-8 -*-
"""
Created on Fri Jan  8 20:25:19 2016

@author: mgleason
"""

import pywt
import numpy as np
import sys
import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('/Users/mgleason/NREL_Projects/github/diffusion/python/sample_8760.csv')
l = [int(x) for x in df['cf'][0][1:-1].split(',')]
a = np.array(l)

coefs = pywt.wavedec(a, 'db1')

sys.getsizeof(coefs)
sys.getsizeof(a)
coefs = pywt.wavedec(a, 'db1')
rec = pywt.waverec(coefs, 'db1')

print 'Wavelets Size: %s' % sys.getsizeof(coefs)
print 'Actual Size: %s' % sys.getsizeof(a)


np.max(a - rec)


fig, axes = plt.subplots(1, 2, sharey=True, sharex=True,
                         figsize=(10,8))
ax1, ax2 = axes

ax1.plot(a)
ax1.set_title("Actual Signal")
ax1.margins(.1)

ax2.plot(rec)
ax2.set_title("Recovered Signal")





s = SparseArray(a, 'int64', 0)
w = pywt.wavedec(s.data, 'db1')
sys.getsizeof(w)
sys.getsizeof(s.data)