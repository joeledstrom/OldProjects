//
//  MD5Model.h
//  TDtest
//
//  Created by Joel Edström on 1/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef TD_MD5MODEL_H
#define TD_MD5MODEL_H

#include "common.h"
#include "MD5.h"
#include "GLResources.h"

#include <set>
#include <map>

class MD5Model {
	DISALLOW_COPY_AND_ASSIGN(MD5Model);
	
public:
	class AnimationState {
		friend class MD5Model;
		int32_t animationIndex;
	public:
		AnimationState(int32_t animationIndex) 
		: animationIndex(animationIndex) {}
		float blendWeight;
		float currentFrame;
	};
	
	class Instance {
		friend class MD5Model;
        vector<mat4> skeletonPose;
	public:
		mat4 modelMatrix;
		vector<AnimationState> animationStates;
	};

	
	MD5Model(const shared_ptr<MD5Mesh>& mesh);
	void attachAnimation(const shared_ptr<MD5Anim>& anim);
	shared_ptr<MD5Model::Instance> createInstance();
	void update();
	void render(const mat4& viewMat, const mat4& projMat);
	void prepareBuffers();
	
private:
    
    struct SubMeshBuffers {
        shared_ptr<GLBuffer> indexBuffer;
        shared_ptr<GLBuffer> positionBuffer;
        shared_ptr<GLBuffer> normalBuffer;
        shared_ptr<GLBuffer> texCoordBuffer;
        shared_ptr<GLBuffer> jointWeightBuffer;
        shared_ptr<GLBuffer> jointIndexBuffer;
        
    };
    
    vector<SubMeshBuffers> submeshBuffers;
    shared_ptr<GLProgram> program;
    
	shared_ptr<MD5Mesh> mesh;
	vector<shared_ptr<MD5Anim> > animations;
	set<weak_ptr<MD5Model::Instance> > instances;
	
	bool matchesMesh(const MD5Anim& anim) const;
	
	void blendFrames(vector<MD5AnimJoint>& output, const AnimationState& state);
    void updatePose(vector<mat4>& pose, const vector<MD5AnimJoint>& skel);
    
    //MD5KeyFramedModel generateKeyFramedModel(const vector<>& keyframes)
};

#endif
