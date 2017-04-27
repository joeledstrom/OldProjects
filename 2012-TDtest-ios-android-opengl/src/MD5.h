#ifndef TD_MD5_H
#define TD_MD5_H
#include "common.h"


class MD5Triangle {
public:
	u_int32_t vertexIndices[3];
	MD5Triangle(const u_int32_t index0, const u_int32_t index1, const u_int32_t index2) {
		vertexIndices[0] = index0;
		vertexIndices[1] = index1;
		vertexIndices[2] = index2;
	}
};



class MD5Joint {
public:
	string name;
	int32_t parentIndex;
	
	// in Object space
	vec3 position;
	// in Joint space
	quat orientation;
	
    mat4 inverseBindPose;
};




struct MD5Vertex {
    vec3 position;
    vec3 normal;
    float textureCordinateS;
	float textureCordinateT;
    u_int8_t jointIndex[4];
    float jointWeight[4];
    
};


struct MD5SubMesh {
    string shader;
    vector<MD5Triangle> triangles;
    vector<MD5Vertex> vertices;
};


// Maps to a full md5mesh file.
class MD5Mesh {
	MD5Mesh() {}
public:
	static shared_ptr<MD5Mesh> loadMesh(const void* data, const int32_t length);
	
	unordered_map<string, string> properties;
	vector<MD5Joint> joints;
	vector<MD5SubMesh> meshes;
};





struct MD5AnimJoint {
	MD5AnimJoint() : position(0, 0, 0), orientation(0, 0, 0, 0) {}	
	// in "Parent Joint" space
	vec3 position;
	// in Joint space
	quat orientation;
};

struct MD5Frame {
	vec3 minBound;
	vec3 maxBound;
	vector<MD5AnimJoint> joints;
};

struct MD5JointInfo {
	string name;
	int32_t parentIndex;
	int32_t flags;
	int32_t startIndex;
};

// Maps to a full md5anim file.
class MD5Anim {
	MD5Anim() {}
public:
	static shared_ptr<MD5Anim> parseAnim(const void* data, const int32_t length);
	
	unordered_map<string, string> properties;
	vector<MD5JointInfo> jointInfos; 
	vector<MD5Frame> frames;
	
};


#endif
