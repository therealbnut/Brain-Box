#import <OpenGL/OpenGL.h>
#import <Cocoa/Cocoa.h>
#import <GLUT/GLUT.h>

GLuint GLTextureCreateNamed(NSString * name);
GLint  GLShaderProgramCreateNamed(NSString * name);
int    CheckOpenGLErrors();