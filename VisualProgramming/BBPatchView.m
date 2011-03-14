//
//  BBPatchView.m
//  BrainBox2
//
//  Created by Andrew Bennett on 12/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchView.h"

#import "BBImageResource.h"
#import "NSArray+BBUtility.h"

#import "BBPatchDefinition.h"
#import "BBPatchDocument.h"
#import "BBConnectionDefinition.h"


CGImageRef createPatchImage(CGContextRef context, NSString * patchTitle, 
							NSArray * inputs, NSArray * outputs,
							NSUInteger hash, BOOL focused);

const CGFloat kPatchShadowSize		= 14.0;
const CGFloat kPatchPadding			=  4.0;
const CGFloat kPatchInnerPadding	= 24.0;
const CGFloat kPatchBorder			= 36.0;
const CGFloat kPatchTextSize		= 12.0;
const CGFloat kPatchTitleTextSize	= 16.0;
const CGFloat kPatchMinInnerWidth	= 72.0;

static CGImageRef kBBPatchViewBackground, kBBPatchViewDivider, kBBPatchViewCutCorners[2][9];
static CGImageRef kBBPatchViewInputPlug, kBBPatchViewOutputPlug;

#pragma mark -
#pragma mark BBPatchDefinitionView

@implementation BBPatchView

-initWithFrame: (NSRect) frame
{
	if (self = [super initWithFrame: frame])
	{
	}
	return self;
}

-(void) dealloc
{
	[self->_definition removeObserver: self
						   forKeyPath: @"inputs"];
	[self->_definition removeObserver: self
						   forKeyPath: @"outputs"];
	[self->_definition removeObserver: self
						   forKeyPath: @"title"];
	[super dealloc];
}

-(void) awakeFromNib
{
    [[self window] setAcceptsMouseMovedEvents:YES];
}

#pragma mark Properties

-(BBPatchDefinition*) definition
{
	return self->_definition;
}
-(void) setDefinition:(BBPatchDefinition *) new_definition
{
	[self->_definition release];
	[self->_definition removeObserver: self
						   forKeyPath: @"inputs"];
	[self->_definition removeObserver: self
						   forKeyPath: @"outputs"];
	[self->_definition removeObserver: self
						   forKeyPath: @"title"];

	[self willChangeValueForKey: @"definition"];
	self->_definition = new_definition;
	[self didChangeValueForKey: @"definition"];

	[self->_definition addObserver: self
						forKeyPath: @"inputs"
						   options: NSKeyValueObservingOptionNew 
						   context: NULL];
	[self->_definition addObserver: self
						forKeyPath: @"outputs"
						   options: NSKeyValueObservingOptionNew 
						   context: NULL];
	[self->_definition addObserver: self
						forKeyPath: @"title"
						   options: NSKeyValueObservingOptionNew 
						   context: NULL];	
}

-(void) observeValueForKeyPath: (NSString *)keyPath
					  ofObject: (id)object
						change: (NSDictionary *)change
					   context: (void *)context
{
	if ([keyPath isEqualToString: @"inputs"] ||
		[keyPath isEqualToString: @"outputs"] ||
		[keyPath isEqualToString: @"title"])
	{
		[self updateImage];
	}
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}
-(BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

NSComparisonResult bringToFront(id arg1, id arg2, void *arg3)
{
	if (arg1 == arg3)
		return NSOrderedDescending;
	else if (arg2 == arg3)
		return NSOrderedAscending;
	return NSOrderedSame;
}

- (BOOL)becomeFirstResponder
{
    BOOL okToChange = [super becomeFirstResponder];
    if (okToChange) [self setKeyboardFocusRingNeedsDisplayInRect: [self bounds]];
	
	[[self superview] sortSubviewsUsingFunction: bringToFront
										context: self];
	
    return okToChange;
}
- (BOOL)resignFirstResponder
{
    BOOL okToChange = [super resignFirstResponder];
    if (okToChange) [self setKeyboardFocusRingNeedsDisplayInRect: [self bounds]];
    return okToChange;
}

#pragma mark Cell Calculations

-(NSUInteger) cellColumnForPoint: (NSPoint) localPoint
{
	BOOL isInput = 2.0 * localPoint.x < self.bounds.size.width;
	if (NSPointInRect(localPoint, self.bounds))
		return !isInput;
	return -1;
}
-(NSUInteger) cellRowForPoint: (NSPoint) localPoint
{
	BOOL isInput = 2.0 * localPoint.x < self.bounds.size.width;
	NSUInteger index = floor((self.bounds.size.height - (localPoint.y+(kPatchBorder + kPatchTitleTextSize + kPatchPadding))) / (kPatchTextSize + kPatchPadding));
	NSUInteger countIndex = isInput ? [[[self definition] inputs] count] : [[[self definition] outputs] count];
	
	if (index >= countIndex)
		return -1;

	return index;	
}

#pragma mark -
#pragma mark Connection Points

-(CGFloat) connectionHeightForIndex: (NSUInteger) index
{
	CGFloat y = self.bounds.size.height - (kPatchBorder + kPatchTitleTextSize + kPatchPadding + (kPatchTextSize+kPatchPadding) * 0.5);
	y += -(kPatchTextSize + kPatchPadding) * index;
	return y;
}

-(CGPoint) outputPointForIndex: (NSUInteger) index
{
	NSPoint point = [self convertPoint: NSMakePoint(self.bounds.size.width-kPatchShadowSize, [self connectionHeightForIndex: index])
								toView: [self superview]];
	return NSPointToCGPoint(point);
}
-(CGPoint) inputPointForIndex: (NSUInteger) index
{
	NSPoint point = [self convertPoint: NSMakePoint(kPatchShadowSize, [self connectionHeightForIndex: index])
								toView: [self superview]];
	return NSPointToCGPoint(point);
}

#pragma mark Drawing

-(NSPoint) centrePointForSize: (NSSize) size
					oldCentre: (NSPoint) oldCentre
{
	NSSize superViewSize = [self superview].bounds.size;
	return NSMakePoint(superViewSize.width * 0.5,
					   superViewSize.height * 0.5);
}

-(NSUInteger) imageHash
{
	return
	(
		[[[self definition] title] hash] ^
		[[[self definition] inputs] hash] ^
		[[[self definition] outputs] hash]
	);
}

-(void) viewWillDraw
{
	BOOL isFirstResponder = ([[self window] firstResponder] == self);
	NSUInteger imageHash = [self imageHash];
	//	//sizeToCells
	//	[super viewWillDraw];
	//	NSRect frameRect  = [self frame];
	//	NSRect titleFrame = NSMakeRect(kPatchBorder, frameRect.size.height - (kPatchBorder + kPatchTitleTextSize + kPatchPadding),
	//								   frameRect.size.width - kPatchBorder * 2.0, kPatchTitleTextSize);
	//	NSDictionary * titleAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
	//									  [NSFont fontWithName: @"Helvetica-Bold" size: kPatchTitleTextSize], NSFontAttributeName,
	//									  [NSColor colorWithDeviceRed: 0.03 green: 0.02 blue: 0.01 alpha: 1.0], NSForegroundColorAttributeName,
	//									  [NSNumber numberWithDouble: 3.0], NSKernAttributeName,
	//									  [NSNumber numberWithDouble: -1.0], NSStrokeWidthAttributeName,
	//									  [NSColor colorWithDeviceRed: 0.50 green: 0.42 blue: 0.15 alpha: 1.0], NSStrokeColorAttributeName,
	//									  nil];
	//
	//	NSAttributedString * attributedString = [[NSAttributedString alloc] initWithString: @"title"
	//																			attributes: titleAttributes];
	//	[self->_title setAttributedStringValue: attributedString];
	//	[self->_title setAlignment: NSCenterTextAlignment];
	//	[self->_title setFont: [NSFont fontWithName: @"Helvetica-Bold" size: kPatchTitleTextSize]];
	//	[self->_title setFrame: titleFrame];
	//	[self->_title setBordered: NO];
	//	[self->_title setDrawsBackground: NO];
	////	[self->_title setStringValue: @"title patch"];
	//	
	//	[titleAttributes release];
	//	[attributedString release];
	
	if (self->_patchImage[isFirstResponder] == NULL || 
		self->_imageHash[isFirstResponder] != imageHash)
		[self updateImage];
}

-(NSArray*) drawingInputArray
{
	return [[[self definition] inputs] arrayByPerformingSelector: @selector(keyName)];
}

-(NSArray*) drawingOutputArray
{
	return [[[self definition] outputs] arrayByPerformingSelector: @selector(keyName)];	
}

-(void) updateImage
{
	CGContextRef context;
	NSArray * inputs;
	NSArray * outputs;
	
	BOOL isFirstResponder = ([[self window] firstResponder] == self);

//	[self lockFocus];
	context = (CGContextRef) [[[self window] graphicsContext] graphicsPort];
	if (context == NULL)
		return;
	
	inputs  = [self drawingInputArray];
	outputs = [self drawingOutputArray];
	
	BOOL firstImageInit = (self->_patchImage[isFirstResponder] == NULL);
	NSUInteger imageHash = [self imageHash];
	if (firstImageInit || imageHash != self->_imageHash[isFirstResponder])
	{
		NSString * title;
		if (self->_patchImage[isFirstResponder] != NULL)
		{
			CGImageRelease(self->_patchImage[isFirstResponder]);
		}
		title = [[self definition] title];
		if (title == nil)
			title = @"Untitled";
		self->_patchImage[isFirstResponder] = createPatchImage(context, title, inputs, outputs, imageHash, isFirstResponder);
		self->_imageHash[isFirstResponder] = imageHash;
	}

	NSSize frame_size = NSMakeSize(CGImageGetWidth(self->_patchImage[isFirstResponder]),
								   CGImageGetHeight(self->_patchImage[isFirstResponder]));
//	NSSize old_frame_size = [self frame].size;
//	NSPoint old_frame_origin = [self frame].origin;
//	NSPoint frame_origin = NSMakePoint(old_frame_origin.x + (old_frame_size.width-frame_size.width)*0.5,
//									   old_frame_origin.y + (old_frame_size.height-frame_size.height)*0.5);

	NSPoint old_centre;
	if (firstImageInit)
	{
		NSRect superViewBounds = [self superview].bounds;
		old_centre = NSMakePoint(NSMidX(superViewBounds), NSMidY(superViewBounds));		
	}
	else
	{
		NSRect frameRect = [self frame];
		old_centre = NSMakePoint(NSMidX(frameRect), NSMidY(frameRect));
	}
	NSPoint frame_centre = [self centrePointForSize: frame_size
										  oldCentre: old_centre];
	NSPoint frame_origin = NSMakePoint(frame_centre.x - frame_size.width * 0.5,
									   frame_centre.y - frame_size.height * 0.5);

	[self setFrame: NSMakeRect(frame_origin.x, frame_origin.y, frame_size.width, frame_size.height)];
	[self setNeedsDisplay: YES];
}

-(void) drawRect: (NSRect) rect
{
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	BOOL isFirstResponder = ([[self window] firstResponder] == self);

	CGContextDrawImage(context, 
					   CGRectMake(0, 0,
								  CGImageGetWidth(self->_patchImage[isFirstResponder]), 
								  CGImageGetHeight(self->_patchImage[isFirstResponder])), 
					   self->_patchImage[isFirstResponder]);

//	[[NSColor blackColor] setStroke];
//	[[NSBezierPath bezierPathWithRect: self.bounds] stroke];\
//	[[NSColor redColor] setStroke];
//	// kPatchTitleTextSize + kPatchTextSize + kPatchPadding
//	[[NSBezierPath bezierPathWithRect: 
//	  NSMakeRect(
//		0, 0,
//		self.bounds.size.width,
//		self.bounds.size.height - (kPatchBorder + kPatchTitleTextSize + kPatchPadding)
//		)] stroke];
}

@end

#pragma mark Drawing Utility Functions

void BBPatchView_initializeImages()
{
	static BOOL images_initialized = NO;
	if (!images_initialized)
	{
		kBBPatchViewBackground = [BBImageResource CGImageFromName: @"CopperTile"];
		kBBPatchViewDivider = [BBImageResource CGImageFromName: @"Divider"];
		
		CGImageRef corners[2] = {
			[BBImageResource CGImageFromName: @"CopperCorner"],
			[BBImageResource CGImageFromName: @"CopperCornerFocused"],
		};
		for (int i=0; i<2; ++i)
		{
			kBBPatchViewCutCorners[i][0] = CGImageCreateWithImageInRect(corners[i], CGRectMake( 0, 0,40,40));
			kBBPatchViewCutCorners[i][1] = CGImageCreateWithImageInRect(corners[i], CGRectMake(40, 0,11,40));
			kBBPatchViewCutCorners[i][2] = CGImageCreateWithImageInRect(corners[i], CGRectMake(51, 0,40,40));
			kBBPatchViewCutCorners[i][3] = CGImageCreateWithImageInRect(corners[i], CGRectMake( 0,40,40,11));
			kBBPatchViewCutCorners[i][4] = CGImageCreateWithImageInRect(corners[i], CGRectMake(40,40,11,11));
			kBBPatchViewCutCorners[i][5] = CGImageCreateWithImageInRect(corners[i], CGRectMake(51,40,40,11));
			kBBPatchViewCutCorners[i][6] = CGImageCreateWithImageInRect(corners[i], CGRectMake( 0,51,40,40));
			kBBPatchViewCutCorners[i][7] = CGImageCreateWithImageInRect(corners[i], CGRectMake(40,51,11,40));
			kBBPatchViewCutCorners[i][8] = CGImageCreateWithImageInRect(corners[i], CGRectMake(51,51,40,40));
		}
		
		kBBPatchViewInputPlug = [BBImageResource CGImageFromName: @"PlugInput"];
		kBBPatchViewOutputPlug = [BBImageResource CGImageFromName: @"PlugOutput"];
		
		images_initialized = YES;
	}	
}

void drawCopperSheet(CGContextRef context, CGRect sheet_bounds, NSUInteger seed, BOOL focused)
{
	NSRect bounds = NSRectFromCGRect(sheet_bounds);
	NSRect bounds_inset = NSInsetRect(bounds, 40, 40);
	NSUInteger width, height;
	
	BBPatchView_initializeImages();
	
	CGContextMoveToPoint(context, bounds.origin.x, bounds.origin.y);
	
	CGContextSaveGState(context);
	
	CGContextMoveToPoint(context, NSMinX(bounds) + 14, NSMinY(bounds) + 34);
	CGContextAddLineToPoint(context, NSMinX(bounds) + 14, NSMinY(bounds) + 34);
	CGContextAddLineToPoint(context, NSMinX(bounds) + 14, NSMaxY(bounds) - 34);
	CGContextAddLineToPoint(context, NSMinX(bounds) + 34, NSMaxY(bounds) - 14);
	CGContextAddLineToPoint(context, NSMaxX(bounds) - 34, NSMaxY(bounds) - 14);
	CGContextAddLineToPoint(context, NSMaxX(bounds) - 14, NSMaxY(bounds) - 34);
	CGContextAddLineToPoint(context, NSMaxX(bounds) - 14, NSMinY(bounds) + 34);
	CGContextAddLineToPoint(context, NSMaxX(bounds) - 34, NSMinY(bounds) + 14);
	CGContextAddLineToPoint(context, NSMinX(bounds) + 34, NSMinY(bounds) + 14);
	CGContextClosePath(context);
	
	CGContextClip(context);
	
	width  = CGImageGetWidth(kBBPatchViewBackground);
	height = CGImageGetHeight(kBBPatchViewBackground);
	
	CGContextDrawTiledImage(context,
							CGRectMake(seed%width, seed/width, width, height),
							kBBPatchViewBackground);
	
	CGContextRestoreGState(context);
	
	CGContextSaveGState(context);
	
	CGContextSetBlendMode(context, kCGBlendModeHardLight);
	
	CGContextDrawImage(context, CGRectMake(NSMinX(bounds      ), NSMaxY(bounds_inset), 40, 40), kBBPatchViewCutCorners[focused][0]);
	CGContextDrawImage(context, CGRectMake(NSMinX(bounds_inset), NSMaxY(bounds_inset), NSWidth(bounds_inset), 40), kBBPatchViewCutCorners[focused][1]);
	CGContextDrawImage(context, CGRectMake(NSMaxX(bounds_inset), NSMaxY(bounds_inset), 40, 40), kBBPatchViewCutCorners[focused][2]);
	
	CGContextDrawImage(context, CGRectMake(NSMinX(bounds      ), NSMinY(bounds_inset), 40, NSHeight(bounds_inset)), kBBPatchViewCutCorners[focused][3]);
	CGContextDrawImage(context, CGRectMake(NSMinX(bounds_inset), NSMinY(bounds_inset), NSWidth(bounds_inset), NSHeight(bounds_inset)), kBBPatchViewCutCorners[focused][4]);
	CGContextDrawImage(context, CGRectMake(NSMaxX(bounds_inset), NSMinY(bounds_inset), 40, NSHeight(bounds_inset)), kBBPatchViewCutCorners[focused][5]);
	
	CGContextDrawImage(context, CGRectMake(NSMinX(bounds      ), NSMinY(bounds      ), 40, 40), kBBPatchViewCutCorners[focused][6]);
	CGContextDrawImage(context, CGRectMake(NSMinX(bounds_inset), NSMinY(bounds      ), NSWidth(bounds_inset), 40), kBBPatchViewCutCorners[focused][7]);
	CGContextDrawImage(context, CGRectMake(NSMaxX(bounds_inset), NSMinY(bounds      ), 40, 40), kBBPatchViewCutCorners[focused][8]);
	
	CGFloat dividerWidth = CGImageGetWidth(kBBPatchViewDivider);
	dividerWidth = NSWidth(bounds_inset) < dividerWidth ? NSWidth(bounds_inset) : dividerWidth;
	CGContextDrawImage(context, CGRectMake(NSMidX(bounds) -  dividerWidth/2, NSMinY(bounds_inset)-16, dividerWidth, 8), kBBPatchViewDivider);
	
	CGContextRestoreGState(context);	
}

void prepareText(CGContextRef context, CGFloat size)
{
	CGContextSelectFont(context, "Helvetica-Bold", size, kCGEncodingMacRoman);
	CGContextSetCharacterSpacing (context, 3);
	
	//	CGContextSetRGBFillColor(context, 0.07, 0.06, 0.03, 1);
	CGContextSetRGBFillColor(context, 0.03, 0.02, 0.01, 1);
	CGContextSetLineWidth(context, 1);
	CGContextSetRGBStrokeColor(context, 0.50, 0.42, 0.15, 1);
}

void drawText(CGContextRef context, CGPoint point, const char * string)
{
	CGContextSetTextDrawingMode(context, kCGTextFillStroke);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextShowTextAtPoint(context, point.x, point.y, string, strlen(string)); 
}

CGSize getTextSize(CGContextRef context, const char * string)
{
	CGPoint start, point;
	
    CGContextSetTextMatrix (context, CGAffineTransformIdentity);
	CGContextSetTextDrawingMode(context, kCGTextInvisible);
	start = CGContextGetTextPosition(context);
    CGContextShowText(context, string, strlen(string));
	point = CGContextGetTextPosition(context);
	
	return CGSizeMake(point.x-start.x, point.y-start.y);
}

CGImageRef createPatchImage(CGContextRef context, NSString * patchTitle, 
							NSArray * inputs, NSArray * outputs, NSUInteger hash,
							BOOL focused)
{
	NSUInteger connection_count = [inputs count] + [outputs count];
	CGSize title_size, inputs_size, outputs_size, size;
	CGSize sizes[connection_count];
	NSUInteger index;
	CGPoint point;
	
	for (int i=0; i<connection_count; ++i)
		sizes[i] = CGSizeZero;
	
	BBPatchView_initializeImages();	
	
	CGContextSaveGState(context);
	
	prepareText(context, kPatchTitleTextSize);
	title_size = getTextSize(context, [patchTitle UTF8String]);
	
	prepareText(context, kPatchTextSize);
	
	index = 0;
	inputs_size = CGSizeZero;
	for (NSString * input in inputs)
	{
		size = getTextSize(context, [input UTF8String]);
		
		if (inputs_size.width < size.width)
			inputs_size.width = size.width;
		inputs_size.height += kPatchTextSize + kPatchPadding;
		
		sizes[index] = size;
		++index;
	}
	
	outputs_size = CGSizeZero;
	for (NSString * output in outputs)
	{
		size = getTextSize(context, [output UTF8String]);
		
		if (outputs_size.width < size.width)
			outputs_size.width = size.width;
		outputs_size.height += kPatchTextSize + kPatchPadding;
		
		sizes[index] = size;
		++index;
	}
	
	size = CGSizeMake(inputs_size.width+outputs_size.width+kPatchInnerPadding, 
					  inputs_size.height > outputs_size.height ? inputs_size.height : outputs_size.height);

	if (size.width < title_size.width) size.width = title_size.width;
	if (size.width < kPatchMinInnerWidth + kPatchPadding * 2.0) size.width = kPatchMinInnerWidth + kPatchPadding * 2.0;
	
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bitmap_context = CGBitmapContextCreate(NULL,
														size.width  + kPatchBorder*2.0 + 4,  
														size.height + kPatchBorder*2.0 + kPatchTitleTextSize*2.0 + kPatchPadding, 
														8, 0, colorspace, kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorspace);
	
	drawCopperSheet(bitmap_context, CGRectMake(2,2,size.width+kPatchBorder*2.0,
											   size.height+kPatchTitleTextSize*2.0+kPatchBorder*2.0),
					hash, focused);
	
	point = CGPointMake(kPatchBorder + 2, 
						kPatchBorder + size.height + kPatchTitleTextSize + kPatchPadding);
	
	prepareText(bitmap_context, kPatchTextSize);
	
	index = 0;
	for (NSString * input in inputs)
	{
		point.y -= kPatchTextSize + kPatchPadding;
		drawText(bitmap_context, point, [input UTF8String]);
		CGContextDrawImage(bitmap_context, CGRectMake(0,point.y + (kPatchTextSize-24) * 0.5,32,20), kBBPatchViewInputPlug);
		
		++index;
	}
	
	point = CGPointMake(kPatchBorder + 2 + size.width, 
						kPatchBorder + size.height + kPatchTitleTextSize + kPatchPadding);
	for (NSString * output in outputs)
	{
		point.y -= kPatchTextSize + kPatchPadding;
		drawText(bitmap_context, CGPointMake(point.x-sizes[index].width, point.y), [output UTF8String]);
		CGContextDrawImage(bitmap_context, CGRectMake(size.width+kPatchBorder*2.0 - 28,
													  point.y + (kPatchTextSize-24) * 0.5,32,20), kBBPatchViewOutputPlug);
		
		++index;
	}
	
	prepareText(bitmap_context, kPatchTitleTextSize);
	drawText(bitmap_context,
			 CGPointMake(kPatchBorder + 6 + (size.width - title_size.width) * 0.5,
						 kPatchBorder + size.height + kPatchTitleTextSize + kPatchPadding), 
			 [patchTitle UTF8String]);
	
	CGContextRestoreGState(context);
	
	CGImageRef cgImage = CGBitmapContextCreateImage(bitmap_context);
	CGContextRelease(bitmap_context);
	
	return cgImage;
}
