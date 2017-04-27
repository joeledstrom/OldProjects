//
//  Game.h
//  TDtest
//
//  Created by Joel Edström on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef TDtest_Game_h
#define TDtest_Game_h

#include "common.h"


#include "GDT.h"

#include "ResourceManager.h"
#include "MD5Model.h"


class Game : public gdt::Application {
public:
    
    
    float lastX;
    float lastY;
    bool drag;
    int _width;
    int _height;
    
    
    
    void onTouch(gdt::touch_type_t what, int screenX, int screenY) {
        float x = 2 * screenX / (float) _width  - 1;
        float y = 2 * screenY / (float) _height - 1;
        
        
        
        
        if (drag) {
            switch (what) {
                case TOUCH_MOVE:
                {
                    float deltaX = x - lastX;
                    float deltaY = y - lastY;
                    rotate(deltaX, deltaY);
                    
                }
                    break;
                case TOUCH_UP:
                    drag = false;
                    break;
                default: {}
            }
        } else {
            switch (what) {
                case TOUCH_DOWN:
                    drag = true;
                    break;
                default: {}
            }
        }
        lastX = x;
        lastY = y;

    }
    
    void onVisible(bool newContext) {
        logg() << "onVisible, newContext == " << (newContext ? "true": "false");
        
        if (newContext) {
            
            
            if (obj)
                delete obj;
            
            ResourceManager rm;
            _width = gdt_surface_width();
            _height = gdt_surface_height();
            
            //LOG("Viewport size (width: %d, height: %d)", _width, _height);
            
            Texture tex = rm.loadTexture("/data/linen.webp", true, true);
            
            
            obj = new GameObject(tex);
            
            
            glBindTexture(GL_TEXTURE_2D, 0);
            
            glDisable(GL_CULL_FACE);
            glCullFace(GL_FRONT);
            glEnable(GL_DEPTH_TEST);
            
            glClearColor(0.0, 0.0, 0.0, 1);
            
            glViewport(0, 0, _width, _height);
            
            
            GLint depthBufferBits;
            glGetIntegerv( GL_DEPTH_BITS, &depthBufferBits );
            logg() << "Depth buffer bits: " << depthBufferBits;
            logg() << "glGetError: " << glGetError() << logg::flush;
            
            LoggingStream() << "kaka";
            
            
            
            GDTResource res("/data/boblampclean.md5mesh.jet");
            shared_ptr<MD5Mesh> mesh = MD5Mesh::loadMesh(res.getBytes(), res.getLength());
            
            
            GDTResource res2("/data/boblampclean.md5anim.jet");
            shared_ptr<MD5Anim> anim = MD5Anim::parseAnim(res2.getBytes(), res2.getLength());
            
            
            shared_ptr<MD5Model> model(new MD5Model(mesh));
            model->attachAnimation(anim);
            model->attachAnimation(anim);
            
            
            for (int i = 0 ; i < 30; i++) {
                shared_ptr<MD5Model::Instance> instance = model->createInstance();
                
                
                instance->animationStates.push_back(MD5Model::AnimationState(0));
                instance->animationStates[0].blendWeight = 1.0;
                instance->animationStates[0].currentFrame = 3.4 + i * 12.3;
                
                
                mat4 trans, scale, rot;
                cml::matrix_translation(trans, 0.0f, 0.0f, -30.0f);
                cml::matrix_rotation_world_x(rot, -3.14159f/2);
                cml::matrix_scale(scale, 0.2f, 0.2f, 0.2f);
                
                mat4 adjustModelMat = scale * rot * trans;
                
                
                mat4 moveSideways;
                
                cml::matrix_translation(moveSideways, -25.0f + i*5.0f , 0.0f, 0.0f);
                
                
                instance->modelMatrix = moveSideways * adjustModelMat;
                
                obj->instances.push_back(instance);
            }
            
            
            GDTResource res3("/data/egg.md5mesh.jet");
            shared_ptr<MD5Mesh> mesh2 = MD5Mesh::loadMesh(res3.getBytes(), res3.getLength());
            
            model.reset(new MD5Model(mesh2));
            
            //model->update();
            model->prepareBuffers();
            
            obj->model = model;
            
            shared_ptr<MD5Model::Instance> instance = model->createInstance();
            mat4 scale;
            cml::matrix_scale(scale, 3.0f, 3.0f, 3.0f);
            instance->modelMatrix = scale;
            obj->instances.push_back(instance);
            
        }
        
        lastTime = gdt_time_ns();

    }
    
    u_int64_t lastTime;
    
    class GameObject {
    public:
        Texture tex;
        shared_ptr<GLBuffer> vt;
        shared_ptr<GLBuffer> n;
        shared_ptr<GLBuffer> tc;
        shared_ptr<MD5Model> model;
        vector<shared_ptr<MD5Model::Instance> > instances;
        GameObject(Texture tex) 
        : tex(tex) {}
    };
    
    GameObject *obj = NULL; 
    
    quat rot = quat().identity();
    
    void rotate(float dx, float dy) {
        quat xRot(cos(-dy), sin(-dy) * vec3(1,0,0));
        quat yRot(cos(dx), sin(dx) * vec3(0,1,0));
        
        //quaternion_rotate_about_world_y(rot, dx*2.0f);
        //quaternion_rotate_about_world_x(rot, -dy*2.0f);
        
        rot = xRot * yRot * rot;
        
        
    }
    
    
    int frameCounter = 0;
    double timeCounter = 0.0f;
    
    void onRender() {
        u_int64_t timeNS = gdt::getTime();
        double dt = double(timeNS-lastTime)/(1000*1000*1000);
        
        lastTime = timeNS;
        
        frameCounter++;
        
        timeCounter += dt;
        
        if (timeCounter > 5) {
            
            assert(timeCounter < 5);
            
            logg() << "avg FPS: " << double(frameCounter)/timeCounter;
            
            
            timeCounter = 0;
            frameCounter = 0;
        }
        
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        
        
        
        mat4 pMatrix;
        matrix_perspective_xfov_RH(pMatrix, cml::rad(45.0f), (float)_width/_height, 1.0f, 128.0f,  cml::z_clip_neg_one);
        
        
        mat4 t2;
        matrix_translation(t2, 0.0f, 0.0f, -20.0f);
        
        mat4 r;
        matrix_rotation_quaternion(r, rot);
        
        /*
         for (int i = 0; i < obj->instances.size(); i++) {
         
         float& animTime = obj->instances[i]->animationStates[0].currentFrame;
         animTime += 30 * dt;
         if (animTime > 139) {
         animTime = animTime-139;
         }
         }
         */
        
        obj->tex.bind();
        
        
        obj->model->update();
        
        obj->model->render(t2 * r, pMatrix);
    }
    
    void onActive() {
        logg() << "onActive";
    }
    
    void onInactive() {
        logg() << "onInactive";
    }
    
    void onSaveState() {
        logg() << "onSaveState";
    }
    
    void onHidden() {
        logg() << "onHidden";
    }
};



#endif
