#ifndef TD_RESOURCES_ASYNCRESOURCE_H
#define TD_RESOURCES_ASYNCRESOURCE_H


#include <tr1/memory>
#include <string>



namespace tdresources {
    

    class AsyncResource {
        
        
        // called on main thread, to open the GDTResource
        virtual void loadResource() = 0;   //maybe do this on constructor instead
        
        // called on worker thread, to read data, and decompress textures etc
        virtual void loadData() = 0;
        
        // called on main thread, return true if done, false if there is more data
        virtual bool uploadToGL() = 0;
        
        
        
        
        virtual ~AsyncResource() = 0;
        
    };
    
    
    
    
}















#endif