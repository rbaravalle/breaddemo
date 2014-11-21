import numpy as np
cimport numpy as np

cdef extern from "math.h":
    int round(float x)

DTYPE = np.uint8
DTYPE_f = np.float32
ctypedef np.uint8_t DTYPE_t
ctypedef np.float32_t DTYPE_tf


# warp a 3D field using the gradient G(gx,gy,gz)
def warp2D(np.ndarray[DTYPE_tf, ndim=2] field, np.ndarray[DTYPE_tf, ndim=2] gx, np.ndarray[DTYPE_tf, ndim=2] gy, int N, float k):
    cdef int x,y,u,v
    cdef np.ndarray[DTYPE_tf, ndim=2] field2 = np.zeros((N,N),dtype=DTYPE_f)
    for x from 0<=x<N:    
        for y from 0<=y<N:
            u = round(x+k*gx[x,y])
            v = round(y+k*gy[x,y])
            try:
                field2[x,y] = field[u,v]
            except: pass

    return field2

# warp a 3D field using the gradient G(gx,gy,gz)
def warp(np.ndarray[DTYPE_t, ndim=3] field, np.ndarray[DTYPE_tf, ndim=3] gx, np.ndarray[DTYPE_tf, ndim=3] gy, np.ndarray[DTYPE_tf, ndim=3] gz, int N, int Nz, float k):
    cdef int x,y,z,u,v,w
    cdef np.ndarray[DTYPE_t, ndim=3] field2 = np.zeros((N,N,Nz),dtype=DTYPE)
    for x from 0<=x<N:    
        for y from 0<=y<N:
            for z from 0<=z<Nz:
                u = round(x+k*gx[x,y,z])
                v = round(y+k*gy[x,y,z])
                w = round(z+k*gz[x,y,z])
                try:
                    field2[x,y,z] = field[u,v,w]
                except: pass

    return field2
