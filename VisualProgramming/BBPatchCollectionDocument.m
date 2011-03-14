//
//  BBSimulationDocument.m
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchCollectionDocument.h"

#import "BBPatchDefinition.h"
#import "BBPatchDocument.h"
#import "BBLinkedPatch.h"

#import "NSArray+BBUtility.h"

NSString * const kBBPatchCollectionPatchAddedNotification = @"BBPatchCollectionPatchAddedNotification";
NSString * const kBBPatchCollectionPatchRemovedNotification = @"BBPatchCollectionPatchRemovedNotification";

@implementation BBPatchCollectionDocument

- (NSString *)windowNibName
{
    // Implement this to return a nib to load OR implement -makeWindowControllers to manually create your controllers.
    return @"SimulationDocument";
}

#pragma mark Properties

@synthesize patches = _patches;

#pragma mark Initialisation

-(id) init
{
	if (self = [super init])
	{
		self->_patches = [[NSMutableDictionary alloc] init];
	}
	return self;
}
-(void) dealloc
{
	[self->_patches release];
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

-(NSUInteger) getUniquePatchIdentity
{
	++self->_patchIdentity;
	return self->_patchIdentity;
}

-(void) setPatches: (NSDictionary*) new_patches
{
	if (new_patches != self->_patches)
	{
		[[self undoManager] beginUndoGrouping];
		for (id key in self->_patches)
		{
			if ([new_patches objectForKey: key] == nil)
				[self removePatch: [self->_patches objectForKey: key]];
		}
		for (id key in new_patches)
		{
			if ([self->_patches objectForKey: key] == nil)
				[self addPatch: [new_patches objectForKey: key]];
		}
		[[self undoManager] endUndoGrouping];
	}
}

-(void) addPatch: (BBLinkedPatch*) patch
{
	[[self undoManager] registerUndoWithTarget: self
									  selector: @selector(removePatch:) 
										object: patch];	

	[self willChangeValueForKey: @"patches"];
	[self->_patches setObject: patch
					   forKey: [NSNumber numberWithInteger: [patch identity]]];
	[self didChangeValueForKey: @"patches"];

	id userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
				   patch, @"patch",
				   nil];
	[[NSNotificationCenter defaultCenter] postNotificationName: kBBPatchCollectionPatchAddedNotification
														object: self
													  userInfo: userInfo];
	[userInfo release];
}

-(void) removePatch: (BBLinkedPatch*) patch
{
	[[self undoManager] registerUndoWithTarget: self
									  selector: @selector(addPatch:) 
										object: [patch retain]];	

	[self willChangeValueForKey: @"patches"];
	[self->_patches removeObjectForKey: [NSNumber numberWithInteger: [patch identity]]];
	[self didChangeValueForKey: @"patches"];

	id userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
				   patch, @"patch",
				   nil];	
	[[NSNotificationCenter defaultCenter] postNotificationName: kBBPatchCollectionPatchRemovedNotification
														object: self
													  userInfo: userInfo];
	[userInfo release];
}

-(BBLinkedPatch*) patchForIdentity: (NSUInteger) identity
{
	return [self->_patches objectForKey: [NSNumber numberWithInteger: identity]];
}

#pragma mark -
#pragma mark Read Write

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
					 atPath:(NSString *)path 
					  error:(NSError **)error
{
	/*
	 In general, you should perform error checking throughout and if there is a problem return in &error a new NSError object that describes the issue.
	 */
    
	// Create a file wrapper for each object saved to a separate file.
	//    NSFileWrapper *imageFile = [[fileWrapper fileWrappers] objectForKey: ImageFileNameKey];	
	//    if (imageFile) {
	//		// Restore the picture from the file wrapper's data.
	//		// Disable undo registration so that this is not registered with the undo manager -- see the implementation of setPicture:.
	//		[[self undoManager] disableUndoRegistration];
	//		[self setPicture:[imageFile regularFileContents]];
	//		[[self undoManager] enableUndoRegistration];
	//    }	
	
    return YES;
}

- (BOOL)updateFileWrapper:(NSFileWrapper *)documentFileWrapper
				   atPath:(NSString *)path
					error:(NSError **)error
{
	/*
	 In general, you should perform error checking throughout and if there is a problem return in &error a new NSError object that describes the issue.
	 */
	
    // First, remove any previous existing wrappers for the custom content.
	//    NSFileWrapper *imageFileWrapper = [[documentFileWrapper fileWrappers] objectForKey:ImageFileNameKey];
	//    if (imageFileWrapper != nil)
	//	{
	//        [documentFileWrapper removeFileWrapper:imageFileWrapper];
	//    }
	
    // Create a new wrapper for each piece of data, set its name, and add it to the document file wrapper.
	//    imageFileWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:picture] autorelease];
	//    [imageFileWrapper setPreferredFilename:@"MyImage"];
	//    [documentFileWrapper addFileWrapper:imageFileWrapper];
	
    return YES;
}


@end
