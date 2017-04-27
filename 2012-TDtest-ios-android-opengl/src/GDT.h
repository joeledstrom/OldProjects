#ifndef TD_GDT_H
#define TD_GDT_H


#define DISALLOW_COPY_AND_ASSIGN(TypeName) \
TypeName(const TypeName&);               \
void operator=(const TypeName&)

#include <stdint.h>
#include <stdexcept>
#include <string>

struct resource;
typedef struct resource* resource_t;


namespace gdt {

    typedef enum {
        TOUCH_DOWN,
        TOUCH_UP,
        TOUCH_MOVE
    } touch_type_t;
    
    struct GDTException : public std::runtime_error {
        explicit GDTException(const std::string& what) 
        : std::runtime_error(what) {}
    };
    
    class Application {
        
    public:
        virtual void onInit() {}
        
        virtual void onVisible(bool newContext) {}
        
        virtual void onTouch(touch_type_t what, int screenX, int screenY) {}
        
        virtual void onRender() {}
        
        virtual void onActive() {}
        
        virtual void onInactive() {}
        
        virtual void onSaveState() {}
        
        virtual void onHidden() {}
        
        
        virtual ~Application() {}
    };
    
    
    // NOTE: needs to be created on the gdt thread
    class Resource {
        DISALLOW_COPY_AND_ASSIGN(Resource);
        resource_t resource;
    public:
        Resource(char* resourcePath);
        void *getBytes();
        int32_t getLength();
        ~Resource();    
    };
    
    uint64_t getTime();
}



#endif