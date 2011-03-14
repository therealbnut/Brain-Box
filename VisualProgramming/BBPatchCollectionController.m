//
//  BBPatchCollectionController.m
//  BrainBox2
//
//  Created by Andrew Bennett on 22/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchCollectionController.h"
#import "BBPatchCollectionDocument.h"

#import "BBPatchDocument.h"
#import "BBLinkedPatch.h"

#import "NSArray+BBUtility.h"

NSString * const kBBPatchCollectionControllerIndicesPboardType = @"BBPatchCollectionControllerIndices";

@implementation BBPatchCollectionController

#pragma mark -
#pragma mark Properties

@synthesize document = _document, view = _view, patchList = _patchList;

#pragma mark -
#pragma mark Initialisation

-init
{
	if (self = [super init])
	{
		[self updateList];
	}
	return self;
}

#pragma mark -
#pragma mark Patch Management

-(void) createPatchWithDefinition: (BBPatchDefinition*) definition
						  atPoint: (CGPoint) point
{
	BBLinkedPatch * patch = [[BBLinkedPatch alloc] initWithController: self
															 identity: [self->_document getUniquePatchIdentity]
														   definition: definition
															  atPoint: point];
	[self->_document addPatch: patch];
	[patch release];
}

-(void) removePatch: (BBLinkedPatch*) patch
{
	[self->_document removePatch: patch];
}


#pragma mark -
#pragma mark Patch List

+(id) patchList
{
	NSArray * paths = [[NSBundle mainBundle] pathsForResourcesOfType: @"bbpatch"
														 inDirectory: @"patches"];
	NSMutableArray * new_patches = [[NSMutableArray alloc] initWithCapacity: [paths count]];
	for (id path in paths)
	{
		[new_patches addObject: [BBPatchDocument definitionFromDocumentAtPath: path]];
	}
	
	return [new_patches autorelease];
}

#pragma mark Update List

-(void) updateList
{
	[self willChangeValueForKey: @"patchList"];
	[self->_patchList release];
	self->_patchList = [[BBPatchCollectionController patchList] retain];
	[self didChangeValueForKey: @"patchList"];
}

-(IBAction) updateList: (id) sender
{
	[self updateList];
}

#pragma mark Pasteboard

+(NSArray*) pasteboardTypes
{
	return [NSArray arrayWithObjects: 
			kBBPatchCollectionControllerIndicesPboardType,
			nil];
}

-(NSArray*) definitionsFromPasteboard: (NSPasteboard*) pboard
{
	NSData * data = [pboard dataForType: kBBPatchCollectionControllerIndicesPboardType];
	NSIndexSet * indexSet = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	return [self->_patchList arrayFromIndexSet: indexSet];
}

#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self->_patchList count];
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn
			row:(NSInteger)rowIndex
{
	NSParameterAssert(rowIndex >= 0 && rowIndex < [self->_patchList count]);
	if ([[aTableColumn identifier] isEqualToString: @"title"])
	{
		return [[self->_patchList objectAtIndex: rowIndex] title];// objectForKey: [aTableColumn identifier]];
	}
	return nil;
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes
	 toPasteboard:(NSPasteboard*)pboard
{
	[tv setDraggingSourceOperationMask: NSDragOperationCopy
							  forLocal: NO];
	[tv setDraggingSourceOperationMask: NSDragOperationCopy
							  forLocal: YES];
	
    [pboard addTypes: [NSArray arrayWithObjects:
					   kBBPatchCollectionControllerIndicesPboardType,
					   nil]
			   owner: self];
	
	[pboard setData: [NSKeyedArchiver archivedDataWithRootObject: rowIndexes]
			forType: kBBPatchCollectionControllerIndicesPboardType];
	
    return YES;
}

@end
