#ifndef TD_RESOURCES_RESOURCE_MAN_H
#define TD_RESOURCES_RESOURCE_MAN_H

//#include "AsyncResource.h"

#include <tr1/memory>

#include "AsyncResource.h"


namespace tdresources {
    
    
    
    
    class ResourceManager {
        //friend class AsyncResource;
        std::tr1::shared_ptr<AsyncResource> getFromCache(const std::string& key) {
            
        }
        
        
    public:
        
        template <typename T>
        std::tr1::shared_ptr<T> 
        load(const std::string& url) {
            std::string key = T::typeName + url;
            
            std::tr1::shared_ptr<T> r = std::tr1::dynamic_pointer_cast<T>(getFromCache(key));
            
            if (!r) {
                
            }
            
            
            return r;
            
        }
        
        
        
        
        
        /**
         * aborts all in-progress async loads
         * note. if a strong references to the resources still exist
         * the loading process will be restarted again
         */ 
        void resetAsyncLoads();
        
        
        
        
        
        
        
        /**
         * give the ResourceManager access to the main thread
         * allowing it to for example: stream data to GL or do callbacks 
         */
        void finishLoads();
    };
    
    
    
    
}













#endif