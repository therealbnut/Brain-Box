//
//  NSPersistentDocumentWrapper.h
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright __MyCompanyName__ 2010 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSPersistentDocumentWrapper : NSPersistentDocument
{
}

- (NSURL *)storeURLFromPath:(NSString *)filePath;
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
					 atPath:(NSString *)path
					  error:(NSError **)error;
- (BOOL)updateFileWrapper:(NSFileWrapper*)fileWrapper
				   atPath:(NSString *)path
					error:(NSError **)error;

@end
