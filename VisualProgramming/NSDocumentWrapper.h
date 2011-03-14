//
//  NSDocumentWrapper.h
//  BrainBox2
//
//  Created by Andrew Bennett on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSDocumentWrapper : NSDocument
{
}

//- (NSURL *)storeURLFromPath:(NSString *)filePath;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
					 atPath:(NSString *)path
					  error:(NSError **)error;
- (BOOL)updateFileWrapper:(NSFileWrapper*)fileWrapper
				   atPath:(NSString *)path
					error:(NSError **)error;

@end
