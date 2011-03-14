//
//  BBPatchDefinition.m
//  BrainBox2
//
//  Created by Andrew Bennett on 21/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchDefinition.h"

#import "BBConnectionDefinition.h"

#import "NSArray+BBUtility.h"
#import "BBError.h"

NSString * const kBBPatchDefinitionDefaultTitle = @"Patch Title";

NSString * const kBBPatchDefinitionTitleKey = @"title";
NSString * const kBBPatchDefinitionInputsKey = @"inputs";
NSString * const kBBPatchDefinitionOutputsKey = @"outputs";
NSString * const kBBPatchDefinitionSourceKey = @"source";

NSString * const kBBPatchDefinitionPboardType = @"BBPatchDefinition";

@interface BBPatchDefinition (Internal)

+(NSArray*) connectionArrayFromPropertyList: (id) plist;

@end


@implementation BBPatchDefinition

+definitionFromString: (NSString*) string
{
	return [[[BBPatchDefinition alloc] initWithString: string] autorelease];
}
+definitionFromPropertyList: (id) plist
{	
	return [[[BBPatchDefinition alloc] initWithPropertyList: plist] autorelease];
}
+definitionFromData: (NSData*) data
{	
	return [NSKeyedUnarchiver unarchiveObjectWithData: data];
}

#pragma mark Initialisations

-init
{
	if (self = [super init])
	{
		self->_title = [[kBBPatchDefinitionDefaultTitle copy] retain];
		self->_inputs = [[NSMutableArray array] retain];
		self->_outputs = [[NSMutableArray array] retain];
	}
	return self;
}
-initWithPropertyList: (id) plist
{
	if (self = [super init])
	{
		id new_title   = [plist objectForKey: kBBPatchDefinitionTitleKey];
		id new_inputs  = [BBPatchDefinition connectionArrayFromPropertyList: [plist objectForKey: kBBPatchDefinitionInputsKey]];
		id new_outputs = [BBPatchDefinition connectionArrayFromPropertyList: [plist objectForKey: kBBPatchDefinitionOutputsKey]];

		self->_title   = [[new_title copy] retain];
		self->_inputs  = [[new_inputs mutableCopy] retain];
		self->_outputs = [[new_outputs mutableCopy] retain];
	}
	return self;
}

-initWithString: (NSString*) string
{
	if (self = [super init])
	{
		NSPropertyListFormat format;
		NSString * serializationError = nil;
		
		if (string == nil || [string length] == 0)
		{
			[self autorelease];
			return nil;
		}
		
		id plist = [NSPropertyListSerialization propertyListFromData: [string dataUsingEncoding: NSUTF8StringEncoding]
													mutabilityOption: NSPropertyListImmutable
															  format: &format
													errorDescription: &serializationError];
		if (serializationError != nil || ![plist isKindOfClass: [NSDictionary class]])
		{
			NSLog(@"BBConnectionDefinition initWithString error: %@ (%@)", serializationError, string);
			[self autorelease];
			return nil;
		}

		id new_title   = [plist objectForKey: kBBPatchDefinitionTitleKey];
		id new_inputs  = [BBPatchDefinition connectionArrayFromPropertyList: [plist objectForKey: kBBPatchDefinitionInputsKey]];
		id new_outputs = [BBPatchDefinition connectionArrayFromPropertyList: [plist objectForKey: kBBPatchDefinitionOutputsKey]];
		
		self->_title   = [[new_title copy] retain];
		self->_inputs  = [[new_inputs mutableCopy] retain];
		self->_outputs = [[new_outputs mutableCopy] retain];		
	}
	return self;
}

-initWithCoder: (NSCoder*) coder
{
	if (self = [super init])
	{
		self->_title = [[coder decodeObject] retain];
		self->_source = [[coder decodeObject] retain];
		self->_inputs = [[coder decodeObject] retain];
		self->_outputs = [[coder decodeObject] retain];
	}
	return self;
}

-(void) dealloc
{
	[self->_title release];
	[self->_inputs release];
	[self->_outputs release];
	[self->_source release];
	[super dealloc];
}

-(void) encodeWithCoder: (NSCoder*) coder
{
	[coder encodeObject: self->_title];
	[coder encodeObject: self->_source];
	[coder encodeObject: self->_inputs];
	[coder encodeObject: self->_outputs];
}

#pragma mark Encoding

-(id) asPropertyList
{
	NSDictionary * plist;
	plist = [[NSDictionary alloc] initWithObjectsAndKeys:
			 self->_title, kBBPatchDefinitionTitleKey,
			 [self->_inputs arrayByPerformingSelector: @selector(asPropertyList)], kBBPatchDefinitionInputsKey,
			 [self->_outputs arrayByPerformingSelector: @selector(asPropertyList)], kBBPatchDefinitionOutputsKey,
			 self->_source, kBBPatchDefinitionSourceKey,
			 nil];
	return [plist autorelease];
}

-(NSString*) encodeAsString
{
	id plist;
	NSString * serializationError = nil;
	NSData * data;
	
	plist = [self asPropertyList];
	data = [NSPropertyListSerialization dataFromPropertyList: plist
													  format: NSPropertyListXMLFormat_v1_0
											errorDescription: &serializationError];
	if (serializationError != nil)
	{
		NSLog(@"BBPatchDocument encodeAsString error: %@", serializationError);
		return nil;
	}
	return [[[NSString alloc] initWithData: data
								  encoding: NSUTF8StringEncoding] autorelease];
}

-(NSData*) encodeAsData
{
	return [NSKeyedArchiver archivedDataWithRootObject: self];
}

#pragma mark Pasteboard

+(NSArray*) pasteboardTypes
{
	return [NSArray arrayWithObjects:
			NSStringPboardType,
			kBBPatchDefinitionPboardType,
			nil];
}

+fromPasteboard: (NSPasteboard*) pboard
{
	BBPatchDefinition * definition = nil;
	
    if ([[pboard types] containsObject: kBBPatchDefinitionPboardType])
	{
		//		NSLog(@"%@", [pboard dataForType: kBBPatchDefinitionPboardType]);
		definition = [BBPatchDefinition definitionFromData:
					  [pboard dataForType: kBBPatchDefinitionPboardType]];
    }
	else if ([[pboard types] containsObject: NSStringPboardType])
	{
		definition = [BBPatchDefinition definitionFromString:
					  [pboard stringForType: NSStringPboardType]];
    }	
	
	return definition;
}

-(void) storeOnPasteboard: (NSPasteboard*) pboard
{
    [pboard declareTypes: [BBPatchDefinition pasteboardTypes]
				   owner: self];	
	[pboard setData: [self encodeAsData]
			forType: kBBPatchDefinitionPboardType];
	[pboard setString: [self encodeAsString]
			  forType: NSStringPboardType];	
}

- (void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)pboardType
{
	if ([pboardType compare: kBBPatchDefinitionPboardType] == NSOrderedSame)
	{
		[pboard setData: [self encodeAsData]
				forType: kBBPatchDefinitionPboardType];
    }
	else if ([pboardType compare: NSStringPboardType] == NSOrderedSame)
	{
		[pboard setString: [self encodeAsString]
				  forType: NSStringPboardType];
	}
}

#pragma mark -
#pragma mark Properties

-(void) setInterfaceFromPropertyList: (id) plist
{
	id new_inputs  = [BBPatchDefinition connectionArrayFromPropertyList: [plist objectForKey: kBBPatchDefinitionInputsKey]];
	id new_outputs = [BBPatchDefinition connectionArrayFromPropertyList: [plist objectForKey: kBBPatchDefinitionOutputsKey]];
	
	[self setTitle: [plist objectForKey: kBBPatchDefinitionTitleKey]];
	[self setInputs: new_inputs];
	[self setOutputs: new_outputs];
}
-(id) interfaceAsPropertyList
{
	NSDictionary * plist;
	plist = [[NSDictionary alloc] initWithObjectsAndKeys:
			 self->_title, kBBPatchDefinitionTitleKey,
			 [self->_inputs arrayByPerformingSelector: @selector(asPropertyList)], kBBPatchDefinitionInputsKey,
			 [self->_outputs arrayByPerformingSelector: @selector(asPropertyList)], kBBPatchDefinitionOutputsKey,
			 nil];
	return [plist autorelease];	
}

#pragma mark Connections

+(NSArray*) connectionArrayFromPropertyList: (id) plist
{
	NSMutableArray * new_inputs = [NSMutableArray arrayWithCapacity: [plist count]];
	for (id definition in plist)
	{
		id connection = [BBConnectionDefinition connectionFromPropertyList: definition];
		if (!connection || [new_inputs containsObject: connection])
			return nil;
		[new_inputs addObject: connection];
	}
	return new_inputs;
}

#pragma mark Get Input and Output Property Lists

-(id) inputsPropertyList
{
	NSMutableArray * list = [NSMutableArray arrayWithCapacity: [self->_inputs count]];
	for (id definition in self->_inputs)
		[list addObject: [definition asPropertyList]];
	return list;
}
-(id) outputsPropertyList
{
	NSMutableArray * list = [NSMutableArray arrayWithCapacity: [self->_outputs count]];
	for (id definition in self->_outputs)
		[list addObject: [definition asPropertyList]];
	return list;
}

#pragma mark Set Inputs and Outputs from Property Lists

-(void) setInputsFromPropertyList: (id) plist
{
	id new_inputs = [BBPatchDefinition connectionArrayFromPropertyList: plist];
	[self willChangeValueForKey: @"inputs"];
//	[[self undoManager] registerUndoWithTarget: self
//									  selector: @selector(setInputs:) 
//										object: [[self->_inputs copy] autorelease]];	
	[self->_inputs release];
	self->_inputs = [new_inputs mutableCopy];
	[self didChangeValueForKey: @"inputs"];
}

-(void) setOutputsFromPropertyList: (id) plist
{
	id new_outputs = [BBPatchDefinition connectionArrayFromPropertyList: plist];
	[self willChangeValueForKey: @"outputs"];
//	[[self undoManager] registerUndoWithTarget: self
//									  selector: @selector(setOutputs:) 
//										object: [[self->_outputs copy] autorelease]];
	[self->_outputs release];
	self->_outputs = [new_outputs mutableCopy];
	[self didChangeValueForKey: @"outputs"];
}

#pragma mark Source

@synthesize source = _source;

//-(NSString*) source
//{
//	return [[self->_source retain] autorelease];
//}
//-(void) setSource: (NSString *) newSource
//{
//	if (![self->_source isEqualToString: newSource])
//	{
//		[self willChangeValueForKey: @"source"];
//		[[self undoManager] registerUndoWithTarget: self 
//										  selector: @selector(setSource:) 
//											object: self->_source];
//		[self->_source release];
//		self->_source = [[newSource copy] retain];
//		[self didChangeValueForKey: @"source"];
//	}
//}

#pragma mark Title

@synthesize title = _title;

//-(NSString*) title
//{
//	return [[self->_title retain] autorelease];
//}
//-(void) setTitle: (NSString *) newTitle
//{
//	if (![self->_title isEqualToString: newTitle])
//	{
//		//		NSLog(@"setTitle: %@", newTitle);
//		[self willChangeValueForKey: @"title"];
//		[[self undoManager] registerUndoWithTarget: self
//										  selector: @selector(setTitle:) 
//											object: self->_title];
//		[self->_title release];
//		self->_title = [[newTitle copy] retain];
//		[self didChangeValueForKey: @"title"];
//	}
//}

#pragma mark Inputs and Outputs

@synthesize inputs = _inputs, outputs = _outputs;

//-(NSMutableArray*) inputs
//{
//	return [[self->_inputs retain] autorelease];
//}
//- (void)setInputs: (NSMutableArray*) newInputs
//{
//	if (newInputs != self->_inputs)
//	{
//		[self willChangeValueForKey: @"inputs"];
//		[[self undoManager] registerUndoWithTarget: self
//										  selector: @selector(setInputs:) 
//											object: [[self->_inputs copy] autorelease]];
//		[self->_inputs release];
//		self->_inputs = [newInputs mutableCopy];
//		[self didChangeValueForKey: @"inputs"];
//	}
//	else NSLog(@"failed due to samedness!");
//}
//
//-(NSMutableArray*) outputs
//{
//	return [[self->_outputs retain] autorelease];
//}
//- (void)setOutputs: (NSMutableArray*) newOutputs
//{
//	if (newOutputs != self->_outputs)
//	{
//		[self willChangeValueForKey: @"outputs"];
//		[[self undoManager] registerUndoWithTarget: self
//										  selector: @selector(setOutputs:) 
//											object: [[self->_outputs copy] autorelease]];
//		[self->_outputs release];
//		self->_outputs = [newOutputs mutableCopy];
//		[self didChangeValueForKey: @"outputs"];
//	}
//	else NSLog(@"failed due to samedness!");
//}

-(BOOL) isValidInput: (BBConnectionDefinition *) definition
{
	if (!definition || ![definition keyName] || ![definition type])
		return NO;
	return ![self->_inputs containsObject: definition];
}
-(BOOL) isValidOutput: (BBConnectionDefinition *) definition
{
	if (!definition || ![definition keyName] || ![definition type])
		return NO;
	return ![self->_outputs containsObject: definition];
}

- (void)insertObject: (BBConnectionDefinition *) input
	 inInputsAtIndex: (NSUInteger) index
{
	[self willChangeValueForKey: @"inputs"];
//	[[self undoManager] registerUndoWithTarget: self
//									  selector: @selector(setInputs:) 
//										object: [[self->_inputs copy] autorelease]];
	if (index == -1 || index >= [self->_inputs count])
	{
		[self->_inputs addObject: input];
	}
	else
	{
		[self->_inputs insertObject: input
							atIndex: index];
	}
	[self didChangeValueForKey: @"inputs"];
}
- (void)insertObject: (BBConnectionDefinition *) output
	inOutputsAtIndex: (NSUInteger) index
{
	[self willChangeValueForKey: @"outputs"];
//	[[self undoManager] registerUndoWithTarget: self
//									  selector: @selector(setOutputs:) 
//										object: [[self->_outputs copy] autorelease]];
	if (index == -1 || index >= [self->_outputs count])
	{
		[self->_outputs addObject: output];
	}
	else
	{
		[self->_outputs insertObject: output
							 atIndex: index];
	}	
	[self didChangeValueForKey: @"outputs"];
}

//#pragma mark Add Inputs and Outputs
//
//-(IBAction) addInput: (id) sender
//{
//	id newInput  = [[BBConnectionDefinition alloc] init];
//	//	id changeSet = [NSSet setWithObject: newInput];
//	[self willChangeValueForKey: @"inputs"];
//	//				withSetMutation: NSKeyValueUnionSetMutation
//	//				   usingObjects: changeSet];
//	[[self undoManager] registerUndoWithTarget: self
//									  selector: @selector(setInputs:) 
//										object: [[self->_inputs copy] autorelease]];
//	[self->_inputs addObject: newInput];
//	[self didChangeValueForKey: @"inputs"];
//	//			   withSetMutation: NSKeyValueUnionSetMutation
//	//				  usingObjects: changeSet];
//	[newInput release];
//}
//
//-(IBAction) addOutput: (id) sender
//{
//	id newOutput  = [[BBConnectionDefinition alloc] init];
//	//	id changeSet = [NSSet setWithObject: newOutput];
//	[self willChangeValueForKey: @"outputs"];
//	//				withSetMutation: NSKeyValueUnionSetMutation
//	//				   usingObjects: changeSet];
//	[[self undoManager] registerUndoWithTarget: self
//									  selector: @selector(setOutputs:) 
//										object: [[self->_outputs copy] autorelease]];
//	[self->_outputs addObject: newOutput];
//	[self didChangeValueForKey: @"outputs"];
//	//			   withSetMutation: NSKeyValueUnionSetMutation
//	//				  usingObjects: changeSet];
//	[newOutput release];
//}

@end
