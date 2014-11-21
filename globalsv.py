import numpy as np
from maths import *
from random import randint, random
from math import floor, sqrt

# global vars
maxcoord = 128
maxcoordZ = 128
maxcoord2 = maxcoord*maxcoord
maxcoord3 = maxcoord2*maxcoordZ
m1 = 1.0/maxcoord
t = 0

N = 10
cp = np.zeros(50) # # of particles per size (see below)
lt = np.zeros(50) # lifetime of particles
CT = 0
distG = 0.8
cantG = 20 # amount of generators
sembrado = 0 # random or uniform
VF = 10.59
MCA = 5000
stCA = 6000
randomness = 0.1

#2D-world limits
x0 = -25
y0 = -25
x1 = 25
y1 = 25
z0 = 0
z1 = 50
diffX = x1-x0
diffY = y1-y0
diffZ = z1-z0

generadores = np.array([[0,0,0]])

TIEMPO = 120000
sep = 1 # separation among particles
diffBubbles = 18
amountSons = 0

def compute_lifetimes() :
    M = stCA*stCA

    s = sign()
    # compute lifetimes
    for i in range(N-1):
        x = randint(0,floor(M))
        M = M - x
        s = -s
        lt[i] = floor(s*sqrt(x)) + MCA
    summ = 0
    CT2 = floor(VF*maxcoord3/MCA)
    # calculate amount of particles per lifetime
    for i in range(N-2):
        cp[i] = randint(0,CT2)
        CT2 = CT2 - cp[i]
        summ = summ + cp[i]*lt[i] 
    
    if(lt[N-1] > 0) : cp[N-1] = floor((VF*maxcoord3 - summ)/lt[N-1])
    print "Cp: ", cp
    print "Lt: ", lt
    for i in range(1,50):
        fieldsize = maxcoord*maxcoord*maxcoordZ
        cp[i-1] = fieldsize/(1000*i*i*i)
        lt[i-1] = 100*i

    print "Cp: ", cp
    print "Lt: ", lt
            

def init_variables() :
    global generadores
    compute_lifetimes()

    if(sembrado == 0) :
        for i in range(cantG):
            b = np.array([[randint(0,maxcoord), randint(0,maxcoord),randint(0,maxcoordZ)]])
            generadores = np.concatenate((generadores,b), axis = 0)

        
    else :
        step = np.float32(maxcoord/cantG)
        for i in range(0,maxcoord,step):
            for j in range(0,maxcoord,step):
                for k in range(0,maxcoordZ,step):
                    b = np.array([[floor(i),floor(j),floor(k)]])
                    generadores = np.concatenate((generadores,b), axis = 0)

    generadores = generadores[1:] # take out the dummy (0,0,0)
    print generadores

def ocupada(i):
    return (occupied[i] > 0)

#print "Init..."
#init_variables()
