#import "BBWorldView.h"
#import "GLUtility.h"

@implementation BBWorldView

@synthesize colors       = _array_colors;
@synthesize scales       = _array_scales;
@synthesize translations = _array_translations;
@synthesize forwards     = _array_forwards;
@synthesize ups          = _array_ups;

+ (NSOpenGLPixelFormat*) basicPixelFormat
{
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFAWindow,
        NSOpenGLPFADoubleBuffer,	// double buffered
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)24, // 24 bit depth buffer
		
		NSOpenGLPFAMultisample,
		NSOpenGLPFASampleBuffers, (NSOpenGLPixelFormatAttribute)1,
		NSOpenGLPFASamples, (NSOpenGLPixelFormatAttribute)4,
		
        (NSOpenGLPixelFormatAttribute) 0
    };
    return [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
}

-initWithFrame: (NSRect) frameRect
{
	NSOpenGLPixelFormat * pixelFormat = [BBWorldView basicPixelFormat];
	if (self = [super initWithFrame: frameRect
						pixelFormat: pixelFormat])
	{
	}
    return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}
- (BOOL)becomeFirstResponder
{
	return  YES;
}
- (BOOL)resignFirstResponder
{
	return YES;
}

- (void) awakeFromNib
{
	self->_updateTimer = [NSTimer timerWithTimeInterval: (1.0f/60.0f) 
												 target: self 
											   selector: @selector(update:) 
											   userInfo: nil
												repeats: YES];
	[[NSRunLoop currentRunLoop] addTimer: self->_updateTimer
								 forMode: NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer: self->_updateTimer
								 forMode: NSEventTrackingRunLoopMode];
}

-(void) setupShaders
{
	self->_shaderProgram = GLShaderProgramCreateNamed(@"texRepeat");
	if (CheckOpenGLErrors() != 0)
		NSLog(@"OpenGL Errors encountered while creating the shader program!");

	if (self->_shaderProgram != 0)
	{
		GLint attribLoc;
		const char * samplerNames[] =
		{
			"diffuseMap",
			"normalMap",
			"lightMap"
		};

		glUseProgram(self->_shaderProgram);
		for (GLint i=0; i<3; ++i)
		{
			attribLoc = glGetUniformLocation(self->_shaderProgram, samplerNames[i]);
			if (CheckOpenGLErrors() != 0)
				NSLog(@"OpenGL Errors encountered while getting uniform location: %s", samplerNames[i]);
			if (attribLoc == -1)
				NSLog(@"Unable to find uniform location: %s", samplerNames[i]);
			else
			{
				glUniform1i(attribLoc, i);
				if (CheckOpenGLErrors() != 0)
					NSLog(@"OpenGL Errors encountered while setting uniform: %s", samplerNames[i]);
			}
		}
		glUseProgram(0);
	}
}
-(void) setupTextures
{
	self->_texAmbientOcclusion = GLTextureCreateNamed(@"Occlusion");
	self->_texNormals          = GLTextureCreateNamed(@"Normals");
	self->_texLightMap         = GLTextureCreateNamed(@"LightMap");
}
- (void) prepareOpenGL
{
	glEnable(GL_DEPTH_TEST);

	glEnable(GL_DEPTH_TEST);
	
	glShadeModel(GL_SMOOTH);
	glHint( GL_LINE_SMOOTH_HINT, GL_NICEST );
	glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
	glHint( GL_POLYGON_SMOOTH_HINT, GL_NICEST );
	glEnable(GL_MULTISAMPLE);
	
	glEnable(GL_CULL_FACE);
	glFrontFace(GL_CCW);
	glPolygonOffset (1.0f, 1.0f);
	
	glClearColor(0.0, 0.0, 0.0, 0.0);

	[self setupTextures];
	[self setupShaders];
}
- (void) updateProjection
{
	NSRect rect;
	float w, h;
	
	rect = [self bounds];

	[[self openGLContext] makeCurrentContext];

	w = rect.size.width;
	h = rect.size.height;
	
	if (w > h)
	{
		h /= w;
		w  = 1.0;
	}
	else
	{
		w /= h;
		h  = 1.0;
	}

	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glFrustum(-w, w, -h, h, 1.0, 1000.0);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glTranslated(0.0, 0.0, -2.0);
}
- (void) reshape
{
	NSRect rect;
	rect = [self bounds];
	[[self openGLContext] makeCurrentContext];

	glViewport(0, 0, rect.size.width, rect.size.height);
	
	[self updateProjection];
}
-(void) update
{
	[self setNeedsDisplay: YES];
}
-(void) update: (NSTimer*) timer
{
	[self update];
}
-(void) beginCubeWithSizeAttribute: (GLint*) attribLocSize
				   tangetAttribute: (GLint*) attribLocTan
{
	CheckOpenGLErrors();
	*attribLocSize = -1;
	*attribLocTan  = -1;
	if (self->_shaderProgram != 0)
	{
		glUseProgram(self->_shaderProgram);
		if (CheckOpenGLErrors() != 0)
			NSLog(@"OpenGL Errors encountered while using shader program");
		
		attribLocSize[0] = glGetAttribLocation(self->_shaderProgram, "in_size");
		if (CheckOpenGLErrors() != 0)
			NSLog(@"OpenGL Errors encountered while getting attribute size");

		attribLocTan[0] = glGetAttribLocation(self->_shaderProgram, "in_tangent");
		if (CheckOpenGLErrors() != 0)
			NSLog(@"OpenGL Errors encountered while getting attribute tangent");
		
		glEnable(GL_TEXTURE_2D);
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, self->_texAmbientOcclusion);
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, self->_texNormals);
		glActiveTexture(GL_TEXTURE2);
		glBindTexture(GL_TEXTURE_2D, self->_texLightMap);
		if (CheckOpenGLErrors() != 0)
			NSLog(@"OpenGL Errors encountered while binding textures");
	}	
}

-(void) endCube
{
	glUseProgram(0);
	glDisable(GL_TEXTURE_2D);
	CheckOpenGLErrors();
}

void drawCube(GLint attribLocSize, GLint attribLocTan,
			  BBVector3 color, BBVector3 scale, BBVector3 translation, BBVector3 forward, BBVector3 up)
{
	// this is probably all wrong, looks ok though...?
	glPushMatrix();
	{
		glLoadIdentity();
		glColor3f(color.coord[0], color.coord[1], color.coord[2]);
		glTranslated(translation.coord[0], translation.coord[1], translation.coord[2]);
		
		BBMultGLMatrixWithForwardAndUp(forward, up);
	
		glBegin(GL_QUADS);
		{
			// front
			if (attribLocSize != -1) glVertexAttrib2f(attribLocSize, scale.coord[0], scale.coord[0]);
			if (attribLocTan  != -1) glVertexAttrib3f(attribLocTan, 1.0, 0.0, 0.0);
			glNormal3f( 0.0, 0.0, 1.0);
			glTexCoord2f(1.0, 1.0); glVertex3f( scale.coord[0], scale.coord[1], scale.coord[2]);
			glTexCoord2f(0.0, 1.0); glVertex3f(-scale.coord[0], scale.coord[1], scale.coord[2]);
			glTexCoord2f(0.0, 0.0); glVertex3f(-scale.coord[0],-scale.coord[1], scale.coord[2]);
			glTexCoord2f(1.0, 0.0); glVertex3f( scale.coord[0],-scale.coord[1], scale.coord[2]);	

			// back
			if (attribLocSize != -1) glVertexAttrib2f(attribLocSize, scale.coord[0], scale.coord[1]);
			if (attribLocTan  != -1) glVertexAttrib3f(attribLocTan,-1.0, 0.0, 0.0);
			glNormal3f( 0.0, 0.0,-1.0);
			glTexCoord2f(1.0, 0.0); glVertex3f( scale.coord[0],-scale.coord[1],-scale.coord[2]);
			glTexCoord2f(0.0, 0.0); glVertex3f(-scale.coord[0],-scale.coord[1],-scale.coord[2]);
			glTexCoord2f(0.0, 1.0); glVertex3f(-scale.coord[0], scale.coord[1],-scale.coord[2]);
			glTexCoord2f(1.0, 1.0); glVertex3f( scale.coord[0], scale.coord[1],-scale.coord[2]);

			// top
			if (attribLocSize != -1) glVertexAttrib2f(attribLocSize, scale.coord[2], scale.coord[0]);
			if (attribLocTan  != -1) glVertexAttrib3f(attribLocTan, 0.0, 0.0, 1.0);
			glNormal3f( 0.0, 1.0, 0.0);
			glTexCoord2f(1.0, 0.0); glVertex3f( scale.coord[0], scale.coord[1], scale.coord[2]);
			glTexCoord2f(0.0, 0.0); glVertex3f( scale.coord[0], scale.coord[1],-scale.coord[2]);
			glTexCoord2f(0.0, 1.0); glVertex3f(-scale.coord[0], scale.coord[1],-scale.coord[2]);
			glTexCoord2f(1.0, 1.0); glVertex3f(-scale.coord[0], scale.coord[1], scale.coord[2]);
			
			// bottom
			if (attribLocSize != -1) glVertexAttrib2f(attribLocSize, scale.coord[2], scale.coord[0]);
			if (attribLocTan  != -1) glVertexAttrib3f(attribLocTan, 0.0, 0.0,-1.0);
			glNormal3f( 0.0,-1.0, 0.0);
			glTexCoord2f(1.0, 1.0); glVertex3f(-scale.coord[0],-scale.coord[1], scale.coord[2]);
			glTexCoord2f(0.0, 1.0); glVertex3f(-scale.coord[0],-scale.coord[1],-scale.coord[2]);
			glTexCoord2f(0.0, 0.0); glVertex3f( scale.coord[0],-scale.coord[1],-scale.coord[2]);
			glTexCoord2f(1.0, 0.0); glVertex3f( scale.coord[0],-scale.coord[1], scale.coord[2]);

			// right
			if (attribLocSize != -1) glVertexAttrib2f(attribLocSize, scale.coord[1], scale.coord[2]);
			if (attribLocTan != -1) glVertexAttrib3f(attribLocTan, 0.0, 1.0, 0.0);
			glNormal3f( 1.0, 0.0, 0.0);
			glTexCoord2f(0.0, 0.0); glVertex3f( scale.coord[0],-scale.coord[1],-scale.coord[2]);
			glTexCoord2f(1.0, 0.0); glVertex3f( scale.coord[0], scale.coord[1],-scale.coord[2]);
			glTexCoord2f(1.0, 1.0); glVertex3f( scale.coord[0], scale.coord[1], scale.coord[2]);
			glTexCoord2f(0.0, 1.0); glVertex3f( scale.coord[0],-scale.coord[1], scale.coord[2]);

			// left
			if (attribLocSize != -1) glVertexAttrib2f(attribLocSize, scale.coord[1], scale.coord[2]);
			if (attribLocTan  != -1) glVertexAttrib3f(attribLocTan, 0.0, -1.0, 0.0);
			glNormal3f(-1.0, 0.0, 0.0);
			glTexCoord2f(0.0, 1.0); glVertex3f(-scale.coord[0],-scale.coord[1], scale.coord[2]);
			glTexCoord2f(1.0, 1.0); glVertex3f(-scale.coord[0], scale.coord[1], scale.coord[2]);
			glTexCoord2f(1.0, 0.0); glVertex3f(-scale.coord[0], scale.coord[1],-scale.coord[2]);
			glTexCoord2f(0.0, 0.0); glVertex3f(-scale.coord[0],-scale.coord[1],-scale.coord[2]);
		}
		glEnd();
	}
	glPopMatrix();
}

- (void)drawRect: (NSRect) dirtyRect
{
	[[self openGLContext] makeCurrentContext];

	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

//	static BBVector3 old  = {0.0, 0.0, 1.0};
//	static BBVector3 oldv = {0.0, 0.0, 0.0};
//	float oldv_normfac;

//	oldv = BBVector3Lerp(oldv, BBVector3CreateRandom(), 0.05);
//	oldv_normfac = 0.1 / BBVector3Length(oldv);
//	if (oldv_normfac < 1.0) oldv = BBVector3Mul(oldv, oldv_normfac);
//	old  = BBVector3Normalize(BBVector3Add(old, oldv));

//	BBMultGLMatrixWithForwardAndUp(old, BBVector3Make(0.0, 1.0, 0.0));

	if (self->_array_colors       != NULL &&
		self->_array_scales       != NULL &&
		self->_array_translations != NULL &&
		self->_array_forwards     != NULL &&
		self->_array_ups          != NULL)
	{
		GLint attribLocSize, attribLocTan;		
		float * c, * s, * t, * f, * u;
		size_t index = 0;

		[self beginCubeWithSizeAttribute: &attribLocSize
						 tangetAttribute: &attribLocTan];
		
		while (YES)
		{
			c = BBVector3Array_getComponents(self->_array_colors, index);
			s = BBVector3Array_getComponents(self->_array_scales, index);
			t = BBVector3Array_getComponents(self->_array_translations, index);
			f = BBVector3Array_getComponents(self->_array_forwards, index);
			u = BBVector3Array_getComponents(self->_array_ups, index);

			if (!c || !s || !s || !t || !f || !u)
				break;

			drawCube(attribLocSize, attribLocTan, *(BBVector3*)c, *(BBVector3*)s, *(BBVector3*)t, *(BBVector3*)f, *(BBVector3*)u);

			++index;
		}
		
		[self endCube];
	}

	[[self openGLContext] flushBuffer];
}

@end
