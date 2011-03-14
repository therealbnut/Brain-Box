//
//  BBPatchCollectionView.h
//  BrainBox2
//
//  Created by Andrew Bennett on 17/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BBConnectionAnimationState.h"

@class BBPatchCollectionController;
@class BBPatchCollectionDocument;

@class BBConnection;
@class BBPatchConnectionAnimation;
@class BBLinkedPatch;

@interface BBPatchCollectionView : NSView
{
	BBPatchCollectionController * _controller;
	BBPatchCollectionDocument * _document;
	
//	BBPatchConnectionAnimation* _connection;
	NSTimer * _timer;
	NSMutableDictionary * _connectionAnimations;
	NSMutableDictionary * _patches;

	BBPatchConnectionAnimation * _draggingConnectionAnimation;
}

@property (readwrite, assign) IBOutlet BBPatchCollectionController * controller;
@property (readwrite, assign) IBOutlet BBPatchCollectionDocument * document;

-(void) startTimer;
-(void) stopTimer;

-(BOOL) upgradeTemporaryDraggingConnection: (id<NSDraggingInfo>) sender
								 withPatch: (BBLinkedPatch*) patch
									 index: (NSUInteger) index;

-(BOOL) updateTemporaryDraggingConnection: (id<NSDraggingInfo>) sender;
-(void) setTemporaryDraggingConnectionStart: (CGPoint) point;
-(void) setTemporaryDraggingConnectionEnd: (CGPoint) point;
-(void) removeTemporaryDraggingConnectionFromStart;
-(void) removeTemporaryDraggingConnectionFromEnd;

@end
