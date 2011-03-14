//
//  BBPatchDefinitionView.h
//  BrainBox2
//
//  Created by Andrew Bennett on 21/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchView.h"

@interface BBPatchDefinitionView : BBPatchView
{
	BBPatchDocument * _document;
	NSUInteger _insertionRow;
	NSUInteger _insertionColumn;
}

@property (readwrite, assign) IBOutlet BBPatchDocument * document;

@end
