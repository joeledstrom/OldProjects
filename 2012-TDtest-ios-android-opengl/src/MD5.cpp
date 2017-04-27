#include "MD5.h"

#include <iostream>
#include <tr1/tuple>

#define TAG "MD5"

struct InternalVertex {
	float textureCordinateS;
	float textureCordinateT;
	int32_t weightStartIndex;
	int32_t weightCount;
	
};

struct InternalWeight {
	u_int8_t jointIndex;
	float bias;
	
	// in Joint space
	vec3 position;
};

struct InternalWeightComparator {
    bool operator() (const InternalWeight& left, const InternalWeight& right) {
        return left.bias > right.bias;
    }
} internalWeightComparator;


struct InternalSubMesh {
	string shader;
	vector<InternalVertex> vertices;
	vector<MD5Triangle> triangles;
	vector<InternalWeight> weights;
};



enum SearchMode {
	SECTION,
	JOINTS,
	MESH,
	HIERARCHY,
	BOUNDS,
	BASEFRAME,
	FRAME
};


static bool getLine(string& line, const char** iter, const char* endIter) {
	
	
	do {
		line = "";
		
		int32_t slashCounter = 0;
		
		while (*iter < endIter) {
			
			char c = **iter;
			(*iter)++;
			
			if (slashCounter == 2) {
				line = line.substr(0, line.length()-2);  // remove slashes from output
				slashCounter++;
			}
			
			
			
			if (c == '\n' || c == '\r') {
				const char *nextChar = (*iter);
				
				if (nextChar < endIter && 
					((*nextChar == '\n' && c == '\r') ||
					 (*nextChar == '\r' && c == '\n'))) 
				{
					(*iter)++; // skip second CR or LF
					break;
				} else
					break;
			} else if (c == '/') {
				slashCounter++;
			} else {
				if (slashCounter > 2) {
					continue;
				}
				if (slashCounter == 1) {
					slashCounter = 0;
				}
			}
			
			line += c;
			
		}
	} while (*iter < endIter && line == "");
	return line.length() > 0;
}

static quat computeW(float x, float y, float z) {
	
	float t = 1.0f - (x * x) - (y * y) - (z * z);
	
	float w = t < 0.0f ? 0.0f : -sqrt(t);
	
	return quat (x, y, z, w);
}

static void generateFrameJoints(vector<MD5AnimJoint>& frameJoints,
								const vector<tuple<vec3, vec3> >& baseframe,
								const vector<float>& frameValues,
								const vector<MD5JointInfo>& jointInfos)
{
	for (size_t i = 0; i < baseframe.size(); i++) {
    
		MD5AnimJoint joint;

		
		// start with the baseframe
		joint.position = get<0>(baseframe[i]);
		vec3 &pos = joint.position;
		vec3 orientVec = get<1>(baseframe[i]);
		
		// replace with per frame animated components
		int flags = jointInfos[i].flags;
		int start = jointInfos[i].startIndex;
		int j = 0;
		
		if (flags & 1)
			pos[0] = frameValues[start+(j++)];
		if (flags & 2)
			pos[1] = frameValues[start+(j++)];
		if (flags & 4)
			pos[2] = frameValues[start+(j++)];
		if (flags & 8)
			orientVec[0] = frameValues[start+(j++)];
		if (flags & 16)
			orientVec[1] = frameValues[start+(j++)];
		if (flags & 32)
			orientVec[2] = frameValues[start+(j++)];
		
		

		joint.orientation = computeW(orientVec[0], orientVec[1], orientVec[2]);
		
        int parentId = jointInfos[i].parentIndex;
        //LOG("%d", parentId);
        if (parentId >= 0) {
            MD5AnimJoint& parent = frameJoints.at(parentId);
            
            mat4 orient;
            cml::matrix_rotation_quaternion(orient, parent.orientation);
            
            vec3 rotated = transform_vector(orient, joint.position);
            
            joint.position = parent.position + rotated; 
            
            joint.orientation = parent.orientation * joint.orientation;
        }
        
        joint.orientation.normalize();

		frameJoints.push_back(joint);
	}
}

static int stringToInt(const string& str) {
	int r;
	stringstream ss(str);
	ss >> r;
	
	return ss.fail() ? -1 : r;
}


static void parseMesh(MD5Mesh* mesh, vector<InternalSubMesh>& meshes, const char* iter, const char* endIter) {
    
    int32_t searchMode = SECTION;
		
	meshes.push_back(InternalSubMesh());
	
	int32_t vertCount = 0;
	int32_t triCount = 0;
	int32_t weightCount = 0;
	
	string line;
	while (getLine(line, &iter, endIter)) {
		
		
		if (searchMode == SECTION) {
			stringstream ss(line);
			
			string cmd;
			string value;
			
			ss >> cmd;
			ss >> value;
			
			bool valueExists = !ss.fail(); 
			
			if ((cmd == "joints" && value == "{") ||
				(cmd == "joints{" && !valueExists)) {
				searchMode = JOINTS;
			} else if ((cmd == "mesh" && value == "{") ||
					   (cmd == "mesh{" && !valueExists)) {
				searchMode = MESH;
                
			} else if (valueExists)
				mesh->properties[cmd] = value;
			
		} else if (searchMode == JOINTS) {
			replace(line.begin(), line.end(), '(', ' ');
			replace(line.begin(), line.end(), ')', ' ');  //TODO: Error: might turn name: "kaka(" into "kaka "
			
			
			stringstream ss(line);
			
			string name;
			
			ss >> name;
			
			if (name == "}") {
				searchMode = SECTION;
			} else {
				MD5Joint joint;
				float x,y,z;
				
				joint.name = name;
				ss >> joint.parentIndex;
				
				ss >> x >> y >> z;
				joint.position = vec3(x, y, z);
				
				ss >> x >> y >> z;
				joint.orientation = computeW(x, y, z);
				
				mesh->joints.push_back(joint);
			}
			
			if (ss.fail())
				throw runtime_error("Invalid md5mesh Joints data");
            
		} else if (searchMode == MESH) {
			replace(line.begin(), line.end(), '(', ' ');
			replace(line.begin(), line.end(), ')', ' ');
			
			bool failure = false;
            
			string cmd;			
			stringstream ss(line);
			ss >> cmd;
			
			InternalSubMesh &currentSubMesh = meshes.at(meshes.size()-1); // get the last one
			
			if (cmd == "}") {
				searchMode = SECTION;
				meshes.push_back(InternalSubMesh());
				vertCount = triCount = weightCount = 0;
			} else if (cmd == "shader") {
				string value;
				ss >> value;
				currentSubMesh.shader = value;
			} else if (cmd == "vert") {
				InternalVertex vert;
				
				int32_t num;
				ss >> num;
				if (num != vertCount)
					failure = true; // Possible TODO? allow unordered?
                
				ss >> vert.textureCordinateS >> vert.textureCordinateT;
				ss >> vert.weightStartIndex >> vert.weightCount;
				
				currentSubMesh.vertices.push_back(vert);
				vertCount++;
			} else if (cmd == "tri") {
				u_int32_t v1, v2, v3;
				
				int32_t num;
				ss >> num;
				if (num != triCount)
					failure = true; // Possible TODO? allow unordered?
				
				ss >> v1 >> v2 >> v3;
				
				currentSubMesh.triangles.push_back(MD5Triangle(v1, v2, v3));
				triCount++;
			} else if (cmd == "weight") {
				InternalWeight weight;
				float x, y, z;
				
				int32_t num;
				ss >> num;
				if (num != weightCount)
					failure = true; // Possible TODO? allow unordered?
				
                u_int32_t jointIndex;
				ss >> jointIndex >> weight.bias;
                weight.jointIndex = jointIndex;
				ss >> x >> y >> z;
				weight.position = vec3(x, y, z);
				
				currentSubMesh.weights.push_back(weight);
				weightCount++;
			}
			
			if (ss.fail() || failure)
				throw runtime_error("Invalid md5mesh Mesh data");
			
		}
        
		
	}
    
    

    if (meshes.size() < 2) {
        throw runtime_error("Invalid md5mesh Mesh data: 0 SubMeshes!");
    }
    // erase false submesh (due to weird parsing algoritm)
    meshes.erase(meshes.end()-1);
    
    
}




static void computeObjectSpaceVertexData(MD5Mesh& mesh, const vector<InternalSubMesh>& submeshes) {
    for (int i = 0; i < submeshes.size(); i++) {
        const InternalSubMesh& submesh = submeshes.at(i);
        
        mesh.meshes.push_back(MD5SubMesh());
        MD5SubMesh& newSubMesh = mesh.meshes.back();
        
        newSubMesh.triangles = submesh.triangles;
        newSubMesh.shader = submesh.shader;
        
        for (int v = 0; v < submesh.vertices.size(); v++) {
            const InternalVertex& vert = submesh.vertices.at(v);
            
            
            // grab the vertex weights
            vector<InternalWeight> vertexWeights;
            
            int weightEndIndex = vert.weightStartIndex + vert.weightCount;
            for (int w = vert.weightStartIndex; w < weightEndIndex; w++) {
                vertexWeights.push_back(submesh.weights.at(w));
            }
            
            // sort by weight bias
            sort(vertexWeights.begin(), vertexWeights.end(), internalWeightComparator);
            
            
            newSubMesh.vertices.push_back(MD5Vertex());
            MD5Vertex& newVertex = newSubMesh.vertices.back();
            
            newVertex.position = vec3(0,0,0);
            newVertex.normal = vec3(0,0,0);
            newVertex.textureCordinateS = vert.textureCordinateS;
            newVertex.textureCordinateT = vert.textureCordinateT;
            
            // set initial values to 0
            for (int g = 0; g < 4; g++) {
                newVertex.jointIndex[g] = 0;
                newVertex.jointWeight[g] = 0;
            }
            
            
            
            int gpuWeightCount = 0;
            
            for (int w = 0; w < vertexWeights.size(); w++) {
                
                const InternalWeight& weight = vertexWeights.at(w);
                const MD5Joint& joint = mesh.joints.at(weight.jointIndex);
                
                
                mat3 jointOrient;
                cml::matrix_rotation_quaternion(jointOrient, joint.orientation);
                
                vec3 rotated = transform_vector(jointOrient, weight.position);
                
                newVertex.position += weight.bias * (joint.position + rotated);
                
                
                
                // add the at most the biggest 4 weights
                if (gpuWeightCount < 4) {
                    newVertex.jointIndex[gpuWeightCount] = weight.jointIndex;
                    newVertex.jointWeight[gpuWeightCount] = weight.bias;
                    
                    gpuWeightCount++;
                }
            }
        }
    }
    
    
}

// NOTE. requires vertex normals set to (0,0,0) before calling
static void computeNormals(MD5Mesh& mesh) {
    
    
    for (int i = 0; i < mesh.meshes.size(); i++) {
        MD5SubMesh& submesh = mesh.meshes[i];
        
        
        for (int j = 0; j < submesh.triangles.size(); j++) {
            MD5Triangle& t = submesh.triangles[j];
            
            MD5Vertex& v0 = submesh.vertices.at(t.vertexIndices[0]);
            MD5Vertex& v1 = submesh.vertices.at(t.vertexIndices[1]);
            MD5Vertex& v2 = submesh.vertices.at(t.vertexIndices[2]);
            
            vec3 from0to1 = v1.position - v0.position;
            vec3 from0to2 = v2.position - v0.position;
            
            vec3 normal = cml::cross(from0to2, from0to1);
            normal.normalize();
            
            v0.normal += normal;
            v1.normal += normal;
            v2.normal += normal;
            
        }
        
        for (int j = 0; j < submesh.vertices.size(); j++) {
            submesh.vertices[j].normal.normalize();
        }
        
    }
}

static void computeInverseBindPose(MD5Mesh& mesh) {
    for (int i = 0; i < mesh.joints.size(); i++) {
        MD5Joint& joint = mesh.joints.at(i);
        
        mat4 pos, orient;
        cml::matrix_translation(pos, joint.position);
        cml::matrix_rotation_quaternion(orient, joint.orientation);
        
        joint.inverseBindPose = (pos * orient).inverse();
    }
}

shared_ptr<MD5Mesh> MD5Mesh::loadMesh(const void* data, const int32_t length) {
	const char* iter = (char*)data;
	const char* endIter = iter + length;
	
	
	shared_ptr<MD5Mesh> mesh(new MD5Mesh);
	
    
    vector<InternalSubMesh> submeshes;
    
	parseMesh(mesh.get(), submeshes, iter, endIter);    
    
    computeObjectSpaceVertexData(*mesh, submeshes);
    
    computeNormals(*mesh);
    
    computeInverseBindPose(*mesh);
	
	return mesh;
}

shared_ptr<MD5Anim> MD5Anim::parseAnim(const void* data, const int32_t length) {
	const char* iter = (char*)data;
	const char* endIter = iter + length;
	
 	int32_t searchMode = SECTION;
	
	shared_ptr<MD5Anim> anim(new MD5Anim);
	
	vector<tuple<vec3, vec3> > bounds;
	vector<tuple<vec3, vec3> > baseframe;
	
	int32_t currentFrame = -1;
	vector<float> currentFrameValues;
	
	string line;
	while (getLine(line, &iter, endIter)) {
		
		
		if (searchMode == SECTION) {
			stringstream ss(line);
			
			string cmd;
			string value;
			
			ss >> cmd;
			ss >> value;
			
			bool valueExists = !ss.fail(); 
			
			if ((cmd == "hierarchy" && value == "{") ||
				(cmd == "hierarchy{" && !valueExists)) {
				searchMode = HIERARCHY;
			} else if ((cmd == "bounds" && value == "{") ||
					   (cmd == "bounds{" && !valueExists)) {
				searchMode = BOUNDS;
			} else if ((cmd == "baseframe" && value == "{") ||
					   (cmd == "baseframe{" && !valueExists)) {
				searchMode = BASEFRAME;
			} else if (cmd == "frame" && valueExists) {
				stringstream valueStream(value);
				valueStream >> currentFrame;
				string brace;
				ss >> brace;
				if (!valueStream.fail() && brace == "{") {
					searchMode = FRAME;
				} else {
					throw runtime_error("Invalid md5anim Frame data");
				}
			} else if (valueExists)
				anim->properties[cmd] = value;
			
		} else if (searchMode == HIERARCHY) {
			stringstream ss(line);
			
			string name;
			
			ss >> name;
			
			if (name == "}") {
				searchMode = SECTION;
			} else {
				
				MD5JointInfo jointInfo;
				
				jointInfo.name = name;
				ss >> jointInfo.parentIndex;
				ss >> jointInfo.flags;
				ss >> jointInfo.startIndex;
				
				anim->jointInfos.push_back(jointInfo);
			}
			
			if (ss.fail())
				throw runtime_error("Invalid md5anim Hierarchy data");
		} else if (searchMode == BOUNDS) {
			replace(line.begin(), line.end(), '(', ' ');
			replace(line.begin(), line.end(), ')', ' ');
			
			stringstream ss(line);
			string cmd;
			ss >> cmd;
			
			if (cmd == "}") {
				searchMode = SECTION;
				anim->frames.resize(bounds.size());
			} else {
				ss.str(line);
				float x, y, z, x2, y2, z2;
			
				ss >> x >> y >> z;
				ss >> x2 >> y2 >> z2;
			
				bounds.push_back(make_tuple(vec3(x, y, z), vec3(x2, y2, z2)));
			}
			if (ss.fail())
				throw runtime_error("Invalid md5anim Bounds data");
			
		} else if (searchMode == BASEFRAME) {
			replace(line.begin(), line.end(), '(', ' ');
			replace(line.begin(), line.end(), ')', ' ');
			
			stringstream ss(line);
			
			string cmd;
			ss >> cmd;
			
			if (cmd == "}") {
				searchMode = SECTION;
			} else {
				ss.str(line);
				float x, y, z, x2, y2, z2;
				
				ss >> x >> y >> z;
				ss >> x2 >> y2 >> z2;
				
				baseframe.push_back(make_tuple(vec3(x, y, z), vec3(x2, y2, z2)));
			}
			if (ss.fail())
				throw runtime_error("Invalid md5anim Baseframe data");
			
		} else if (searchMode == FRAME) {
			
			stringstream ss(line);
			
			string cmd;
			ss >> cmd;
			
			if (cmd == "}") {
				searchMode = SECTION;
				
				MD5Frame &frame = anim->frames.at(currentFrame);
				frame.minBound = get<0>(bounds.at(currentFrame));
				frame.maxBound = get<1>(bounds.at(currentFrame));
				
				generateFrameJoints(frame.joints, baseframe, currentFrameValues, anim->jointInfos);
				
				currentFrame = -1;
				currentFrameValues.clear();
				
			} else {
				stringstream ss(line);
				
				while (!ss.eof()) {
					float x;
					ss >> x;
					if (ss.fail()) {
						throw runtime_error("Invalid md5anim Frame data");
					}
					
					currentFrameValues.push_back(x);
				}
			}
			
		}
	}
	
	int numFrames = stringToInt(anim->properties["numFrames"]);
	int numJoints = stringToInt(anim->properties["numJoints"]);

	if (numFrames != bounds.size() ||
		numJoints != baseframe.size() ||
		numJoints != anim->jointInfos.size() ||
		numFrames != anim->frames.size())
	{
		throw runtime_error("Invalid md5anim file: sanity check failed");
	}
    

	return anim;
}




