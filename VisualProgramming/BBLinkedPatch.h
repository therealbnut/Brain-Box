//
//  BBPatch.h
//  BrainBox2
//
//  Created by Andrew Bennett on 20/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BBPatchDefinition;
@class BBPatchCollectionController;

@interface BBLinkedPatch : NSObject
{
	BBPatchCollectionController * _controller;
	BBPatchDefinition * _definition;

	NSUInteger _identity;

	NSMutableDictionary * _inputs;
	NSMutableDictionary * _outputs;

	CGPoint _center;
}

@property (readwrite, assign) BBPatchCollectionController * controller;
@property (readonly)  BBPatchDefinition * definition;
@property (readonly)  NSUInteger identity;
@property (readwrite) CGPoint center;

-initWithController: (BBPatchCollectionController*) controller
		   identity: (NSUInteger) identity
		 definition: (BBPatchDefinition*) definition
			atPoint: (CGPoint) point;

-(void) setInputWithKey: (NSString*) input
				toPatch: (BBLinkedPatch*) patch
					key: (NSString*) output;

@end
