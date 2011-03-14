//
//  BBWoodBackgroundView.m
//  BrainBox2
//
//  Created by Andrew Bennett on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBWoodBackgroundView.h"
#import "BBImageResource.h"

@implementation BBWoodBackgroundView

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSGraphicsContext currentContext] saveGraphicsState];

//	[[NSGraphicsContext currentContext] setPatternPhase:
//	 NSMakePoint(0,[self frame].size.height)];

	NSImage *anImage = [BBImageResource NSImageFromName: @"Mahogany"];
	[[NSColor colorWithPatternImage:anImage] set];
	NSRectFill([self bounds]);

	[[NSGraphicsContext currentContext] restoreGraphicsState];
}

@end
