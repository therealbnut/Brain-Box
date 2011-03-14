//
//  NSPersistentDocumentWrapper.m
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright __MyCompanyName__ 2010 . All rights reserved.
//

#import "NSPersistentDocumentWrapper.h"
#import "NSPersistentDocument+FileWrapper.h"

/*
 This is the name of the Core Data store file contained within the document package.
 You can change this whatever you want -- the user will not see this file.
 */
NSString * const kNSPersistentDocumentWrapperStoreFileName = @"data.xml";

@implementation NSPersistentDocumentWrapper

#pragma mark -
#pragma mark URL management

/*
 Sets the on-disk location.  NSPersistentDocument's implementation is bypassed using the FileWrapperSupport category.  The persistent store coordinator is directed to use an internal URL rather than NSPersistentDocument's default (the main file URL).
 */
- (void)setFileURL:(NSURL *)fileURL
{
    NSURL *originalFileURL = [self storeURLFromPath:[[self fileURL] path]];
    if (originalFileURL != nil)
	{
        NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
        id store = [psc persistentStoreForURL:originalFileURL];
        if (store != nil)
		{
            // Switch the coordinator to an internal URL.
            [psc setURL:[self storeURLFromPath:[fileURL path]] forPersistentStore:store];
        }
    }
    [self simpleSetFileURL:fileURL];
}


/*
 Returns the URL for the wrapped Core Data store file. This appends the StoreFileName to the document's path.
 */
- (NSURL *)storeURLFromPath:(NSString *)filePath
{
    filePath = [filePath stringByAppendingPathComponent: kNSPersistentDocumentWrapperStoreFileName];
    if (filePath != nil)
	{
        return [NSURL fileURLWithPath:filePath];
    }
    return nil;
}


#pragma mark -
#pragma mark Reading (Opening)

/*
 This is a utility method called by readFromURL:ofType:error: (when the document is opened).
 All non-Core Data content is read from disk here. 
 */
- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
					 atPath:(NSString *)path 
					  error:(NSError **)error
{	
    return YES;
}


/*
 Overridden NSDocument/NSPersistentDocument method to open existing documents.
 */
- (BOOL)readFromURL:(NSURL *)absoluteURL
			 ofType:(NSString *)typeName
			  error:(NSError **)error
{
    BOOL success = NO;

    // Create a file wrapper for the document package.
    NSFileWrapper *directoryFileWrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];    

    // File wrapper for the Core Data store within the document package.
    NSFileWrapper *dataStore = [[directoryFileWrapper fileWrappers] objectForKey: kNSPersistentDocumentWrapperStoreFileName];
    if (dataStore != nil)
	{
        NSString *path = [[absoluteURL path] stringByAppendingPathComponent:[dataStore filename]];
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        // Set the document persistent store coordinator to use the internal Core Data store.
        success = [self configurePersistentStoreCoordinatorForURL:storeURL ofType:typeName 
											   modelConfiguration:nil storeOptions:nil error:error];
    }
	
    // Don't read anything else if reading the main store failed.
    if (success == YES)
	{
        // Read the other contents of the document.
        success = [self readFromFileWrapper:directoryFileWrapper atPath:[absoluteURL path] error:error];
    }
    [directoryFileWrapper release];
	
    return success;
}


#pragma mark -
#pragma mark Writing (Saving)

/*
 This is a utility method called from writeSafelyToURL:ofType:forSaveOperation:error: (when the document is saved).  This is where you prepare the non-Core Data content to be written to disk.  You create a new file wrapper for each piece of data that is to be saved to its own file (this sample has only the picture object).
 */
- (BOOL)updateFileWrapper:(NSFileWrapper *)documentFileWrapper
				   atPath:(NSString *)path
					error:(NSError **)error
{
    return YES;
}

/*
 Overridden NSDocument/NSPersistentDocument method to save documents.
 */
- (BOOL)writeSafelyToURL:(NSURL *)inAbsoluteURL
				  ofType:(NSString *)inTypeName
		forSaveOperation:(NSSaveOperationType)inSaveOperation
				   error:(NSError **)outError
{
    BOOL success = YES;
    NSFileWrapper *filewrapper = nil;
    NSURL *originalURL = [self fileURL];
    NSString *filePath = [inAbsoluteURL path];
	
    // Depending on the type of save operation:
    if (inSaveOperation == NSSaveAsOperation)
	{
        // Nothing exists at the URL: set up the directory and migrate the Core Data store.
        filewrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
        // Need to write once so there's somewhere for the store file to go.
        [filewrapper writeToFile:filePath atomically:NO updateFilenames:NO];

        // Now, the Core Data store...
        NSURL *storeURL = [self storeURLFromPath:filePath];
        NSURL *originalStoreURL = [self storeURLFromPath:[originalURL path]];

        if (originalStoreURL != nil)
		{
            // This is a "Save As", so migrate the store to the new URL.
            NSPersistentStoreCoordinator *coordinator = [[self managedObjectContext] persistentStoreCoordinator];
            id originalStore = [coordinator persistentStoreForURL:originalStoreURL];
            success = ([coordinator migratePersistentStore: originalStore 
													 toURL: storeURL
												   options: nil
												  withType: [self persistentStoreTypeForFileType: inTypeName]
													 error: outError] != nil);
        }
		else
		{
            // This is the first Save of a new document, so configure the store.
            success = [self configurePersistentStoreCoordinatorForURL:storeURL
															   ofType:inTypeName
												   modelConfiguration:nil
														 storeOptions:nil
																error:nil];
        }	
        
        [filewrapper addFileWithPath:[storeURL path]];
		
    }
	else
	{ // This is not a Save-As operation.
        // Just create a file wrapper pointing to the existing URL.
        filewrapper = [[NSFileWrapper alloc] initWithPath: filePath];
    }
    
    /*
     * Important *
     Atomicity during write is a problem that is not addressed in this sample.
     See the ReadMe for discussion.
	 */
    
    if (success == YES)
	{
        // Update the file wrapper: this writes the non-Core Data portions of the document.
        success = [self updateFileWrapper:filewrapper 
								   atPath: filePath
									error:outError];
        [filewrapper writeToFile: filePath 
					  atomically: NO
				 updateFilenames: NO];
    }

    if (success == YES)
	{
        // Save the Core Data portion of the document.
        success = [[self managedObjectContext] save:outError];
    }

    if (success == YES)
	{
        // Set the appropriate file attributes (such as "Hide File Extension")
        NSDictionary *fileAttributes = [self fileAttributesToWriteToURL: inAbsoluteURL
																 ofType: inTypeName
													   forSaveOperation: inSaveOperation
													originalContentsURL: originalURL
																  error: outError];
		NSMutableDictionary * modFileAttributes =
			[NSMutableDictionary dictionaryWithDictionary: fileAttributes];
		[modFileAttributes setObject: [NSNumber numberWithBool: NO] 
							  forKey: NSFileExtensionHidden];
        [[NSFileManager defaultManager] setAttributes: modFileAttributes
										 ofItemAtPath: [inAbsoluteURL path]
												error: outError];
    }
    [filewrapper release];

    return success;
}


#pragma mark -
#pragma mark Revert

/*
 The revert method needs to completely tear down the object graph assembled by the document. In this case, you also want to remove the persistent store manually, because NSPersistentDocument will expect the store for its coordinator to be located at the document URL (instead of inside that URL as part of the file wrapper).
 */
- (BOOL)revertToContentsOfURL:(NSURL *)inAbsoluteURL
					   ofType:(NSString *)inTypeName
						error:(NSError **)outError
{
    NSPersistentStoreCoordinator *psc = [[self managedObjectContext] persistentStoreCoordinator];
    id store = [psc persistentStoreForURL:[self storeURLFromPath:[inAbsoluteURL path]]];
    if (store)
	{
        [psc removePersistentStore: store
							 error: outError];
    }
    return [super revertToContentsOfURL: inAbsoluteURL
								 ofType: inTypeName
								  error: outError];
}

@end
