//
//  BBPatchDefinition.h
//  BrainBox2
//
//  Created by Andrew Bennett on 21/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBPasteboardable.h"

@class BBConnectionDefinition;

@interface BBPatchDefinition : NSObject<NSCoding, BBPasteboardable>
{
	NSString * _title;
	NSString * _source;
	NSMutableArray * _inputs;
	NSMutableArray * _outputs;
}

-init;
-initWithPropertyList: (id) plist;

-(void) setInterfaceFromPropertyList: (id) plist;
-(id) interfaceAsPropertyList;
-(id) asPropertyList;

-(void) setInputsFromPropertyList: (id) plist;
-(void) setOutputsFromPropertyList: (id) plist;

@property (readwrite, copy) NSString * title;
@property (readwrite, copy) NSString * source;

@property (readwrite, retain) NSMutableArray * inputs;
@property (readwrite, retain) NSMutableArray * outputs;

-(BOOL) isValidInput: (BBConnectionDefinition *) definition;
-(BOOL) isValidOutput: (BBConnectionDefinition *) definition;

- (void)insertObject: (BBConnectionDefinition *) input
	 inInputsAtIndex: (NSUInteger) index;
- (void)insertObject: (BBConnectionDefinition *) output
	inOutputsAtIndex: (NSUInteger) index;

-(NSString*) encodeAsString;
-(NSData*) encodeAsData;

@end
