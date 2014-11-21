import numpy as np
import Image
import random
import time
from random import randint

N = 128
Nz = 128
arr = np.zeros((N,N,N))
arr2 = np.zeros((N,N,N))
p = 0

def printImg(arr):
    I3 = Image.new('L',(N,(N)*(Nz)),0.0)
    for w in range(Nz):
        II = Image.frombuffer('L',(N,N), np.array(arr[0:N,0:N,w]).astype(np.uint8),'raw','L',0,1)
        I3.paste(II,(0,(N)*w))
    I3.save('randomImage.png')

def eatimage():
    for x in range(N):
        for y in range(N):
            for z in range(Nz):
                arr[x,y,z] = randint(0,2)*255
          

    printImg(arr)

eatimage()
