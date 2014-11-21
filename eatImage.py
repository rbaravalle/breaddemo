import numpy as np
import Image
import random
import time
import sys 
from random import randint

I = Image.open(sys.argv[1])
dim = I.size[0]
Nz = I.size[1]/I.size[0]
arr = np.array(I).reshape((Nz,dim,dim))
N = dim
p = 0

def printImg(arr2):
    I3 = Image.new('L',(N,(N)*(Nz)),0.0)
    for w in range(Nz):
        II = Image.frombuffer('L',(N,N), np.array(arr2[0:N,0:N,w]).astype(np.uint8),'raw','L',0,1)
        I3.paste(II,(0,(N)*w))
    I3.save('cutted'+sys.argv[1])

def eatimage(arr):
    arr2 = arr
    for z in range(Nz):
        for y in range(N):
            for x in range(N):

               x1 = x-94
               y1 = N-y+124
               z1 = z-124
               if((x1/1.6)*(x1/1.6)+(y1/1)*(y1/1)+(z1/0.8)*(z1/0.8) < 120*200+randint(0,200)):
                   arr2[z,N-1-y,x] =  0
                   continue

               #x1 = x-120
               #y1 = N-y-65
               #z1 = z-20
               #if(x1*x1+y1*y1+z1*z1 < 125*125+randint(0,300)):
               #    arr2[z,N-1-y,x] =  0
               #    continue

               #if(z > np.sin(2*x)*np.cos(2*y)*np.exp(-(x*x+y*y)/6)):
               #    arr2[z,N-1-y,x] =  0
               #    continue

               limit = np.sqrt((z/0.8-Nz/2)*(z/0.8-Nz/2)+(x/1.6-N/2)*(x/1.6-N/2)+(y/1-N/2)*(y/1-N/2))

               if(z > 170 or y > 170 or x > 170 or x < 10 or y < 10 or z < 10):
                   arr2[z,N-1-y,x] =  0
                   continue

               if(limit > 120+random.randint(0,2)):
                   arr2[z,N-1-y,x] =  0
                   continue

               arr2[z,N-1-y,x] = arr[z,N-1-y,x]

    printImg(arr2)


arr2 = eatimage(arr)
