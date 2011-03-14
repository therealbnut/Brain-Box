//
//  BBImageResource.m
//  BrainBox2
//
//  Created by Andrew Bennett on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBImageResource.h"

static NSMutableDictionary * BBImageResourceMap;

@implementation BBImageResource

+(void) initialize
{
	if (self == [BBImageResource class])
	{
		BBImageResourceMap = [[NSMutableDictionary alloc] init];
	}
}

+(NSBitmapImageRep*) ImageRepFromName: (NSString*) name
{
	NSBitmapImageRep * imageRep;
    CGImageRef image = NULL;
	CGImageSourceRef src;
	NSString * path;
    CFURLRef url;
	
	imageRep = [BBImageResourceMap objectForKey: name];
	if (imageRep != nil)
		return imageRep;
	
	path = [[NSBundle mainBundle] pathForImageResource: name];
	url  = (CFURLRef) [NSURL fileURLWithPath: path];
	if (!url)
	{
		NSLog(@"Warning: no file %@", path);
		return nil;
	}

	src  = CGImageSourceCreateWithURL(url, NULL);
	
    if(!src)
	{
		NSLog(@"Warning: CGImageFromName failed on file %@", path);
		return nil;
	}
	
	image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
	CFRelease(src);
	
	if (!image)
	{
		NSLog(@"Warning: CGImageFromName failed on file %@", path);
		return nil;
	}
	
	imageRep = [[NSBitmapImageRep alloc] initWithCGImage: image];
	[BBImageResourceMap setObject: imageRep
						   forKey: name];
	CGImageRelease(image);
	[imageRep release];
	
    return imageRep;
}

+(NSImage*) NSImageFromName: (NSString*) name
{
	CGImageRef cgImage = [[BBImageResource ImageRepFromName: name] CGImage];
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
	NSImage *image = [[NSImage alloc] init];

	[image addRepresentation:bitmapRep];
	[bitmapRep release];

	return [image autorelease];
}

+(CGImageRef) CGImageFromName: (NSString*) name
{
    return [[BBImageResource ImageRepFromName: name] CGImage];
}

@end
