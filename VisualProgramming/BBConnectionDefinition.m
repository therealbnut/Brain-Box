//
//  BBConnectionDefinition.m
//  BrainBox2
//
//  Created by Andrew Bennett on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBConnectionDefinition.h"

NSString * const kBBConnectionDefinitionDefaultKeyName = @"Connection Key";
NSString * const kBBConnectionDefinitionDefaultType = @"Connection Type";

NSString * const kBBPatchDefinitionConnectionPboardType = @"BBPatchDefinitionConnection";

NSString * const kBBConnectionDefinitionKeyNameKey = @"KeyName";
NSString * const kBBConnectionDefinitionTypeKey = @"Type";

@implementation BBConnectionDefinition

#pragma mark Construction

+connectionFromString: (NSString*) string
{
	return [[[BBConnectionDefinition alloc] initWithString: string] autorelease];
}
+connectionFromPropertyList: (id) plist
{	
	return [[[BBConnectionDefinition alloc] initWithPropertyList: plist] autorelease];
}
+connectionFromData: (NSData*) data
{	
	return [NSKeyedUnarchiver unarchiveObjectWithData: data];
}

#pragma mark Encoding

-(NSString*) encodeAsString
{
	id plist = [self asPropertyList];
	NSString * serializationError = nil;
	
	NSData * data = [NSPropertyListSerialization dataFromPropertyList: plist
															   format: NSPropertyListXMLFormat_v1_0
													 errorDescription: &serializationError];
	if (serializationError != nil)
	{
		NSLog(@"BBConnectionDefinition encodeAsString error: %@", serializationError);
		return nil;
	}
	return [[[NSString alloc] initWithData: data
								  encoding: NSUTF8StringEncoding] autorelease];
}
-(id) asPropertyList
{
	NSDictionary * plist = [[NSDictionary alloc] initWithObjectsAndKeys:
							self->_keyName, kBBConnectionDefinitionKeyNameKey,
							self->_type, kBBConnectionDefinitionTypeKey,
							nil];
	return [plist autorelease];
}
-(NSData*) encodeAsData
{
	return [NSKeyedArchiver archivedDataWithRootObject: self];
}

#pragma mark Initialisation

-initWithString: (NSString*) string
{
	if (self = [super init])
	{
		NSPropertyListFormat format;
		NSString	* serializationError = nil;
		
		if (string == nil || [string length] == 0)
		{
			[self autorelease];
			return nil;
		}
		
		id plist = [NSPropertyListSerialization propertyListFromData: [string dataUsingEncoding: NSUTF8StringEncoding]
													mutabilityOption: NSPropertyListImmutable
															  format: &format
													errorDescription: &serializationError];
		if (serializationError != nil || ![plist isKindOfClass: [NSDictionary class]])
		{
			NSLog(@"BBConnectionDefinition initWithString error: %@ (%@)", serializationError, string);
			[self autorelease];
			return nil;
		}
		self->_keyName = [[[plist objectForKey: kBBConnectionDefinitionKeyNameKey] copy] retain];
		self->_type = [[[plist objectForKey: kBBConnectionDefinitionTypeKey] copy] retain];
	}
	return self;
}
-initWithPropertyList: (id) plist
{
	if (self = [super init])
	{
		if (!plist || ![plist isKindOfClass: [NSDictionary class]])
		{
			[self autorelease];
			return nil;
		}		
		self->_keyName = [[[plist objectForKey: kBBConnectionDefinitionKeyNameKey] copy] retain];
		self->_type = [[[plist objectForKey: kBBConnectionDefinitionTypeKey] copy] retain];
	}
	return self;
}
-initWithKeyName: (NSString*) newKeyName
			type: (NSString*) newType
{
	if (self = [super init])
	{
		self->_keyName = [[newKeyName copy] retain];
		self->_type = [[newType copy] retain];
	}
	return self;
}

-init
{
	if (self = [super init])
	{
		self->_keyName = [[kBBConnectionDefinitionDefaultKeyName copy] retain];
		self->_type = [[kBBConnectionDefinitionDefaultType copy] retain];
	}
	return self;
}

-initWithCoder: (NSCoder*) coder
{
	if (self = [super init])
	{
		self->_keyName = [[coder decodeObject] retain];
		self->_type = [[coder decodeObject] retain];

		if (self->_keyName == nil) abort();
		if (self->_type == nil) abort();
	}
	return self;
}

-(void) encodeWithCoder: (NSCoder*) coder
{
	[coder encodeObject: self->_keyName];
	[coder encodeObject: self->_type];
}

-(void) dealloc
{
	[self->_keyName release];
	[self->_type release];
	[super dealloc];
}

#pragma mark Comparison

-(BOOL) isEqual:(id)object
{
	BBConnectionDefinition * connection = (BBConnectionDefinition*) object;
	if (![object isKindOfClass: [BBConnectionDefinition class]])
		return NO;
	if (![connection->_keyName isEqualToString: self->_keyName])
		return NO;
//	if (![connection->_type isEqualToString: self->_type])
//		return NO;
	return YES;
}

#pragma mark -
#pragma mark Pasteboard

+(NSArray*) pasteboardTypes
{
	return [NSArray arrayWithObjects:
			NSStringPboardType,
			kBBPatchDefinitionConnectionPboardType,
			nil];
}

+fromPasteboard: (NSPasteboard*) pboard
{
	BBConnectionDefinition* connection = nil;
	
    if ([[pboard types] containsObject: kBBPatchDefinitionConnectionPboardType])
	{
		connection = [BBConnectionDefinition connectionFromData: 
					  [pboard dataForType: kBBPatchDefinitionConnectionPboardType]];
    }
	else if ([[pboard types] containsObject: NSStringPboardType])
	{
		connection = [BBConnectionDefinition connectionFromString:
					  [pboard stringForType: NSStringPboardType]];
    }
	
	return connection;
}

-(void) storeOnPasteboard: (NSPasteboard*) pboard
{
    [pboard declareTypes: [BBConnectionDefinition pasteboardTypes]
				   owner: self];
	[pboard setData: [self encodeAsData]
			forType: kBBPatchDefinitionConnectionPboardType];
	[pboard setString: [self encodeAsString]
			  forType: NSStringPboardType];	
}

- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)pboardType
{
	if ([pboardType compare: kBBPatchDefinitionConnectionPboardType] == NSOrderedSame)
	{
		[pboard setData: [self encodeAsData]
				forType: kBBPatchDefinitionConnectionPboardType];
    }
	else if ([pboardType compare: NSStringPboardType] == NSOrderedSame)
	{
		[pboard setString: [self encodeAsString]
				  forType: NSStringPboardType];
	}
}

#pragma mark -
#pragma mark Properties

#pragma mark Key Name

-(NSString*) keyName
{
	return [[self->_keyName retain] autorelease];
}
-(void) setKeyName: (NSString*) newKeyName
{
	[self willChangeValueForKey: @"keyName"];
	if (self->_keyName != newKeyName)
	{
		[self->_keyName release];
		self->_keyName = [[newKeyName copy] retain];
	}
	[self didChangeValueForKey: @"keyName"];
}
-(BOOL) validateKeyName: (id *)ioValue
				  error: (NSError **)outError
{
    if (*ioValue == nil || [*ioValue length] == 0)
	{
		*ioValue = [kBBConnectionDefinitionDefaultKeyName copy];
        return YES;
    }
//    NSString *capitalizedName = [*ioValue capitalizedString];
//    *ioValue = capitalizedName;
    return YES;
}

#pragma mark Type

-(NSString*) type
{
	return [[self->_type retain] autorelease];
}
-(void) setType: (NSString*) newType
{
	[self willChangeValueForKey: @"type"];
	if (self->_type != newType)
	{
		[self->_type release];
		self->_type = [[newType copy] retain];
	}
	[self didChangeValueForKey: @"type"];
}
-(BOOL) validateType: (id *)ioValue
			   error: (NSError **)outError
{
    if (*ioValue == nil || [*ioValue length] == 0)
	{
		*ioValue = [kBBConnectionDefinitionDefaultType copy];
        return YES;
    }
//    NSString *capitalizedName = [*ioValue capitalizedString];
//    *ioValue = capitalizedName;
    return YES;
}

@end
