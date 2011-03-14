//
//  BBPatchDefinitionView.m
//  BrainBox2
//
//  Created by Andrew Bennett on 21/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchDefinitionView.h"
#import "BBConnectionDefinition.h"
#import "BBPatchDocument.h"
#import "BBPatchDefinition.h"

#import "NSArray+BBUtility.h"

@implementation BBPatchDefinitionView

#pragma mark -
#pragma mark Initialisation

-initWithFrame: (NSRect) frameRect
{
	if (self = [super initWithFrame: frameRect])
	{
		self->_insertionRow = -1;
		self->_insertionColumn = -1;
	}
	return self;
}

+(BOOL) canDragView
{
	return NO;
}

-(void) awakeFromNib
{
	[self registerForDraggedTypes: [BBPatchDefinition pasteboardTypes]];
}

#pragma mark Properties

-(BBPatchDocument*) document
{
	return self->_document;
}
-(void) setDocument: (BBPatchDocument*) new_document
{
	[self setDefinition: [new_document definition]];
	[self willChangeValueForKey: @"document"];
	self->_document = new_document;
	[self didChangeValueForKey: @"document"];
}

#pragma mark -
#pragma mark Events

- (BOOL)acceptsFirstResponder
{
	return YES;
}
-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}
- (BOOL)wantsPeriodicDraggingUpdates
{
	return YES;
}

#pragma mark Pasteboard and Dragging

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationCopy;
}
- (void)pasteboard: (NSPasteboard *)sender provideDataForType: (NSString *)type
{
	if ([type compare: NSPDFPboardType] == NSOrderedSame)
	{
		[self writePDFInsideRect: self.bounds
					toPasteboard: sender];
	}
	else if ([type compare: NSPostScriptPboardType] == NSOrderedSame)
	{
		[self writeEPSInsideRect: self.bounds
					toPasteboard: sender];
	}
	else if ([type compare: NSTIFFPboardType] == NSOrderedSame)
	{
		NSBitmapImageRep * image = [self bitmapImageRepForCachingDisplayInRect: [self visibleRect]];
		BOOL locked = [self lockFocusIfCanDraw];
		[self cacheDisplayInRect: [self visibleRect]
				toBitmapImageRep: image];
		if (locked) [self unlockFocus];
		[sender setData: [image TIFFRepresentation]
				forType: NSTIFFPboardType];
	}
}

-(void) clearInsertion
{
	self->_insertionRow = -1;
	self->_insertionColumn = -1;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
	NSPoint newDragLocation, localPoint;	
	BBConnectionDefinition * connection;
    NSPasteboard * pboard;
	
	
	newDragLocation = [sender draggingLocation];
	localPoint = [self convertPoint: newDragLocation
						   fromView: nil];		
	
	pboard = [sender draggingPasteboard];
	connection = [BBConnectionDefinition fromPasteboard: pboard];
	
	//containsObject
	if (connection != nil)
	{
		//[self calculateInsertionCellForPoint: localPoint];
		self->_insertionRow = [self cellRowForPoint: localPoint];
		self->_insertionColumn = [self cellColumnForPoint: localPoint];
		if (
			(self->_insertionColumn == 0 && 
			 [[self definition] isValidInput: connection]) || 
			(self->_insertionColumn == 1 &&
			 [[self definition] isValidOutput: connection])
			)
		{
			[self updateImage];
			return NSDragOperationCopy;
		}
		[self clearInsertion];
		
		return NSDragOperationNone;
	}
	
	return NSDragOperationNone;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
	[self clearInsertion];
	[self updateImage];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	BBConnectionDefinition * connection;
    NSPasteboard * pboard;
	
	pboard = [sender draggingPasteboard];
	connection = [BBConnectionDefinition fromPasteboard: pboard];
	
	if (connection == nil)
		return NO;

	if (self->_insertionColumn == 0)
	{
		[self->_document insertObject: connection
					  inInputsAtIndex: self->_insertionRow];
		[self clearInsertion];
		[self updateImage];
	}
	else if (self->_insertionColumn == 1)
	{
		[self->_document insertObject: connection
					 inOutputsAtIndex: self->_insertionRow];
		[self clearInsertion];
		[self updateImage];
	}
	
    return YES;
}

#pragma mark Drawing Overrides

-(NSUInteger) imageHash
{
	return
	(
	 [[[self definition] title] hash] ^
	 [[[self definition] inputs] hash] ^
	 [[[self definition] outputs] hash]
	 ) ^ (
		  (self->_insertionColumn+1) ^
		  (self->_insertionRow+1)
		  );
}

-(NSArray*) drawingInputArray
{
	NSMutableArray * inputs = [[[self definition] inputs] arrayByPerformingSelector: @selector(keyName)];
	if (self->_insertionColumn==0)
	{
		NSString * new_object = @" ";
		if (self->_insertionRow == -1)
		{
			[inputs addObject: new_object];
		}
		else
		{
			[inputs insertObject: new_object atIndex: self->_insertionRow];
		}
	}
	return inputs;
}

-(NSArray*) drawingOutputArray
{
	NSMutableArray * outputs	= [[[self definition] outputs] arrayByPerformingSelector: @selector(keyName)];	
	if (self->_insertionColumn==1)
	{
		NSString * new_object = @" ";
		if (self->_insertionRow == -1)
		{
			[outputs addObject: new_object];
		}
		else
		{
			[outputs insertObject: new_object atIndex: self->_insertionRow];
		}
	}
	return outputs;
}

@end
