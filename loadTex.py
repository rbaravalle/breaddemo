import numpy as np
import Image
import random
import time
import cprint
import sys 

I = Image.open(sys.argv[1])
dim = I.size[0]
#print dim, I.size
Nz = I.size[1]/I.size[0]
arr = np.array(I).reshape((Nz,dim,dim))
N = dim
p = 0
cprint.cprint(p,Nz,N,arr)


