#import <Cocoa/Cocoa.h>
#import <BBVisualization/BBVisualization.h>

@interface BBWorldView : NSOpenGLView
{
	NSTimer * _updateTimer;
	GLuint _texAmbientOcclusion, _texNormals, _texLightMap;
	GLint  _shaderProgram;

	BBVector3Array _array_colors;
	BBVector3Array _array_scales;
	BBVector3Array _array_translations;
	BBVector3Array _array_forwards;
	BBVector3Array _array_ups;
}

@property (readwrite) BBVector3Array colors;
@property (readwrite) BBVector3Array scales;
@property (readwrite) BBVector3Array translations;
@property (readwrite) BBVector3Array forwards;
@property (readwrite) BBVector3Array ups;

@end
