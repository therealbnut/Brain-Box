//
//  BBConnection.h
//  BrainBox2
//
//  Created by Andrew Bennett on 23/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPasteboardable.h"

@class BBLinkedPatch;

@interface BBConnection : NSObject<BBPasteboardable, NSCoding>
{
	NSUInteger _from;
	NSUInteger _output;
	NSUInteger _to;
	NSUInteger _input;
}

-initFromPatch: (NSUInteger) from
		   key: (NSUInteger) output
	   toPatch: (NSUInteger) to
		   key: (NSUInteger) input;

+connectionFromPatch: (NSUInteger) from
				 key: (NSUInteger) output
			 toPatch: (NSUInteger) to
				 key: (NSUInteger) input;

@property (readonly) NSUInteger from;
@property (readonly) NSUInteger to;
@property (readonly) NSUInteger input;
@property (readonly) NSUInteger output;

@end
