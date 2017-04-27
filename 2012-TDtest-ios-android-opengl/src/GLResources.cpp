#include "GLResources.h"


using namespace std;

#define TAG "GLResources"



static string getShaderLog(GLuint shader) {
    GLint infologLength = 0;
    
    int charsWritten = 0;
    char *infoLog;
    
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infologLength);
    
    if (infologLength > 0) {
        infoLog = (char *)malloc(infologLength);
        glGetShaderInfoLog(shader, infologLength, &charsWritten, infoLog);
        
        string log = infoLog;
        
        free(infoLog);
        
        return log;
    }
    
    return "<empty>";
}

static GLuint compileShader(string_t shaderCode, GLenum type, int len) {
	GLuint shader = glCreateShader(type);
    
	glShaderSource(shader, 1, &shaderCode, &len);
    
	glCompileShader(shader);
    
	GLint result;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &result);
	if (result == GL_FALSE) {
        gdt_log(LOG_NORMAL, TAG, getShaderLog(shader).c_str());
		throw runtime_error("Error compiling shader");
	}
        
	return shader;
}

static GLuint createProgram(vector<string> vsPaths, vector<string> fsPaths) {
    vector<GLuint> shaders;
    
    for (int i = 0; i < vsPaths.size(); i++) {
        GDTResource r(vsPaths[i].c_str());
        shaders.push_back(compileShader((string_t)r.getBytes(), GL_VERTEX_SHADER, r.getLength()));
    }
    
    
    for (int i = 0; i < fsPaths.size(); i++) {
        GDTResource r(fsPaths[i].c_str());
        shaders.push_back(compileShader((string_t)r.getBytes(), GL_FRAGMENT_SHADER, r.getLength()));
    }
    
    GLuint program = glCreateProgram();
    
    for (int i = 0; i < shaders.size(); i++) {
        glAttachShader(program, shaders[i]);
        glDeleteShader(shaders[i]);
    }
    
    glLinkProgram(program);
    
    GLint result;
	glGetProgramiv(program, GL_LINK_STATUS, &result);
	if (result == GL_FALSE) {
		throw runtime_error("Error linking program");
	}
    
    return program;
}



GLProgram::GLProgram(vector<string> vsPaths, vector<string> fsPaths) 
    : program(createProgram(vsPaths, fsPaths))
{}

GLProgram::~GLProgram() {
    glDeleteProgram(program);
}
