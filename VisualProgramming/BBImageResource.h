//
//  BBImageResource.h
//  BrainBox2
//
//  Created by Andrew Bennett on 14/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BBImageResource : NSObject

+(NSImage*) NSImageFromName: (NSString*) name;
+(CGImageRef) CGImageFromName: (NSString*) name;

@end
