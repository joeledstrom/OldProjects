#include "GDT.h"

#include <string>

#include <gdt/gdt.h>

namespace gdt {
    Resource::Resource(char* resourcePath) {
        
        resource = gdt_resource_load(resourcePath);
        if (!resource) {
            throw GDTException("Error loading: " + std::string(resourcePath));
        }
    }
    

    void* Resource::getBytes() {
        return gdt_resource_bytes(resource); 
    }
    
    int32_t Resource::getLength() {
        return gdt_resource_length(resource);
    }
    
    Resource::~Resource() {
        gdt_resource_unload(resource);
    }
    
    uint64_t getTime() {
        return gdt_time_ns(); 
    }
}