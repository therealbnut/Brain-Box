//
//  BBConnectionDefinition.h
//  BrainBox2
//
//  Created by Andrew Bennett on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBPasteboardable.h"

extern NSString * const kBBConnectionDefinitionDefaultKeyName;
extern NSString * const kBBConnectionDefinitionDefaultType;

@interface BBConnectionDefinition : NSObject<NSCoding, BBPasteboardable>
{
	NSString * _keyName;
	NSString * _type;
}

@property (readwrite, copy) NSString * keyName;
@property (readwrite, copy) NSString * type;

-init;
-initWithString: (NSString*) string;
-initWithPropertyList: (id) plist;
-initWithKeyName: (NSString*) keyName
			type: (NSString*) type;

+connectionFromString: (NSString*) definitionString;
+connectionFromPropertyList: (id) plist;
+connectionFromData: (NSData*) data;

-(NSString*) encodeAsString;
-(id) asPropertyList;
-(NSData*) encodeAsData;

@end
