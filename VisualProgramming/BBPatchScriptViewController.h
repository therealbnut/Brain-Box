//
//  BBPatchScriptController.h
//  BrainBox2
//
//  Created by Andrew Bennett on 15/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class AGRegex;

@interface BBPatchScriptViewController : NSObject//<NSTextViewDelegate>
{
	AGRegex * _keyword;
	NSColor * _keywordColour;
	
	NSArray * _syntax;
	NSArray * _colours;
	NSTextView * _scriptView;
}

@property (readwrite, assign) IBOutlet NSTextView * scriptView;

@end
