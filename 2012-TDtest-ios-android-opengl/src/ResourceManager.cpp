#include "ResourceManager.h"
//#include "common.h"



#define TAG "ResourceManager"


using namespace std;
using namespace tr1;


#include <webp/decode.h>

 
 
 
 
class WebpImage {
    DISALLOW_COPY_AND_ASSIGN(WebpImage);
    uint8_t* imgData;
    int width, height;
public:
    explicit WebpImage(GDTResource& r) {
        imgData = WebPDecodeRGBA((uint8_t*)r.getBytes(), r.getLength(), &width, &height);
        
        if (!imgData) {
            throw runtime_error("Error opening file");
        }
    }
    
    WebpImage() {
        free(imgData);
    }
    
    int getWidth() {
        return width;;
    }
    
    int getHeight() {
        return height;
    }
    
    unsigned char* getData() {
        return imgData;
    }
};





static string boolToString(bool b) {
    return b ? "true" : "false";
}


Texture ResourceManager::loadTexture(string path, bool filter, bool repeat) {
    
    
    string key = path + boolToString(filter) + boolToString(repeat);
    
    shared_ptr<GLTexture> tex;
    
    if (loadedTextures.count(key) > 0) {
        tex = loadedTextures[key].lock();
    }
    
    if (!tex) {
        tex = shared_ptr<GLTexture>(new GLTexture());
        
        tex->bind();
        

        if (filter) {
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        } else {
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        }
        
        if (repeat) {
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
        } else {
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }

        string ext = path.substr(path.find_last_of('.') + 1);
        
        if (ext == "webp") {
            LOG("Loading texture: %s", path.c_str());
            GDTResource r(path.c_str());
            WebpImage img(r);

            
            LOG("Texture: w: %d h: %d", img.getWidth(), img.getHeight());
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, img.getWidth(), img.getHeight(), 0, GL_RGBA, GL_UNSIGNED_BYTE, img.getData());
            
            if (filter) {
                glGenerateMipmap(GL_TEXTURE_2D);
            }
            
        } else {
            throw runtime_error("Image format: " + ext + " unsupported");
        }
        
        
        
        loadedTextures[key] = weak_ptr<GLTexture>(tex);
    }
    
    return Texture(tex);
}


Program ResourceManager::loadProgram(vector<string> vsPaths, vector<string> fsPaths) {
        
    string key = "";
    
    for (int i = 0; i < vsPaths.size(); i++) {
        key += vsPaths[i];
    }
    for (int i = 0; i < fsPaths.size(); i++) {
        key += fsPaths[i];
    }
    
    shared_ptr<GLProgram> program;
    
    if (loadedPrograms.count(key) > 0) {
        program = loadedPrograms[key].lock();
    }
    
    if (!program) {
        program = shared_ptr<GLProgram>(new GLProgram(vsPaths, fsPaths));
        
        loadedPrograms[key] = weak_ptr<GLProgram>(program);
        
    }
    
    return Program(program);
}

Program ResourceManager::loadProgram(string vsPath, string fsPath) {
    vector<string> vsPaths(1, vsPath);
    vector<string> fsPaths(1, fsPath);
    
    return loadProgram(vsPaths, fsPaths);
}
