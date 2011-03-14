//
//  BBPatchView.h
//  BrainBox2
//
//  Created by Andrew Bennett on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BBPatchDefinition;
@class BBPatchDocument;

extern const CGFloat kPatchShadowSize;
extern const CGFloat kPatchPadding;
extern const CGFloat kPatchInnerPadding;
extern const CGFloat kPatchBorder;
extern const CGFloat kPatchTextSize;
extern const CGFloat kPatchTitleTextSize;
extern const CGFloat kPatchMinInnerWidth;

@interface BBPatchView : NSView
{
	BBPatchDefinition * _definition;

	NSUInteger _imageHash[2];
	CGImageRef _patchImage[2];
}

@property (readwrite, assign) BBPatchDefinition * definition;

-(void) updateImage;

-(NSUInteger) cellColumnForPoint: (NSPoint) localPoint;
-(NSUInteger) cellRowForPoint: (NSPoint) localPoint;

-(NSPoint) centrePointForSize: (NSSize) size
					oldCentre: (NSPoint) oldCentre;

-(CGPoint) outputPointForIndex: (NSUInteger) index;
-(CGPoint) inputPointForIndex: (NSUInteger) index;

@end
