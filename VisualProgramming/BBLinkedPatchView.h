//
//  BBLinkedPatchView.h
//  BrainBox2
//
//  Created by Andrew Bennett on 22/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchView.h"

@class BBLinkedPatch;

@interface BBLinkedPatchView : BBPatchView
{
	BBLinkedPatch * _patch;

	BOOL     _dragging;
	NSPoint  _dragPosition;
}

-initWithPatch: (BBLinkedPatch*) patch;

@end
