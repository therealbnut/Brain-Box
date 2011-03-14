#include "BBVector3.h"

#include "BBVisualization.h"

#import <OpenGL/OpenGL.h>
#include <iostream>

typedef BB::Vector3<GLfloat> GLVec3f;

void BBMultGLMatrixWithForwardAndUp(BBVector3 forward, BBVector3 up)
{
	GLfloat matrix[16] = {1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1};
	GLVec3f f(forward.coord), u(up.coord);
	GLVec3f bX, bY, bZ;
	
	bX = u.cross(f).normalize();
	bZ = f.normalize();
	bY = -bX.cross(bZ);
	
	for (int i=0; i<3; ++i) matrix[0 + i] = bX[i];
	for (int i=0; i<3; ++i) matrix[4 + i] = bY[i];
	for (int i=0; i<3; ++i) matrix[8 + i] = bZ[i];

//	for (int j=0; j<4; ++j)
//	{
//		for (int i=0; i<4; ++i)
//			printf("% 2.2f, ", matrix[j*4+i]);
//		printf("\n");
//	}
//	printf("\n");
	
	glMultMatrixf(matrix);
}

BBVector3 BBVector3CreateRandom(void)
{
	double z = (rand() / (double)RAND_MAX) * 2.0 - 1.0;
	double a = (rand() / (double)RAND_MAX) * M_PI * 2.0;
	double r = sqrt(1.0 - z * z);
	return BBVector3Make(r * cos(a), r * sin(a), z);
}

BBVector3 BBVector3Lerp(BBVector3 _a, BBVector3 _b, float v)
{
	BB::Vector3<float> a(_a.coord), b(_b.coord), c;
	c = a + (b-a) * v;
	return BBVector3Make(c.x, c.y, c.z);
}

BBVector3 BBVector3Normalize(BBVector3 _a)
{
	BB::Vector3<float> a(_a.coord);
	BB::Vector3<float> n = a.normalize();
	return BBVector3Make(n.x, n.y, n.z);
}

float BBVector3Length(BBVector3 _a)
{
	return BB::Vector3<float>(_a.coord).length();
}
