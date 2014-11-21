//|||||||||||||||||||||||||||||||||||||||||||||||

#ifndef VOLUME_BOUNDING_CUBES_HPP
#define VOLUME_BOUNDING_CUBES_HPP

#include "Volume.hpp"

#include <Ogre.h>
#include <stdint.h>


//|||||||||||||||||||||||||||||||||||||||||||||||

class VolumeBoundingCubes 
{
public:
        int create(Volume& vol, int slices, 
                   float min, float max,
                   Ogre::SceneManager* sceneMgr);

        int _create(Volume& vol, int slices, 
                   float min, float max,
                   Ogre::SceneManager* sceneMgr);

        void setMaterial(Ogre::String materialName);

private:

        int _createGeometry(std::vector<Ogre::Vector3>& vertices,
                            std::vector<uint32_t>& indices,
                            Ogre::SceneManager* sceneMgr);

        int _createCubes(std::vector<Ogre::Vector3>& vertices,
                          std::vector<uint32_t>& indices,
                          Ogre::SceneManager* sceneMgr);

        VolumeBounds   _bounds;
        int            _slices;
        
        std::vector<Ogre::Vector3>  _vs; //Vertices
        std::vector<uint32_t> _is; //Indices

        Ogre::Entity*    _entity;
        Ogre::MeshPtr    _mesh;
        Ogre::SceneNode* _node;
};

#endif


