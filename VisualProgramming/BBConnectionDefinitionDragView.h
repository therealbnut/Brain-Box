//
//  BBConnectionDefinitionDragView.h
//  BrainBox2
//
//  Created by Andrew Bennett on 13/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BBConnectionDefinition;

@interface BBConnectionDefinitionDragView : NSView
{
	BBConnectionDefinition * _definition;
}

@property (readwrite, retain) IBOutlet BBConnectionDefinition* definition;

@end
