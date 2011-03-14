//
//  BBConnectionDefinitionDragView.m
//  BrainBox2
//
//  Created by Andrew Bennett on 13/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBConnectionDefinitionDragView.h"
#import "BBConnectionDefinition.h"
#import "BBImageResource.h"

NSString * const kBBConnectionDefinitionDefaultKeyName;
NSString * const kBBConnectionDefinitionDefaultType;

@implementation BBConnectionDefinitionDragView

@synthesize definition = _definition;

-initWithFrame: (NSRect) frameRect
{
	if (self = [super initWithFrame: frameRect])
	{
		self->_definition = [[BBConnectionDefinition alloc] init];
	}
	return self;
}
-(void) dealloc
{
	[self->_definition release];
	[super dealloc];
}

-(void) awakeFromNib
{
	[self registerForDraggedTypes: [BBConnectionDefinition pasteboardTypes]];	
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    return NSDragOperationCopy;
}
- (BOOL)acceptsFirstResponder
{
	return YES;
}
-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPasteboard* dragPasteboard = [NSPasteboard pasteboardWithName: NSDragPboard];
	NSPoint point = [theEvent locationInWindow];
	NSPoint localPoint = [self convertPoint: point
								   fromView: nil];

	[dragPasteboard declareTypes: [BBConnectionDefinition pasteboardTypes]
						   owner: self->_definition];
	NSImage * dragImage = [BBImageResource NSImageFromName: @"DragMe"];
	NSSize dragImageSize = [dragImage size];
	[self dragImage: dragImage
				 at: NSMakePoint(localPoint.x + dragImageSize.width*-0.5,
								 localPoint.y + dragImageSize.height*-0.5)
			 offset: NSZeroSize
			  event: theEvent
		 pasteboard: dragPasteboard
			 source: self
		  slideBack: YES];
}

//- (void)pasteboard: (NSPasteboard *)sender provideDataForType: (NSString *)pboardType
//{
//	if ([pboardType compare: kBBPatchDefinitionConnectionPboardType] == NSOrderedSame)
//	{
//		[sender setData: [self->_definition encodeAsData]
//				forType: kBBPatchDefinitionConnectionPboardType];
//    }
//	else if ([pboardType compare: NSStringPboardType] == NSOrderedSame)
//	{
//		[sender setString: [self->_definition encodeAsString]
//				  forType: NSStringPboardType];
//	}
//}

- (void)drawRect:(NSRect)dirtyRect
{
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
//	CGImageRef wood = [BBImageResource CGImageFromName: @"Mahogany"];
	CGImageRef dragItem = [BBImageResource CGImageFromName: @"DragMeSource"];

//	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(wood), CGImageGetHeight(wood)), wood);	
	CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(dragItem), CGImageGetHeight(dragItem)), dragItem);
}

@end
