//
//  BBLinkedPatchView.m
//  BrainBox2
//
//  Created by Andrew Bennett on 22/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBLinkedPatchView.h"

#import "BBPatchCollectionView.h"

#import "BBPatchDefinition.h"
#import "BBConnectionDefinition.h"

#import "BBLinkedPatch.h"
#import "BBConnection.h"

#import "BBImageResource.h"

@implementation BBLinkedPatchView

-initWithPatch: (BBLinkedPatch*) patch
{
	if (self = [super initWithFrame: NSMakeRect(0, 0, 128.0, 128.0)])
	{
		self->_patch = [patch retain];
		[self setDefinition: [patch definition]];
		[self updateImage];

		[self registerForDraggedTypes: [BBConnection pasteboardTypes]];
	}
	return self;
}
-(void) dealloc
{
	[self->_patch release];
	[super dealloc];
}

-(NSPoint) centrePointForSize: (NSSize) size
					oldCentre: (NSPoint) oldCentre
{
	CGPoint newPoint = [self->_patch center];
	if (newPoint.x < size.width * 0.5)  newPoint.x = size.width * 0.5;
	if (newPoint.y < size.height * 0.5) newPoint.y = size.height * 0.5;
	return NSPointFromCGPoint(newPoint);
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

-(NSRect) viewDragStartRegion
{
	NSRect region = NSInsetRect([self bounds], kPatchShadowSize, kPatchShadowSize);
	//	region.origin.y    = NSMaxY(region);
	//	region.size.height = kPatchTitleTextSize + kPatchInnerPadding;
	//	region.origin.y   -= region.size.height;
	return region;
}

-(BOOL) isPointInViewDragStartRegion: (NSPoint) point
{
    if (!NSPointInRect(point, [self viewDragStartRegion]))
		return NO;
	
    return YES;
}

#pragma mark -
#pragma mark Cell Dragging

-(BOOL) dragCellWithEvent: (NSEvent *)theEvent
					  row: (NSUInteger) row
				   column: (NSUInteger) col
{
	NSPoint windowPoint = [theEvent locationInWindow];
	NSPoint localPoint  = [self convertPoint: windowPoint
									fromView: nil];
	
	NSPasteboard * dragPasteboard;
	dragPasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	if (col == 0)
	{
		[[BBConnection connectionFromPatch: 0 key: 0
								   toPatch: [self->_patch identity] key: row] storeOnPasteboard: dragPasteboard];
	}
	else
	{
		[[BBConnection connectionFromPatch: [self->_patch identity] key: row
								   toPatch: 0 key: 0] storeOnPasteboard: dragPasteboard];
	}

#pragma TODO fix me
	NSImage * dragImage = [BBImageResource NSImageFromName: @"Connection"];
	NSSize dragImageSize = [dragImage size];
	localPoint = NSMakePoint(localPoint.x-dragImageSize.width * 0.5, localPoint.y-dragImageSize.height * 0.5);
	[self dragImage: dragImage
				 at: localPoint
			 offset: NSZeroSize
			  event: theEvent
		 pasteboard: dragPasteboard
			 source: self
		  slideBack: YES];
	return YES;
}

#pragma mark -
#pragma mark Dragging

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
	NSPasteboard * pboard = [sender draggingPasteboard];
	
	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{
		BBConnection * pasteBoardConnection;
		BBPatchCollectionView * collectionView;
		NSUInteger row, column;
		NSPoint localPoint;
		
		collectionView = (BBPatchCollectionView*) [self superview];
		pasteBoardConnection = [BBConnection fromPasteboard: pboard];
		localPoint = [self convertPoint: [sender draggingLocation]
							   fromView: nil];
		
		[collectionView updateTemporaryDraggingConnection: sender];
		
		row = [self cellRowForPoint: localPoint];
		column = [self cellColumnForPoint: localPoint];
		
		if ([pasteBoardConnection from] == 0)
		{
			if (row != -1 && column == 1)
			{
				CGPoint point = [self outputPointForIndex: row];
				[collectionView setTemporaryDraggingConnectionStart: point];
				return NSDragOperationCopy;
			}
		}
		if ([pasteBoardConnection to] == 0)
		{
			if (row != -1 && column == 0)
			{
				CGPoint point = [self inputPointForIndex: row];
				[collectionView setTemporaryDraggingConnectionEnd: point];
				return NSDragOperationCopy;
			}			
		}
		return NSDragOperationNone;
	}
	return NSDragOperationNone;
}
- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	NSPasteboard * pboard = [sender draggingPasteboard];
	
	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{	
		BBConnection * pasteBoardConnection;
		BBPatchCollectionView * collectionView;

		pasteBoardConnection = [BBConnection fromPasteboard: pboard];
		collectionView = (BBPatchCollectionView*) [self superview];

		if ([pasteBoardConnection from] == 0)
			[collectionView removeTemporaryDraggingConnectionFromStart];
		if ([pasteBoardConnection to] == 0)
			[collectionView removeTemporaryDraggingConnectionFromEnd];
	}
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard * pboard;
	NSPoint localPoint;
	
	pboard = [sender draggingPasteboard];
	localPoint = [self convertPoint: [sender draggingLocation]
						   fromView: nil];
	
	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{
//		BBConnection * connection = [BBConnection fromPasteboard: pboard];
//		NSLog(@"attach me: %@", connection);
		[(BBPatchCollectionView*)[self superview] upgradeTemporaryDraggingConnection: sender
																		   withPatch: self->_patch
																			   index: [self cellRowForPoint: localPoint]];
#pragma TODO attach me!

		return NO;
	}
	
    return NO;
}

#pragma mark -
#pragma mark Mouse Events

- (void)mouseDown:(NSEvent *)theEvent
{
	self->_dragPosition = [theEvent locationInWindow];
	NSPoint localPoint = [self convertPoint: self->_dragPosition
								   fromView: nil];
	
	if ([self isPointInViewDragStartRegion: localPoint])
	{
		BOOL wantCellDrag = NO;

		NSUInteger row = [self cellRowForPoint: localPoint];
		NSUInteger column = [self cellColumnForPoint: localPoint];
		if (row != -1 && column < 2)
		{
 			wantCellDrag = [self dragCellWithEvent: theEvent
											   row: row
											column: column];
		}
		self->_dragging = !wantCellDrag;
	}
}
- (void)mouseUp:(NSEvent *)theEvent
{
	self->_dragging = NO;
}

-(void) moveIfAble: (NSSize) offset
{
	if (self->_dragging == NO)
	{
		NSPoint newOrigin = [self frame].origin;
		newOrigin.x = (newOrigin.x + offset.width  >= -kPatchShadowSize) ? newOrigin.x + offset.width  : -kPatchShadowSize;
		newOrigin.y = (newOrigin.y + offset.height >= -kPatchShadowSize) ? newOrigin.y + offset.height : -kPatchShadowSize;
		[self setFrameOrigin: newOrigin];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (self->_dragging)
	{
		NSPoint newDragLocation = [theEvent locationInWindow];
		NSPoint thisOrigin = [self frame].origin;
		
		double dx = (newDragLocation.x - self->_dragPosition.x);
		double dy = (newDragLocation.y - self->_dragPosition.y);
		double r = 0.0;
		
		if (thisOrigin.x + dx < -kPatchShadowSize) {dx += kPatchShadowSize; r += dx*dx; dx = -kPatchShadowSize-thisOrigin.x;}
		if (thisOrigin.y + dy < -kPatchShadowSize) {dy += kPatchShadowSize; r += dy*dy; dy = -kPatchShadowSize-thisOrigin.y;}
		
		thisOrigin.x += dx;
		thisOrigin.y += dy;
		self->_dragPosition.x += dx;
		self->_dragPosition.y += dy;
		
		if (r > 256.0)
		{
			NSPasteboard * dragPasteboard;
			dragPasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
			[dragPasteboard declareTypes: [NSArray arrayWithObjects:
										   NSPDFPboardType,
										   NSPostScriptPboardType,
										   NSTIFFPboardType,
										   nil]
								   owner: self];
			[dragPasteboard addTypes: [BBPatchDefinition pasteboardTypes]
							   owner: [self definition]];

			if (dragPasteboard != nil)
			{
				NSSize dragImageSize = self.bounds.size; 
				NSImage* dragImage = [[NSImage alloc] initWithSize: dragImageSize];
				
				NSData* pdfData = [self dataWithPDFInsideRect: self.bounds];
				NSImage* dragImageBase = [[NSImage alloc] initWithData: pdfData]; 
				[dragImage lockFocus];
				[dragImageBase dissolveToPoint: NSZeroPoint fraction: .5];
				[dragImage unlockFocus];
				[dragImageBase release];
				
				NSPoint dragOffset = [self convertPoint: newDragLocation
											   fromView: nil];
				dragOffset.x = 0.5 * dragOffset.x;
				dragOffset.y = 0.5 * dragOffset.y;
				
				dragImageSize.width  *= 0.5;
				dragImageSize.height *= 0.5;
				
				[dragImage setScalesWhenResized: YES];
				[dragImage setSize: dragImageSize];
				
				[self dragImage: dragImage
							 at: dragOffset
						 offset: NSZeroSize
						  event: theEvent
					 pasteboard: dragPasteboard
						 source: self
					  slideBack: YES];
				[dragImage release];
				self->_dragging = NO;
			}
		}
		
		[self setFrameOrigin: thisOrigin];
	}
}

-(void) moveUp: (id)sender {[self moveIfAble: NSMakeSize(0, 16)];}
-(void) moveDown: (id)sender {[self moveIfAble: NSMakeSize(0, -16)];}
-(void) moveLeft: (id)sender {[self moveIfAble: NSMakeSize(-16, 0)];}
-(void) moveRight: (id)sender {[self moveIfAble: NSMakeSize(16, 0)];}
-(void) deleteBackward:(id)sender
{
	NSLog(@"delete");
}

@end
