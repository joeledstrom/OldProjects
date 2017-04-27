#ifndef TD_GL_RESOURCES_H
#define TD_GL_RESOURCES_H



#include "gdt/gdt.h"
#include "gdt/gdt_gles2.h"


#include "common.h"

#include <string>
#include <vector>
#include <stdexcept>

class ResourceManager;

class GLResource {
	friend class ResourceManager;
	bool valid;
protected:
	GLResource() : valid(true) {}
};



class GLTexture : public GLResource {
    DISALLOW_COPY_AND_ASSIGN(GLTexture);
    GLuint tex;
    
public:
    explicit GLTexture() {
        glGenTextures(1, &tex);
		LOGT("GLResources", "Texture generated: %d", tex);

    }
    
    void bind() {
        bind(GL_TEXTURE_2D);
    }
    
    void bind(GLenum target) {
        glBindTexture(target, tex);
    }

    ~GLTexture() {
		LOGT("GLResources", "Texture deleted; %d", tex);
        glDeleteTextures(1, &tex);
    }
};



class GLBuffer {
    DISALLOW_COPY_AND_ASSIGN(GLBuffer);
    GLuint buf;
    GLenum target;
    GLenum usage;
public:
    template <class T>
    explicit GLBuffer(vector<T>& v, GLenum target, GLenum usage) : target(target), usage(usage) {
        glGenBuffers(1, &buf);
        glBindBuffer(target, buf);
        glBufferData(target, v.size()*sizeof(T), &v[0], usage);
		LOGT("GLResources", "GLBuffer generated: %d", buf);
    }
    
    void bind() {
        glBindBuffer(target, buf);
    }
    
    ~GLBuffer() {
        glDeleteBuffers(1, &buf);
		LOGT("GLResources", "GLBuffer deleted: %d", buf);
    }
};




class GLProgram {
    DISALLOW_COPY_AND_ASSIGN(GLProgram);
    
public:
    GLuint program;
    explicit GLProgram(vector<string> vsPaths, vector<string> fsPaths);
    ~GLProgram();
    
    GLuint getUniformLocation(string_t name) {
        return glGetUniformLocation(program, name);
    }
    GLuint getAttribLocation(string_t name) {
        return glGetAttribLocation(program, name);
    }
};


#endif
