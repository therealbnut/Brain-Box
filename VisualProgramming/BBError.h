//
//  BBError.h
//  BrainBox2
//
//  Created by Andrew Bennett on 11/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BBError : NSError

+(id) errorWithSelector: (SEL) aSelector 
				inClass: (Class) aClass
				 atLine: (NSUInteger) aLine;
@property (readonly) SEL errorSelector;
@property (readonly) Class errorClass;
@property (readonly) NSUInteger errorLine;

@end

#define BBErrorForThisLine() [BBError errorWithSelector: _cmd inClass: [self class] atLine: __LINE__]
