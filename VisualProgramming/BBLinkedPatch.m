//
//  BBPatch.m
//  BrainBox2
//
//  Created by Andrew Bennett on 20/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBLinkedPatch.h"

#import "BBPatchDefinition.h"
#import "BBConnectionDefinition.h"

#pragma mark -
#pragma mark BBPatch Implementation

@implementation BBLinkedPatch

@synthesize controller = _controller;
@synthesize identity = _identity;
@synthesize definition = _definition;
@synthesize center = _center;

-(void) initializeFromDefinition: (BBPatchDefinition*) new_definition
{
	BBConnectionDefinition * connection;
	
	self->_definition = new_definition;

	self->_inputs = [[NSMutableDictionary dictionaryWithCapacity: [[new_definition inputs] count]] retain];
	for (connection in [new_definition inputs])
	{
		[self->_inputs setObject: [NSNull null]
						  forKey: [connection keyName]];
	}

	self->_outputs = [[NSMutableDictionary dictionaryWithCapacity: [[new_definition outputs] count]] retain];
	for (connection in [new_definition outputs])
	{
		[self->_outputs setObject: [NSNull null]
						  forKey: [connection keyName]];
	}	
}

-initWithController: (BBPatchCollectionController*) new_controller
		   identity: (NSUInteger) identity
		 definition: (BBPatchDefinition*) new_definition
			atPoint: (CGPoint) point;
{
	if (self = [super init])
	{
		self->_controller = new_controller;
		self->_identity = identity;
		self->_center = point;
		
		[self initializeFromDefinition: new_definition];
	}
	return self;
}

-(void) setInputWithKey: (NSString*) input
				toPatch: (BBLinkedPatch*) patch
					key: (NSString*) output
{

}

-(BOOL) isEqualTo: (id) object
{
	return (self == object);
//	if (![super isEqualTo: object])
//		return NO;
//	if (![object isKindOfClass: [BBLinkedPatch class]])
//		return NO;
//	
//	BBLinkedPatch* patch = (BBLinkedPatch*) object;
//
//	if (![patch->_inputs isEqualTo: self->_inputs])
//		return NO;
//	if (![patch->_inputs isEqualTo: self->_inputs])
//		return NO;
//	if (patch->_center.x != self->_center.x || 
//		patch->_center.y != self->_center.y)
//		return NO;
//	return YES;
}

@end

