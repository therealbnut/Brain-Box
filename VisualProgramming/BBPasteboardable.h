//
//  BBPasteboardable.h
//  BrainBox2
//
//  Created by Andrew Bennett on 22/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol BBPasteboardable

+(NSArray*) pasteboardTypes;
+fromPasteboard: (NSPasteboard*) pboard;
-(void) storeOnPasteboard: (NSPasteboard*) pasteboard;

@end
