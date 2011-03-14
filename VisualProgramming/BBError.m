//
//  BBError.m
//  BrainBox2
//
//  Created by Andrew Bennett on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBError.h"

NSString * const kBBErrorSelectorKey = @"selectorString";
NSString * const kBBErrorClassKey = @"classString";
NSString * const kBBErrorLineKey = @"lineNumber";

@implementation BBError

+(id) errorWithSelector: (SEL) aSelector
				inClass: (Class) aClass
				 atLine: (NSUInteger) aLine
{
	NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							   NSStringFromSelector(aSelector), kBBErrorSelectorKey,
							   NSStringFromClass(aClass), kBBErrorClassKey,
							   [NSNumber numberWithUnsignedInteger: aLine], kBBErrorLineKey,
							   nil];
	return [[[BBError alloc] initWithDomain: [[NSBundle mainBundle] bundleIdentifier]
									  code: -1
								  userInfo: userInfo] autorelease];
}

-(SEL) errorSelector
{
	return NSSelectorFromString([self valueForKey: kBBErrorSelectorKey]);
}
-(Class) errorClass;
{
	return NSClassFromString([self valueForKey: kBBErrorClassKey]);
}
-(NSUInteger) errorLine;
{
	return [[self valueForKey: kBBErrorLineKey] unsignedIntegerValue];
}

@end
