//
//  MD5Model.cpp
//  TDtest
//
//  Created by Joel Edström on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include "MD5Model.h"




bool MD5Model::matchesMesh(const MD5Anim& anim) const {
    
    if (mesh->joints.size() != anim.frames.at(0).joints.size())
        return false;
    
    if (mesh->joints.size() != anim.jointInfos.size())
        return false;
    
    for (int i = 0; i < mesh->joints.size(); i++) {
        const MD5Joint& joint = mesh->joints.at(i);
        const MD5JointInfo& info = anim.jointInfos.at(i);
        if (joint.name != info.name ||
            joint.parentIndex != info.parentIndex)
        {
            return false;
        }
    }
    
    
    return true;
}


MD5Model::MD5Model(const shared_ptr<MD5Mesh>& mesh) : mesh(mesh) {
    
        
}


void MD5Model::attachAnimation(const shared_ptr<MD5Anim>& anim) {
    if (matchesMesh(*anim)) {
        animations.push_back(anim);
    } else {
        stringstream e; 
        e << "md5anim to be inserted at index: " << animations.size();
        e << " failed to match md5mesh";
        throw runtime_error(e.str());
    }
}

shared_ptr<MD5Model::Instance> MD5Model::createInstance() {
    shared_ptr<MD5Model::Instance> newInstance(new MD5Model::Instance);
    
    instances.insert(weak_ptr<MD5Model::Instance>(newInstance));
    
    return newInstance;
}


void MD5Model::blendFrames(vector<MD5AnimJoint>& output, const AnimationState& state) {
    
    
    MD5Anim& anim = *animations.at(state.animationIndex);
    
    int f0 = int(state.currentFrame) % anim.frames.size();
    int f1 = (int(state.currentFrame)+1) % anim.frames.size();
    
    float delta = state.currentFrame - f0;
    
    MD5Frame& frame0 = anim.frames[f0];
    MD5Frame& frame1 = anim.frames[f1];
    
    vector<MD5AnimJoint>& skel0 = frame0.joints;
    vector<MD5AnimJoint>& skel1 = frame1.joints;
    
    // blend between two frames
    for (int i = 0; i < skel0.size(); i++) {
        vec3 v = cml::lerp(skel0[i].position, skel1[i].position, delta);
        
        
        quat o = cml::slerp(skel0[i].orientation, skel1[i].orientation, delta);
        
        output[i].position += state.blendWeight * v;
        output[i].orientation += state.blendWeight * o;
    }
}

void MD5Model::updatePose(vector<mat4>& pose, const vector<MD5AnimJoint>& skel) {
    pose.clear();
    for (int i = 0; i < skel.size(); i++) {
        const MD5AnimJoint& joint = skel[i];
        
        mat4 pos, orient;
        cml::matrix_translation(pos, joint.position);
        cml::matrix_rotation_quaternion(orient, joint.orientation);
        
        pose.push_back((pos * orient) * mesh->joints[i].inverseBindPose);
    }    
}

void MD5Model::update() {
    for (set<weak_ptr<MD5Model::Instance> >::iterator it = instances.begin();
         it != instances.end();) 
    {
        shared_ptr<MD5Model::Instance> instance = (*it).lock();
        if (instance) {
            
            vector<MD5AnimJoint> skeleton(mesh->joints.size());
            for (int i = 0; i < mesh->joints.size(); i++) {
                skeleton[i].position = vec3(0,0,0);
                skeleton[i].orientation = quat(0,0,0,0);
            }
            
            
            // blend between all animations
            for (int i = 0; i < instance->animationStates.size(); i++) {
                
                AnimationState& state = instance->animationStates[i];
                
                // blend between two frames, and scale with state.blendWeight
                blendFrames(skeleton, state);
            }
            
            for (int i = 0; i < skeleton.size(); i++) {
                skeleton[i].orientation.normalize();   // not sure if necessary
            }
            
            updatePose(instance->skeletonPose, skeleton);
            
            
            
            
            
            ++it;
        } else {
            // remove lingering instances
            instances.erase(it++);
        }
    }
}

template <typename T>
static shared_ptr<GLBuffer> createBuffer(vector<T>& data) {
    return shared_ptr<GLBuffer>(new GLBuffer(data, GL_ARRAY_BUFFER, GL_STATIC_DRAW));
}

void MD5Model::prepareBuffers() {
    
    submeshBuffers.clear();
    
    const bool hasAnimations = animations.size() > 0;
    
    
    
    for (int i = 0; i < mesh->meshes.size(); i++) {
        const MD5SubMesh& m = mesh->meshes[i];
        vector<float> pos;
        vector<float> normal;
        vector<u_int16_t> index;
        vector<float> texCoord;
        vector<float> jointWeight;
        vector<unsigned char> jointIndex;
        
        for (int j = 0; j < m.vertices.size(); j++) {
            const MD5Vertex& v = m.vertices[j];
            pos.push_back(v.position[0]);
            pos.push_back(v.position[1]);
            pos.push_back(v.position[2]);
            
            normal.push_back(v.normal[0]);
            normal.push_back(v.normal[1]);
            normal.push_back(v.normal[2]);
            
            texCoord.push_back(v.textureCordinateS);
            texCoord.push_back(v.textureCordinateT);
            
            
            if (hasAnimations) {
                jointWeight.push_back(v.jointWeight[0]);
                jointWeight.push_back(v.jointWeight[1]);
                jointWeight.push_back(v.jointWeight[2]);
                jointWeight.push_back(v.jointWeight[3]);
            
                jointIndex.push_back(v.jointIndex[0]);
                jointIndex.push_back(v.jointIndex[1]);
                jointIndex.push_back(v.jointIndex[2]);
                jointIndex.push_back(v.jointIndex[3]);
            }
            
        }
        
        for (int j = 0; j < m.triangles.size(); j++) {
            const MD5Triangle& t = m.triangles[j];
            index.push_back(t.vertexIndices[0]);
            index.push_back(t.vertexIndices[1]);
            index.push_back(t.vertexIndices[2]);
        }
        
        submeshBuffers.push_back(SubMeshBuffers());
        SubMeshBuffers& buffers = submeshBuffers.back();
        
        buffers.indexBuffer = shared_ptr<GLBuffer>(new GLBuffer(index, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW));
        buffers.positionBuffer = createBuffer(pos);
        buffers.normalBuffer = createBuffer(normal);
        buffers.texCoordBuffer = createBuffer(texCoord);
        
        if (hasAnimations) {
            buffers.jointWeightBuffer = createBuffer(jointWeight);
            buffers.jointIndexBuffer = createBuffer(jointIndex);
        }
        
    }
    
    
    const string vs = hasAnimations ? "/data/md5.vshader.jet" : "/data/md5-noanim.vshader.jet";
    
    vector<string> vsPaths(1, vs);
    vector<string> fsPaths(1, "/data/md5.fshader.jet");
    
    program = shared_ptr<GLProgram>(new GLProgram(vsPaths, fsPaths));                            
}

void MD5Model::render(const mat4& viewMat, const mat4& projMat) {
    
    // set global uniforms: projMat, viewMat, lightPos etc
    // bind shader
    //
    // foreach submesh
    //     bind buffers
    //     bind texture
    //     (optonal: set material uniforms)
    //     foreach instance
    //         set bone matrix uniforms
    //         set modelMat
    //         render
    
    const bool hasAnimations = animations.size() > 0;
    
    
    glUseProgram(program->program);

    
    
     // NOTE. some of these will return -1 if !hasAnimations, but they will also be unused then
    
    GLuint positionAttrib = program->getAttribLocation("position");
    GLuint normalAttrib = program->getAttribLocation("normal");
    GLuint texCoordAttrib = program->getAttribLocation("texCoord");
    GLuint jointIndexAttrib = program->getAttribLocation("jointIndex");
    GLuint jointWeightAttrib = program->getAttribLocation("jointWeight");
    

    GLuint mMatrixUniform = program->getUniformLocation("mMatrix");
    GLuint vMatrixUniform = program->getUniformLocation("vMatrix");
    GLuint pMatrixUniform = program->getUniformLocation("pMatrix");
    GLuint jointsUniform = program->getUniformLocation("joints");
    
    
    

    glUniformMatrix4fv(pMatrixUniform, 1, GL_FALSE, projMat.data());
    glUniformMatrix4fv(vMatrixUniform, 1, GL_FALSE, viewMat.data());
    

    
    for (int i = 0; i < submeshBuffers.size(); i++) {
        SubMeshBuffers& buffers = submeshBuffers[i];
        
        
        buffers.positionBuffer->bind();
        glEnableVertexAttribArray(positionAttrib);
        glVertexAttribPointer(positionAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);
    
        buffers.normalBuffer->bind();
        glEnableVertexAttribArray(normalAttrib);
        glVertexAttribPointer(normalAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);
        
        buffers.texCoordBuffer->bind();
        glEnableVertexAttribArray(texCoordAttrib);
        glVertexAttribPointer(texCoordAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);
        
        
        if (hasAnimations) {
            buffers.jointIndexBuffer->bind();
            glEnableVertexAttribArray(jointIndexAttrib);
            glVertexAttribPointer(jointIndexAttrib, 4, GL_UNSIGNED_BYTE, GL_FALSE, 0, 0);

            buffers.jointWeightBuffer->bind();
            glEnableVertexAttribArray(jointWeightAttrib);
            glVertexAttribPointer(jointWeightAttrib, 4, GL_FLOAT, GL_FALSE, 0, 0);
        }
        
    
        buffers.indexBuffer->bind();
    
        // TODO IMPORTANT: implement z sorting using viewMat, 
        // and the per instance modelMatrix (on non PowerVR hw)
        
        for (set<weak_ptr<MD5Model::Instance> >::iterator it = instances.begin();
             it != instances.end(); 
             ++it) {
    
            shared_ptr<MD5Model::Instance> instance = (*it).lock();
            
            if (instance) {
                glUniformMatrix4fv(mMatrixUniform, 1, GL_FALSE, instance->modelMatrix.data());

                if (hasAnimations) {
                    glUniformMatrix4fv(jointsUniform, instance->skeletonPose.size(), GL_FALSE, instance->skeletonPose[0].data());
                }
                
                glDrawElements(GL_TRIANGLES, mesh->meshes.at(i).triangles.size() * 3, GL_UNSIGNED_SHORT, 0);

            }
        }
        
        glDisableVertexAttribArray(texCoordAttrib);
        glDisableVertexAttribArray(normalAttrib);
        glDisableVertexAttribArray(positionAttrib);
        
        if (hasAnimations) {
            glDisableVertexAttribArray(jointWeightAttrib);
            glDisableVertexAttribArray(jointIndexAttrib);
        }
        
    }
    
}

