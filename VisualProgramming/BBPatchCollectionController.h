//
//  BBPatchCollectionController.h
//  BrainBox2
//
//  Created by Andrew Bennett on 22/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BBLinkedPatch;
@class BBPatchDefinition;

@class BBPatchCollectionDocument;
@class BBPatchCollectionView;

@interface BBPatchCollectionController : NSObject//<NSTableViewDataSource>
{
	BBPatchCollectionDocument * _document;
	BBPatchCollectionView * _view;

	NSArray * _patchList;
}

@property (readwrite, assign) IBOutlet BBPatchCollectionDocument * document;
@property (readwrite, assign) IBOutlet BBPatchCollectionView * view;

@property (readonly, copy) NSArray * patchList; 

-(void) updateList;
-(IBAction) updateList: (id) sender;

-(void) createPatchWithDefinition: (BBPatchDefinition*) definition
						  atPoint: (CGPoint) point;
-(void) removePatch: (BBLinkedPatch*) patch;

-(NSArray*) definitionsFromPasteboard: (NSPasteboard*) pboard;
+(NSArray*) pasteboardTypes;

@end
