#import "GLUtility.h"

#import <QuickTime/QuickTime.h>

void MakeFSSpecFromPath(const char* path, FSSpec* spec) 
{
	OSStatus err;
	FSRef fsref;
	Boolean isdir;
	
	err = FSPathMakeRef((const UInt8*)path, &fsref, &isdir);
	if(err != noErr)
	{
		NSLog(@"Can't make FSRef from path: '%s'", path);
		return;
	}
	
	if(isdir)
	{
		NSLog(@"Path is a directory.");
		return;
	}
	
	err = FSGetCatalogInfo(&fsref, kFSCatInfoNone, NULL, NULL, spec, NULL);
	if(err != noErr)
	{
		NSLog(@"Can't convert FSRef to FSSpec.");
		return;
	}
}

GLuint LoadTexture(const char * file)
{
	GLuint	 texID;
	FSSpec	 spec;
	GraphicsImportComponent	gi;
	GWorldPtr	 gw;
	Rect	 natbounds;
	void	 *buffer;
	
	MakeFSSpecFromPath(file, &spec);
	GetGraphicsImporterForFile(&spec,&gi);
	GraphicsImportGetNaturalBounds(gi, &natbounds);
	
	if(natbounds.left != 0)
	{
		NSLog(@"Natural bounds' left is not zero.");
		return 0;
	}
	
	if(natbounds.top != 0)
	{
		NSLog(@"Natural bounds' top is not zero.");
		return 0;
	}
	
	buffer = malloc(4 * natbounds.bottom * natbounds.right);
	if(buffer == NULL)
	{
		NSLog(@"Can't allocate texture buffer.");
		return 0;
	}
	
	QTNewGWorldFromPtr(&gw, k32ARGBPixelFormat, &natbounds, NULL, NULL, 0, buffer, 4 * natbounds.right);
	GraphicsImportSetGWorld(gi, gw, NULL);
	GraphicsImportDraw(gi);
	CloseComponent(gi);

	
	glGenTextures(1,&texID);
	
	glBindTexture(GL_TEXTURE_2D,texID);
	
	glPixelStorei(GL_UNPACK_ALIGNMENT,1);
	
	float largest_supported_anisotropy;
	glGetFloatv(GL_MAX_TEXTURE_MAX_ANISOTROPY_EXT, &largest_supported_anisotropy);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, largest_supported_anisotropy);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8,
				 natbounds.right, natbounds.bottom, 0,
				 GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, buffer);
	
	gluBuild2DMipmaps(GL_TEXTURE_2D, 4, natbounds.right, natbounds.bottom, 
					  GL_BGRA_EXT, GL_UNSIGNED_INT_8_8_8_8, buffer);
	
	free(buffer);
	
	return texID;
}

GLint LoadShader(const char * path, GLenum type)
{
	NSError * error;
	NSStringEncoding encoding;
	char * error_buffer;
	int  error_buffer_length;
	GLint shaderID;
	NSString * contents;
	const char * shader_source;
	int shader_source_length;
	
	contents = [NSString stringWithContentsOfFile: [NSString stringWithUTF8String: path]
									 usedEncoding: &encoding 
											error: &error];
	shader_source = [contents UTF8String];
	shader_source_length = [contents lengthOfBytesUsingEncoding: NSUTF8StringEncoding];
	
	if (shader_source == nil ||
		shader_source_length == 0)
	{
		NSLog(@"Source code could not be loaded: '%s'!", path);
		return 0;
	}
	
	shaderID = glCreateShader(type);
	glShaderSource(shaderID, 1, &shader_source, &shader_source_length);
	glCompileShader(shaderID);
	
	glGetShaderiv(shaderID, GL_INFO_LOG_LENGTH, &error_buffer_length);
	if (error_buffer_length > 0)
	{
		error_buffer = (char *) malloc(error_buffer_length);
		glGetShaderInfoLog(shaderID, error_buffer_length, &error_buffer_length, error_buffer);
		NSLog(@"Shader compiler error in '%s':\n%s!", path, error_buffer);
		free(error_buffer);
		glDeleteShader(shaderID);
		
		return 0;
	}
	
	return shaderID;
}

GLint LoadShaderProgram(const char * vert_path, const char * frag_path)
{
	char * error_buffer;
	int  error_buffer_length;
	GLint fragShaderID, vertShaderID;
	GLint programID;

	programID = glCreateProgram();

	fragShaderID = LoadShader(frag_path, GL_FRAGMENT_SHADER);
	vertShaderID = LoadShader(vert_path, GL_VERTEX_SHADER);

	glAttachShader(programID, fragShaderID);
	glAttachShader(programID, vertShaderID);
	glLinkProgram(programID);

	glGetProgramiv(programID, GL_INFO_LOG_LENGTH, &error_buffer_length);
	if (error_buffer_length > 0)
	{
		error_buffer = (char *) malloc(error_buffer_length);
		glGetProgramInfoLog(programID, error_buffer_length, &error_buffer_length, error_buffer);
		NSLog(@"Shader Linker error: %s", error_buffer);
		free(error_buffer);

		glDeleteProgram(programID);
		glDeleteShader(fragShaderID);
		glDeleteShader(vertShaderID);
	
		return 0;
	}

	return programID;
}

NSString * pathForResource(NSString * name, NSString * type)
{
	NSBundle * bundle;
	NSString * path;
	NSArray * array;

	path = [[NSBundle mainBundle] pathForResource: name
										   ofType: type];
	if (path != nil)
		return path;

	array = [NSBundle allFrameworks];
	for (bundle in array)
	{
		path = [bundle pathForResource: name
								ofType: type];
		if (path != nil)
			return path;
	}
	
	array = [NSBundle allBundles];
	for (bundle in array)
	{
		path = [bundle pathForResource: name
								ofType: type];
		if (path != nil)
			return path;
	}	
	
	return nil;
}

GLuint GLTextureCreateNamed(NSString * name)
{
	NSString * path = pathForResource(name, @"png");
	if (!path)
	{
		NSLog(@"Could not find texture for %@!", name);
		return 0;
	}
	return LoadTexture([path UTF8String]);
}

GLint GLShaderProgramCreateNamed(NSString * name)
{
	NSString * vert_path, * frag_path;

	vert_path = pathForResource(name, @"vert");
	if (!vert_path)
	{
		NSLog(@"Failed to compile vertex shader for %@!", name);
		return 0;
	}

	frag_path = pathForResource(name, @"frag");
	if (!frag_path)
	{
		NSLog(@"Failed to compile fragment shader for %@!", name);
		return 0;
	}

	return LoadShaderProgram([vert_path UTF8String], [frag_path UTF8String]);
}

int CheckOpenGLErrors()
{
	GLenum ecode;
	int ecount;
	
	ecount = 0;
	while ((ecode = glGetError()) != GL_NO_ERROR)
	{
		NSLog(@"OpenGL Error: %s", gluErrorString(ecode));
		++ecount;
	}
	
	return ecount;
}
