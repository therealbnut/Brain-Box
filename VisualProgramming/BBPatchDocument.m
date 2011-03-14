//
//  BBPatchDocument.m
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchDocument.h"
#import "BBError.h"

#import "BBConnectionDefinition.h"

#import "BBPatchDefinition.h"

NSString * const kBBPatchDocumentSourceFileNameKey = @"source.js";
NSString * const kBBPatchDocumentInfoFileNameKey = @"Info.plist";

@implementation BBPatchDocument

@synthesize definition = _definition;

-(id) init
{
	if (self = [super init])
	{
		self->_definition = [[BBPatchDefinition alloc] init];
	}
	return self;
}
-(void) dealloc
{
	[self->_definition release];
	[super dealloc];
}

#pragma mark Nib Stuff

- (NSString *)viewNibName
{
    return @"PatchDocumentView";
}
- (NSString *)windowNibName
{
    return @"PatchDocument";
}

#pragma mark -
#pragma mark Properties

#pragma mark Inputs
- (void)insertObject: (BBConnectionDefinition *) input
	 inInputsAtIndex: (NSUInteger) index
{
	[[self undoManager] registerUndoWithTarget: self->_definition
									  selector: @selector(setInputs:) 
										object: [[[self->_definition inputs] mutableCopy] autorelease]];
	[self->_definition insertObject: input
					inInputsAtIndex: index];
}

#pragma mark Outputs
- (void)insertObject: (BBConnectionDefinition *) output
	inOutputsAtIndex: (NSUInteger) index
{
	[[self undoManager] registerUndoWithTarget: self->_definition
									  selector: @selector(setOutputs:) 
										object: [[[self->_definition outputs] mutableCopy] autorelease]];
	[self->_definition insertObject: output
				   inOutputsAtIndex: index];
}

#pragma mark Title
-(NSString*) title
{
	return [self->_definition title];
}
-(void) setTitle: (NSString *) new_title
{
	[[self undoManager] registerUndoWithTarget: self->_definition
									  selector: @selector(setTitle:) 
										object: [[[self->_definition title] copy] autorelease]];
	[self->_definition setTitle: new_title];
}

#pragma mark Source
-(NSString*) source
{
	return [self->_definition source];
}
-(void) setSource: (NSString *) new_source
{
	[[self undoManager] registerUndoWithTarget: self->_definition
									  selector: @selector(setSource:) 
										object: [[[self->_definition source] copy] autorelease]];
	[self->_definition setSource: new_source];
}

#pragma mark Read

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
					 atPath:(NSString *)path 
					  error:(NSError **)error
{
//	NSLog(@"[fileWrapper fileWrappers]: %@", [fileWrapper fileWrappers]);
	
    NSFileWrapper * sourceFileWrapper;
	NSFileWrapper * infoFileWrapper;

	sourceFileWrapper = [[fileWrapper fileWrappers] objectForKey: kBBPatchDocumentSourceFileNameKey];
	[[self undoManager] disableUndoRegistration];
    if (sourceFileWrapper != nil)
	{
		NSString * newSource = [[NSString alloc] initWithData: [sourceFileWrapper regularFileContents] 
													 encoding: NSUTF8StringEncoding];
		[[self undoManager] registerUndoWithTarget: self->_definition
										  selector: @selector(setSource:) 
											object: [[[self->_definition source] copy] autorelease]];
		[self->_definition setSource: newSource];
		[newSource release];
	}
	
	infoFileWrapper = [[fileWrapper fileWrappers] objectForKey: kBBPatchDocumentInfoFileNameKey];
	if (infoFileWrapper != nil)
	{
		NSString * serializationError = nil;
		id plist = [NSPropertyListSerialization propertyListFromData: [infoFileWrapper regularFileContents]
													mutabilityOption: NSPropertyListImmutable
															  format: NULL
													errorDescription: &serializationError];
		if (serializationError != nil)
		{
			NSLog(@"BBPatchDocument readFromFileWrapper error: %@", serializationError);
			[[self undoManager] enableUndoRegistration];
			return NO;
		}
		[[self undoManager] registerUndoWithTarget: self->_definition
										  selector: @selector(setInterfaceFromPropertyList:) 
											object: [[[self->_definition interfaceAsPropertyList] copy] autorelease]];
		[self->_definition setInterfaceFromPropertyList: plist];
	}
	[[self undoManager] enableUndoRegistration];
	
    return YES;
}

#pragma mark Write

-(NSFileWrapper*) createSourceFile
{
	NSFileWrapper * sourceFileWrapper;
	
	// SOURCE FILE
	sourceFileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents: 
						  [[self->_definition source] dataUsingEncoding: NSUTF8StringEncoding]
						  ] autorelease];
	if (!sourceFileWrapper)
		return nil;
	[sourceFileWrapper setPreferredFilename: kBBPatchDocumentSourceFileNameKey];

	return sourceFileWrapper;
}

-(NSFileWrapper*) createInfoFile
{
	NSFileWrapper * infoFileWrapper;
	NSString * serializationError = nil;
	id data;

	data = [NSPropertyListSerialization dataFromPropertyList: [self->_definition interfaceAsPropertyList]
													  format: NSPropertyListXMLFormat_v1_0
											errorDescription: &serializationError];
	if (!data || serializationError != nil)
	{
		NSLog(@"BBPatchDocument createInfoFile: %@", serializationError);
		return nil;
	}
	
	infoFileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents: data] autorelease];

	if (!infoFileWrapper)
		return nil;

	[infoFileWrapper setPreferredFilename: kBBPatchDocumentInfoFileNameKey];

	return infoFileWrapper;
}

- (BOOL)updateFileWrapper:(NSFileWrapper *)documentFileWrapper
				   atPath:(NSString *)path
					error:(NSError **)error
{
	NSFileWrapper * sourceFileWrapper;
	NSFileWrapper * infoFileWrapper;
	
	sourceFileWrapper = [[documentFileWrapper fileWrappers] objectForKey: kBBPatchDocumentSourceFileNameKey];
	if (sourceFileWrapper != nil)
		[documentFileWrapper removeFileWrapper: sourceFileWrapper];
	
	infoFileWrapper = [[documentFileWrapper fileWrappers] objectForKey: kBBPatchDocumentInfoFileNameKey];
	if (infoFileWrapper != nil)
		[documentFileWrapper removeFileWrapper: infoFileWrapper];
	
	sourceFileWrapper = [self createSourceFile];
	infoFileWrapper = [self createInfoFile];
	if (!sourceFileWrapper || !infoFileWrapper)
	{
		if (error != NULL)
			*error = BBErrorForThisLine();
		return NO;		
	}
	[documentFileWrapper addFileWrapper: sourceFileWrapper];
	[documentFileWrapper addFileWrapper: infoFileWrapper];
	
    return YES;
}

+(BBPatchDefinition*) definitionFromDocumentAtPath: (NSString*) path
{
	
	NSFileWrapper * fileWrapper = [[NSFileWrapper alloc] initWithPath: path];
    NSFileWrapper * sourceFileWrapper;
	NSFileWrapper * infoFileWrapper;
	NSMutableDictionary * plist;
	BBPatchDefinition * new_definition;

	plist = [[NSMutableDictionary alloc] init];
	
	sourceFileWrapper = [[fileWrapper fileWrappers] objectForKey: kBBPatchDocumentSourceFileNameKey];
    if (sourceFileWrapper != nil)
	{
		NSString * newSource = [[NSString alloc] initWithData: [sourceFileWrapper regularFileContents] 
													 encoding: NSUTF8StringEncoding];
		[plist setObject: newSource
				  forKey: @"source"];
		[newSource release];
	}
	
	infoFileWrapper = [[fileWrapper fileWrappers] objectForKey: kBBPatchDocumentInfoFileNameKey];
	if (infoFileWrapper != nil)
	{
		NSString * serializationError = nil;
		id info = [NSPropertyListSerialization propertyListFromData: [infoFileWrapper regularFileContents]
												   mutabilityOption: NSPropertyListImmutable
															 format: NULL
												   errorDescription: &serializationError];
		if (serializationError != nil)
		{
			NSLog(@"BBPatchDocument definitionFromDocumentAtPath: %@(%d)", serializationError);
			[fileWrapper release];
			[plist release];

			return nil;
		}
		[plist addEntriesFromDictionary: info];
	}
	
	new_definition =  [[[BBPatchDefinition alloc] initWithPropertyList: plist] autorelease];
	
	[fileWrapper release];
	[plist release];

	return new_definition;
}

@end
