#ifndef TD_MODEL_WORLDMAP_H
#define TD_MODEL_WORLDMAP_H

#include <tr1/memory>
//#include <string>
#include "AsyncResource.h"
#include "ResourceMan.h"

namespace tdmodel {
    
    
    
    
    class WorldMap : public tdresources::AsyncResource {
        
        static const std::string typeName;
        
        
        static std::tr1::shared_ptr<WorldMap> 
          load(const tdresources::ResourceManager& resman, const std::string& url);
    };
    
    
    
    
}















#endif