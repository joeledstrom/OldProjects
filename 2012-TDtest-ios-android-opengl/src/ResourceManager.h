#ifndef TD_RESOURCE_MANAGER_H
#define TD_RESOURCE_MANAGER_H

#include "GLResources.h"

#include <vector>
#include <tr1/unordered_map>
#include <tr1/memory>






class Texture {
    friend class ResourceManager;
    
    shared_ptr<GLTexture> texture; 
    Texture(shared_ptr<GLTexture> texture) : texture(texture) {}
public:
    void bind() {
        texture->bind();
    }
    
    void bind(GLenum target) {
        texture->bind(target);
    }
};


class Program {
    friend class ResourceManager;
    
    shared_ptr<GLProgram> program; 
    Program(shared_ptr<GLProgram> program) : program(program) {}
    
public:
    void use() {
        glUseProgram(program->program);
    }
    GLuint getUniformLocation(string_t name) {
        return glGetUniformLocation(program->program, name);
    }
    GLuint getAttribLocation(string_t name) {
        return glGetAttribLocation(program->program, name);
    }
};


class ResourceManager {
	DISALLOW_COPY_AND_ASSIGN(ResourceManager);

    unordered_map<string, weak_ptr<GLProgram> > loadedPrograms; 
    unordered_map<string, weak_ptr<GLTexture> > loadedTextures;
    
public:
	ResourceManager() {}
    Program loadProgram(vector<string> vsPaths, vector<string> fsPaths);
    Program loadProgram(string vsPath, string fsPath);
    // Model loadModel(string modelPath);
    Texture loadTexture(string path, bool filter, bool repeat);
	~ResourceManager() {
		for (unordered_map<string, weak_ptr<GLTexture> >::iterator it = loadedTextures.begin();
			 it != loadedTextures.end();
			 it++) {
			
			shared_ptr<GLTexture> tex = it->second.lock();
			
			if (tex) {
				tex->valid = false;
			}
			
		}
	}
};




#endif
