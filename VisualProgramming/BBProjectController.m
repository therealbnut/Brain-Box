//
//  BBProjectController.m
//  BrainBox2
//
//  Created by Andrew Bennett on 10/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBProjectController.h"

#import "BBPatchCollectionDocument.h"
#import "BBPatchDocument.h"

NSString * const kBBSimulationDocumentTypeName = @"BBPatchCollectionDocumentTypeName";
NSString * const kPatchDocumentTypeName        = @"BBPatchDocumentTypeName";

@implementation BBProjectController

- (NSString *)defaultType
{
	return kBBSimulationDocumentTypeName;
}

-(IBAction) newPatchDocument: (id) sender
{
	NSError * error;
	NSDocumentController * controller = [NSDocumentController sharedDocumentController];
	
	id newDocument = [controller makeUntitledDocumentOfType: kPatchDocumentTypeName
													  error: &error];
	[newDocument makeWindowControllers];
	[controller addDocument: newDocument];
	[newDocument showWindows];
//	NSLog(@"[newDocument retainCount]: %d", [newDocument retainCount]);
}

//- (id)makeDocumentWithContentsOfURL:(NSURL *)absoluteURL
//							 ofType:(NSString *)typeName
//							  error:(NSError **)outError
//{
//	id currentDocument = [self currentDocument];
//	id newDocument = [super makeDocumentWithContentsOfURL: absoluteURL
//												   ofType: typeName
//													error: outError];
//	if (currentDocument!=nil && [currentDocument isKindOfClass: [BBSimulationDocument class]] &&
//		newDocument!=nil && [newDocument isKindOfClass: [BBPatchDocument class]])
//	{
//		BBSimulationDocument * currentSimulation = currentDocument;
//		[currentSimulation addPatchDocument: newDocument];
//	}	
//	return newDocument;
//}
//
//-(id) makeUntitledDocumentOfType:(NSString *)typeName
//						   error:(NSError **)outError
//{
//	id currentDocument = [self currentDocument];
//	id newDocument = [super makeUntitledDocumentOfType: typeName
//												 error: outError];
//	if (currentDocument!=nil && [currentDocument isKindOfClass: [BBSimulationDocument class]] &&
//		newDocument!=nil && [newDocument isKindOfClass: [BBPatchDocument class]])
//	{
//	}	
//	return newDocument;
//}

@end
