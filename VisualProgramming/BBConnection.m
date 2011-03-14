//
//  BBConnection.m
//  BrainBox2
//
//  Created by Andrew Bennett on 23/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBConnection.h"

#pragma mark -
#pragma mark BBConnection Implementation

NSString * const kBBConnectionPboardType = @"BBConnection";

@implementation BBConnection

@synthesize from = _from, output = _output;
@synthesize to = _to, input = _input;

-initFromPatch: (NSUInteger) new_from
		   key: (NSUInteger) new_output
	   toPatch: (NSUInteger) new_to
		   key: (NSUInteger) new_input
{
	if (self = [super init])
	{
		self->_from		= new_from;
		self->_output	= new_output;
		self->_to		= new_to;
		self->_input	= new_input;
	}
	return self;
}
-initWithCoder: (NSCoder*) coder
{
	if (self = [super init])
	{
		self->_from		= [[coder decodeObject] integerValue];
		self->_input	= [[coder decodeObject] integerValue];
		self->_to		= [[coder decodeObject] integerValue];
		self->_output	= [[coder decodeObject] integerValue];
	}
	return self;
}

-(void) encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject: [NSNumber numberWithInteger: self->_from]];
	[aCoder encodeObject: [NSNumber numberWithInteger: self->_input]];
	[aCoder encodeObject: [NSNumber numberWithInteger: self->_to]];
	[aCoder encodeObject: [NSNumber numberWithInteger: self->_output]];
}

+connectionFromPatch: (NSUInteger) from
				 key: (NSUInteger) output
			 toPatch: (NSUInteger) to
				 key: (NSUInteger) input
{
	return [[[BBConnection alloc] initFromPatch: from
											key: output
										toPatch: to
											key: input] autorelease];
}

-(BOOL) isEqualTo: (id) object
{
	if (![object isKindOfClass: [BBConnection class]])
		return NO;
	
	BBConnection * connection = (BBConnection*) object;
	
	if (connection->_from != self->_from)
		return NO;
	if (connection->_to != self->_to)
		return NO;
	if (connection->_input != self->_input)
		return NO;
	if (connection->_output != self->_output)
		return NO;	
	
	return YES;
}

+(NSArray*) pasteboardTypes
{
	return [NSArray arrayWithObject: kBBConnectionPboardType];
}
+fromPasteboard: (NSPasteboard*) pboard
{
	return [NSUnarchiver unarchiveObjectWithData: [pboard dataForType: kBBConnectionPboardType]];
}
-(void) storeOnPasteboard: (NSPasteboard*) pboard
{
	[pboard declareTypes: [NSArray arrayWithObject: kBBConnectionPboardType]
				   owner: self];
	[pboard setData: [NSArchiver archivedDataWithRootObject: self]
			forType: kBBConnectionPboardType];
}


@end
