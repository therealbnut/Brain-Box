//
//  BBSplitViewLimitsDelegate.m
//  BrainBox2
//
//  Created by Andrew Bennett on 16/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBSplitViewLimitsDelegate.h"

const CGFloat kMinWidth = 196.0;

@implementation BBSplitViewLimitsDelegate

-(CGFloat) splitView: (NSSplitView *)sender
constrainMaxCoordinate: (CGFloat)proposedMax
		 ofSubviewAt: (NSInteger)offset
{
	if (offset == [[sender subviews] count]-1)
		return CGFLOAT_MAX;
	CGFloat left  = [[[sender subviews] objectAtIndex: offset] frame].size.width;
	CGFloat right = [[[sender subviews] objectAtIndex: offset] frame].size.width;
	
	self->minWidth = kMinWidth;
	return (left+right-self->minWidth);
}

- (CGFloat)splitView: (NSSplitView *)sender
constrainMinCoordinate: (CGFloat)proposedMin
		 ofSubviewAt: (NSInteger)offset
{
	self->minWidth = kMinWidth;
	return self->minWidth;
}

- (void) splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
    NSView * subview;

	CGSize size_total = NSSizeToCGSize(sender.frame.size);
	NSUInteger width_divider = [sender dividerThickness];
	size_total.width -= width_divider * ([[sender subviews] count] - 1);

	self->minWidth = kMinWidth;

	NSUInteger width_sum = 0.0;
	for (subview in [sender subviews])
		width_sum += [subview frame].size.width;
	CGFloat ratio = size_total.width / width_sum;

	NSUInteger offset_x = 0;
	for (subview in [sender subviews])
	{
		NSRect rect = [subview frame];
		NSUInteger width = rect.size.width * ratio;
		if (width < self->minWidth)
		{
			width_sum -= (width-self->minWidth);
			ratio = size_total.width / width_sum;
			width = self->minWidth;
		}
		rect.size	= NSMakeSize(width, size_total.height);
		rect.origin	= NSMakePoint(offset_x, 0);
		offset_x += width + width_divider;

		[subview setFrame: rect];
	}
	offset_x -= width_divider;

	if (offset_x != size_total.width)
	{
		subview = [[sender subviews] objectAtIndex: [[sender subviews] count] - 1];
		NSRect rect = [subview frame];
		rect.size.width += size_total.width - offset_x;
	}

	[sender adjustSubviews];
}

@end
