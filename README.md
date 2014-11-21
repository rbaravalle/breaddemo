Real Time Realistic Rendering of Bread Crumbs

This demo allows to construct a 3D image using python and to visualize it in OGRE. The final appearance is similar to bread crumbs and run in real time. Also, other materials such as sponges can be renderized.

Dependencies: 
python >= 2.7.3
cython >= 0.19.2
Ogre >= 1.9

----------------
To construct an image, run:

python mainprocs.py #This will compile with cython the .pyx files.
python main2.py # constructs the image (takes time..)

----------------
If you do not want to see the construction process, just use one of the images in textures/*.

To change the 3D volume field set in OGRE (AFTER COMPILING OGRE) and then just type

python rtexs.py <filename>

For instance:

python rtexs.py textures/randomImage.png (this is used to render a sponge)
