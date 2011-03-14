//
//  NSArray+BBUtility.m
//  BrainBox2
//
//  Created by Andrew Bennett on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSArray+BBUtility.h"


@implementation NSArray (BBUtility)

-(id) arrayByPerformingSelector: (SEL) aSelector
{
	NSMutableArray * array = [[NSMutableArray alloc] initWithCapacity: [self count]];
	
	for (id object in self)
		[array addObject: [object performSelector: aSelector]];
	
	return [array autorelease];
}
-(id) arrayFromIndexSet: (NSIndexSet*) indexSet
{
	NSMutableArray * array;
	NSUInteger * indices;
	NSUInteger i, count;
	
	count   = [indexSet count];
	indices = calloc(count, sizeof(NSUInteger));
	array   = [[NSMutableArray alloc] initWithCapacity: count];
	
	[indexSet getIndexes: indices
				maxCount: count
			inIndexRange: nil];
	
	for (i = 0; i < count; ++i)
		[array addObject: [self objectAtIndex: indices[i]]];
	
	free(indices);
	
	return [array autorelease];
}

@end
