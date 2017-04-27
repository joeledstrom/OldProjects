#define s 1.0f

float na[] = {
	0,-1,0, 0,-1,0, 0,-1,0, 0,-1,0, 0,-1,0, 0,-1,0, 
	0,1,0, 0,1,0, 0,1,0, 0,1,0, 0,1,0, 0,1,0, 
	1,0,0, 1,0,0, 1,0,0, 1,0,0, 1,0,0, 1,0,0, 
	0,0,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1, 
	-1,0,0, -1,0,0, -1,0,0, -1,0,0, -1,0,0, -1,0,0, 
	0,0,-1, 0,0,-1, 0,0,-1, 0,0,-1, 0,0,-1, 0,0,-1
};

vector<GLfloat> normals(na, na + (sizeof(na)/sizeof(na[0])));

      

 float tca[] = {
	1,0,1,1,0,1,1,0,0,1,0,0,
	1,0,0,0,0,1,1,0,0,1,1,1,
	0,0,1,0,1,1,0,0,1,1,0,1,
	1,0,1,1,0,1,1,0,0,1,0,0,
	0,1,1,1,1,0,0,1,1,0,0,0,
	1,1,1,0,0,0,1,1,0,0,0,1
};
vector<GLfloat> texCoords(tca, tca + (sizeof(tca)/sizeof(tca[0])));


float va[] = {
	s, -s, -s,
	s, -s, s,
	-s, -s, s,
	s, -s, -s,
	-s, -s, s,
	-s, -s, -s,
	
	s, s, -s,
	-s, s, -s,
	-s, s, s,
	s, s, -s,
	-s, s, s,
	s, s, s,
	
	s, -s, -s,
	s, s, -s,
	s, s, s,
	s, -s, -s,
	s, s, s,
	s, -s, s,
	
	s, -s, s,
	s, s, s,
	-s, s, s,
	s, -s, s,
	-s, s, s,
	-s, -s, s,
	
	-s, -s, s,
	-s, s, s,
	-s, s, -s,
	-s, -s, s,
	-s, s, -s,
	-s, -s, -s,	
	
	s, s, -s,
	s, -s, -s,
	-s, -s, -s,	
	s, s, -s,
	-s, -s, -s,
	-s, s, -s,
};

vector<GLfloat> vertices(va, va + (sizeof(va)/sizeof(va[0])));








GLBuffer* vertexBuf = new GLBuffer(vertices, GL_ARRAY_BUFFER, GL_STATIC_DRAW);
vertexBuf->bind();
glEnableVertexAttribArray(positionAttrib);
glVertexAttribPointer(positionAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);


GLBuffer* normalsBuf = new GLBuffer(normals, GL_ARRAY_BUFFER, GL_STATIC_DRAW);
normalsBuf->bind();
glEnableVertexAttribArray(normalAttrib);
glVertexAttribPointer(normalAttrib, 3, GL_FLOAT, GL_FALSE, 0, 0);




GLBuffer* texCoordBuf = new GLBuffer(texCoords, GL_ARRAY_BUFFER, GL_STATIC_DRAW);
texCoordBuf->bind();

glEnableVertexAttribArray(texCoordAttrib);
glVertexAttribPointer(texCoordAttrib, 2, GL_FLOAT, GL_FALSE, 0, 0);