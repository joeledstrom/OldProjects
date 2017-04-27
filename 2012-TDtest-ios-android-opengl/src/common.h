#ifndef TD_COMMON_H
#define TD_COMMON_H

#include <stdexcept>
#include <vector>
#include <string>
#include <tr1/unordered_map>
#include <tr1/memory>


#include <gdt/gdt.h>
#include <gdt/gdt_gles2.h>

#include <cml/cml.h>

using namespace std;
using namespace std::tr1;


typedef cml::matrix44f_c mat4;
typedef cml::matrix33f_c mat3;
typedef cml::vector3f vec3;
typedef cml::quaternionf_p quat;




#ifdef DEBUG
    #define assert(e) __builtin_expect(!(e), 0) ? gdt_fatal("assertion", "%s:%u: Assertion failed in: %s [%s == false, should be true]",__FILE__, __LINE__ ,__PRETTY_FUNCTION__, #e) : ((void)0)
#else
    #define assert(e)	((void)0)
#endif

#ifdef DEBUG
struct LoggingStream {
    shared_ptr<stringstream> ss;
    
    struct FlushTag {};
    
    static FlushTag flush;

    LoggingStream& operator <<(FlushTag) {
        if (ss) {
            log();
            ss.reset();
        }
        return *this;
    }

    template <typename T>
    LoggingStream& operator <<(const T& t) {
        if (!ss) {
            ss = shared_ptr<stringstream>(new stringstream);
            *ss << boolalpha;
        }
        *ss << t;

        return *this;
    }

    ~LoggingStream() {
        if (ss)
            log();
    }
    
private:
    void log() {
        gdt_log(LOG_NORMAL, "TDtest", "%s", ss->str().c_str());
    }
    
};
#else
struct LoggingStream {
    static int flush;
    template <typename T>
    inline LoggingStream& operator <<(const T& t) {
                
        return *this;
    }
};
#endif


typedef LoggingStream logg; 



#define LOG(args...) gdt_log(LOG_NORMAL, TAG, args)
#define LOGT(tag, args...) gdt_log(LOG_NORMAL, tag, args)

#define DISALLOW_COPY_AND_ASSIGN(TypeName) \
TypeName(const TypeName&);               \
void operator=(const TypeName&)


class GDTResource {
    DISALLOW_COPY_AND_ASSIGN(GDTResource);
    resource_t resource;
public:
    GDTResource(string_t resourcePath) {
        
        resource = gdt_resource_load(resourcePath);
        if (!resource) {
            LOGT("GLResources", "Error loading: ", resourcePath);
            throw runtime_error("Error loading: " + string(resourcePath));
        }
    }
    
    void *getBytes() {
        return gdt_resource_bytes(resource); 
    }
    
    int32_t getLength() {
        return gdt_resource_length(resource);
    }
    
    ~GDTResource() {
        gdt_resource_unload(resource);
        
    }
};




#endif
