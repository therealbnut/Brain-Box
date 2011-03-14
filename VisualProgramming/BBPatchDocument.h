//
//  BBPatchDocument.h
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSDocumentWrapper.h"

@class BBPatchDefinition;
@class BBConnectionDefinition;

@interface BBPatchDocument : NSDocumentWrapper
{
	BBPatchDefinition * _definition;
}

@property (readonly) BBPatchDefinition * definition;

- (void)insertObject: (BBConnectionDefinition *) input
	 inInputsAtIndex: (NSUInteger) index;
- (void)insertObject: (BBConnectionDefinition *) output
	inOutputsAtIndex: (NSUInteger) index;

@property (readwrite, copy) NSString* title;
@property (readwrite, copy) NSString* source;

- (NSString *)viewNibName;

+(BBPatchDefinition*) definitionFromDocumentAtPath: (NSString*) path;

@end
