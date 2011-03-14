//
//  BBPatchCollectionView.m
//  BrainBox2
//
//  Created by Andrew Bennett on 17/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchCollectionView.h"

#import "BBPatchCollectionController.h"

#import "BBLinkedPatchView.h"
#import "BBLinkedPatch.h"

#import "BBPatchDefinition.h"
#import "BBPatchCollectionDocument.h"
#import "BBConnection.h"

#import "BBImageResource.h"

@implementation BBPatchCollectionView

#pragma mark Properties

@synthesize document = _document;
@synthesize controller = _controller;

#pragma mark Timing

-(void) startTimer
{
	if (self->_timer == nil)
	{
		self->_timer = [NSTimer timerWithTimeInterval: 1.0/30.0
											   target: self
											 selector: @selector(update:)
											 userInfo: self->_timer
											  repeats: YES];
		[[NSRunLoop mainRunLoop] addTimer: self->_timer forMode: NSDefaultRunLoopMode];
		[[NSRunLoop mainRunLoop] addTimer: self->_timer forMode: NSEventTrackingRunLoopMode];
		[self->_timer retain];
	}
}
-(void) stopTimer
{
	if (self->_timer != nil)
	{
		[self->_timer invalidate];
		[self->_timer release];
		self->_timer = nil;
	}
}

- (id)initWithFrame:(NSRect)frame
{
    if (self = [super initWithFrame:frame])
	{
		self->_timer = nil;
		self->_connectionAnimations = [[NSMutableSet alloc] init];
		self->_patches = [[NSMutableDictionary alloc] init];
//		self->_connection  = [[BBPatchConnectionAnimation alloc] initWithStart: NSMakePoint(150, 250)
//																		   end: NSMakePoint(250, 250)];
    }
    return self;
}
-(void) dealloc
{
	[self stopTimer];
	[self->_connectionAnimations release];
	[self->_patches release];
//	[self->_connection release];

	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[super dealloc];
}


-(void) awakeFromNib
{
	[[self window] setAcceptsMouseMovedEvents: YES];
	[self registerForDraggedTypes: [BBPatchCollectionController pasteboardTypes]];
	[self registerForDraggedTypes: [BBConnection pasteboardTypes]];

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(patchAdded:)
												 name: kBBPatchCollectionPatchAddedNotification
											   object: self->_document];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(patchRemoved:)
												 name: kBBPatchCollectionPatchRemovedNotification
											   object: self->_document];
	
	[super awakeFromNib];
}

#pragma mark Event Desires

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

#pragma mark Updating

-(void) mouseMoved:(NSEvent *)theEvent
{
//	NSPoint point = [theEvent locationInWindow];
//	NSPoint localPoint = [self convertPoint: point
//								   fromView: nil];
//	[self->_connectionAnimations addObject: self->_connection];
//	[self->_connection setEnd: localPoint];
//	[self startTimer];
}

-(void) update: (NSTimer*) timer
{
	BOOL needsDisplay;
//	BBPatchConnectionAnimation * animation;
//	BBConnection * connection;
	
	BBConnection* connections;
	BBPatchConnectionAnimation* animations;

	[self->_connectionAnimations getObjects: &animations
									andKeys: &connections];
	NSUInteger count = [self->_connectionAnimations count];

	for (NSUInteger i=0; i<count; ++i)
	{
//		animation  = &animations[i];
//		connection = &connections[i];

		needsDisplay = [&animations[i] update: [timer timeInterval]
									   inView: self];
		if (!needsDisplay)
		{
			if (self->_draggingConnectionAnimation == &animations[i])
			{
				[self->_draggingConnectionAnimation release];
				self->_draggingConnectionAnimation = nil;
			}
			[self->_connectionAnimations removeObjectForKey: &connections[i]];
		}
	}
	if ([self->_connectionAnimations count] == 0)
	{
		[self stopTimer];
	}
}

#pragma mark Dragging

//- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
//{
//	NSPasteboard * pboard = [sender draggingPasteboard];
//
//	if ([pboard availableTypeFromArray: [BBPatchCollectionController pasteboardTypes]] != nil)
//		return NSDragOperationCopy;
//	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
//		return NSDragOperationCopy;
//	return NSDragOperationNone;
//}

-(BOOL) createTemporaryDraggingConnection
{
	if (self->_draggingConnectionAnimation != nil)
		return NO;

	self->_draggingConnectionAnimation = [[BBPatchConnectionAnimation alloc] initWithStart: NSZeroPoint
																					   end: NSZeroPoint];
	[self startTimer];
	return YES;
}
-(void) setTemporaryDraggingConnectionStart: (CGPoint) point
{
	[self createTemporaryDraggingConnection];
	[self->_draggingConnectionAnimation setStart: NSPointFromCGPoint(point)];
	[self->_draggingConnectionAnimation removeSnapBack];
}
-(void) setTemporaryDraggingConnectionEnd: (CGPoint) point
{
	[self createTemporaryDraggingConnection];
	[self->_draggingConnectionAnimation setEnd: NSPointFromCGPoint(point)];
	[self->_draggingConnectionAnimation removeSnapBack];
}
-(void) removeTemporaryDraggingConnection
{
	if (self->_draggingConnectionAnimation != nil)
	{
		[self->_draggingConnectionAnimation setNeedsRedisplayInView: self];
		[self->_draggingConnectionAnimation release];
		self->_draggingConnectionAnimation = nil;
	}
}
-(void) removeTemporaryDraggingConnectionFromStart
{
	if (self->_draggingConnectionAnimation != nil)
	{
		[self->_draggingConnectionAnimation snapBackStart];
	}
}
-(void) removeTemporaryDraggingConnectionFromEnd
{
	if (self->_draggingConnectionAnimation != nil)
	{
		[self->_draggingConnectionAnimation snapBackEnd];
	}
}

-(BOOL) updateTemporaryDraggingConnection:  (id<NSDraggingInfo>)sender
{
	NSPasteboard * pboard = [sender draggingPasteboard];

	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{
		BBConnection * pasteBoardConnection;
		NSPoint localPoint;
		
		pasteBoardConnection = [BBConnection fromPasteboard: pboard];
		localPoint = [self convertPoint: [sender draggingLocation]
							   fromView: nil];
		if ([self createTemporaryDraggingConnection])
		{
			if ([pasteBoardConnection from] != 0)
			{
				NSNumber * identity = [NSNumber numberWithInteger: [pasteBoardConnection from]];
				BBLinkedPatchView * patch = [self->_patches objectForKey: identity];
				CGPoint point = [patch outputPointForIndex: [pasteBoardConnection output]];
				[self setTemporaryDraggingConnectionStart: point];
			}
			if ([pasteBoardConnection to] != 0)
			{
				NSNumber * identity = [NSNumber numberWithInteger: [pasteBoardConnection to]];
				BBLinkedPatchView * patch = [self->_patches objectForKey: identity];
				CGPoint point = [patch inputPointForIndex: [pasteBoardConnection input]];
				[self setTemporaryDraggingConnectionEnd: point];
			}
		}
		if ([pasteBoardConnection from] == 0)
			[self setTemporaryDraggingConnectionStart: NSPointToCGPoint(localPoint)];
		if ([pasteBoardConnection to] == 0)
			[self setTemporaryDraggingConnectionEnd: NSPointToCGPoint(localPoint)];

		return YES;
	}
	return NO;
}

#pragma mark Upgrade Temporary Connection

-(BOOL) upgradeTemporaryDraggingConnection: (id<NSDraggingInfo>)sender
								 withPatch: (BBLinkedPatch*) new_patch
									 index: (NSUInteger) index
{
	NSPasteboard * pboard = [sender draggingPasteboard];
	
	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{
		BBConnection * pasteBoardConnection;
		BBConnection * newConnection = nil;
		NSPoint localPoint;

		pasteBoardConnection = [BBConnection fromPasteboard: pboard];
		localPoint = [self convertPoint: [sender draggingLocation]
							   fromView: nil];

		if ([self createTemporaryDraggingConnection])
		{
			if ([pasteBoardConnection from] != 0)
			{
				newConnection = [[BBConnection alloc] initFromPatch: [pasteBoardConnection from]
																key: [pasteBoardConnection output]
															toPatch: [new_patch identity]
																key: index];
			}
			else if ([pasteBoardConnection to] != 0)
			{
				newConnection = [[BBConnection alloc] initFromPatch: [pasteBoardConnection from]
																key: [pasteBoardConnection output]
															toPatch: [new_patch identity]
																key: index];				
			}
		}
		if (newConnection != nil)
		{
#warning complete me!
//			newConnection
		}
		
		return YES;
	}
	return NO;
}

#pragma mark Dragging

- (NSDragOperation)draggingUpdated: (id<NSDraggingInfo>)sender
{
	NSPasteboard * pboard = [sender draggingPasteboard];
	
	if ([pboard availableTypeFromArray: [BBPatchCollectionController pasteboardTypes]] != nil)
		return NSDragOperationCopy;
	if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{
		
		[self updateTemporaryDraggingConnection: sender];
		
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
		pasteBoardConnection = [BBConnection fromPasteboard: pboard];

		if ([pasteBoardConnection from] == 0)
			[self removeTemporaryDraggingConnectionFromStart];
		if ([pasteBoardConnection to] == 0)
			[self removeTemporaryDraggingConnectionFromEnd];
	}
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	BBPatchDefinition * definition;
	NSArray * definitions;
	NSPoint localPoint;
	NSPasteboard * pboard;
	
	pboard = [sender draggingPasteboard];
	
	if ([pboard availableTypeFromArray: [BBPatchCollectionController pasteboardTypes]] != nil)
	{
		localPoint = [self convertPoint: [sender draggingLocation]
							   fromView: nil];
		definitions = [self->_controller definitionsFromPasteboard: pboard];
		for (definition in definitions)
		{
			[self->_controller createPatchWithDefinition: definition
												 atPoint: NSPointToCGPoint(localPoint)];
		}
		return YES;
	}
	else if ([pboard availableTypeFromArray: [BBConnection pasteboardTypes]] != nil)
	{
		BBConnection * pasteBoardConnection;
		pasteBoardConnection = [BBConnection fromPasteboard: pboard];

		if ([pasteBoardConnection from] == 0)
			[self removeTemporaryDraggingConnectionFromStart];
		if ([pasteBoardConnection to] == 0)
			[self removeTemporaryDraggingConnectionFromEnd];		
		return NO;
	}

    return NO;
}

#pragma mark -
#pragma mark Patch Notification Management

-(void) patchAdded: (NSNotification*) notification
{
	BBLinkedPatch * patch;
	BBLinkedPatchView * view;
	BBLinkedPatchView * lastView = nil;
	BBLinkedPatchView * firstView = nil;
	NSArray * subviews;

	patch = [[notification userInfo] objectForKey: @"patch"];
	view  = [[BBLinkedPatchView alloc] initWithPatch: patch];

	subviews = [self subviews];
	if ([subviews count] > 0)
	{
		firstView = [[self subviews] objectAtIndex: 0];
		lastView  = [[self subviews] objectAtIndex: [subviews count] - 1];
	}

	[self->_patches setObject: view 
					   forKey: [NSNumber numberWithInteger: [patch identity]]];
	[self addSubview: view];
	[view setNextKeyView: firstView];
	[lastView setNextKeyView: view];
	[[self window] makeFirstResponder: view];
	
	[view release];	
}

-(void) patchRemoved: (NSNotification*) notification
{
	BBLinkedPatch * patch = [[notification userInfo] objectForKey: @"patch"];
	BBLinkedPatchView * view = nil;
	
	view = [self->_patches objectForKey: [NSNumber numberWithInteger: [patch identity]]];
	[self->_patches removeObjectForKey: [NSNumber numberWithInteger: [patch identity]]];
	[view removeFromSuperview];
}

#pragma mark -
#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	NSImage *anImage = [BBImageResource NSImageFromName: @"Mahogany"];
	[[NSColor colorWithPatternImage:anImage] set];
	NSRectFill([self bounds]);	
	
	BBPatchConnectionAnimation * animation;
	for (animation in self->_connectionAnimations)
		[animation draw];
	if (self->_draggingConnectionAnimation != nil)
		[self->_draggingConnectionAnimation draw];
}

@end
