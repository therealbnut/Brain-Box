//
//  BBSimulationDocument.h
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSDocumentWrapper.h"

@class BBLinkedPatch;
@class BBPatchDefinition;

extern NSString * const kBBPatchCollectionPatchAddedNotification;
extern NSString * const kBBPatchCollectionPatchRemovedNotification;

@interface BBPatchCollectionDocument : NSDocumentWrapper
{
	NSUInteger _patchIdentity;
	NSMutableDictionary * _patches;
}

@property (readonly) NSDictionary * patches;

-(NSUInteger) getUniquePatchIdentity;

-(void) addPatch: (BBLinkedPatch*) patch;
-(void) removePatch: (BBLinkedPatch*) patch;

-(BBLinkedPatch*) patchForIdentity: (NSUInteger) identity;

@end
