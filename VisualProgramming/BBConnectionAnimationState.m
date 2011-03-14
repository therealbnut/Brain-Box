//
//  BBConnectionAnimationState.m
//  BrainBox2
//
//  Created by Andrew Bennett on 19/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBConnectionAnimationState.h"
#import "CGGeometry+Math.h"

#pragma mark Constants

const CGFloat kConnectionStringStiffness = 64.0;
const CGFloat kConnectionStringBulge = 0.25;
const CGFloat kConnectionStringWeight = 12.0;
const CGFloat kConnectionFriction = 0.9;
const CGFloat kConnectionLineRadius = 8.0;
const CGFloat kAnimationUpdatesPerSecond = 60.0;
const CGFloat kAnimationFramesPerSecond = 40.0;
const CGFloat kAnimationSnapBackTime = 0.2;

const CGFloat kAnimationThreshold = FLT_EPSILON;

#pragma mark -
#pragma mark BBPatchConnectionAnimation

@implementation BBPatchConnectionAnimation

-initWithStart: (NSPoint) _start
		   end: (NSPoint) _end
{
	if (self = [super init])
	{
		BBPatchConnectionAnimationState_init(&self->_state,
											 NSPointToCGPoint(_start),
											 NSPointToCGPoint(_end));
	}
	return self;
}

#pragma mark Properties

-(NSPoint) start
{
	return NSPointFromCGPoint(self->_state._start);
}
-(void) setStart:(NSPoint) _start
{
	[self willChangeValueForKey: @"start"];
	self->_state._start = NSPointToCGPoint(_start);
	[self didChangeValueForKey: @"start"];
}

-(NSPoint) end
{
	return NSPointFromCGPoint(self->_state._end);
}
-(void) setEnd:(NSPoint) _end
{
	[self willChangeValueForKey: @"end"];
	self->_state._end = NSPointToCGPoint(_end);
	[self didChangeValueForKey: @"end"];
}

#pragma mark Update

-(void) removeSnapBack
{
	self->_snapBack = 0;
}
-(void) snapBackStart
{
	self->_snapBack |= 1;
}
-(void) snapBackEnd
{
	self->_snapBack |= 2;
}

-(BOOL) update: (CFTimeInterval) dt
		inView: (NSView*) view
{
	CGRect displayRect[4];
	BOOL needsRedisplay;
	
	if (self->_snapBack)
		self->_snapBackTime = fmin(self->_snapBackTime + dt / kAnimationSnapBackTime, 1.0);
	if (self->_snapBack & 1)
		self->_state._start = CGPointLerp(self->_state._start, self->_state._end, self->_snapBackTime);
	if (self->_snapBack & 2)
		self->_state._end = CGPointLerp(self->_state._end, self->_state._start, self->_snapBackTime);

	needsRedisplay = BBPatchConnectionAnimationState_update(&self->_state, dt, displayRect);
	
	if (self->_snapBack && CGPointLength2(CGPointSub(self->_state._start, self->_state._end)) < 1.0)
		needsRedisplay = NO;

	for (int i=0; i<4; ++i)
		[view setNeedsDisplayInRect: NSRectFromCGRect(displayRect[i])];

	return needsRedisplay;
}

#pragma mark Draw

-(void) setNeedsRedisplayInView: (NSView*) view
{
	for (int i=0; i<4; ++i)
		[view setNeedsDisplayInRect: NSRectFromCGRect(self->_state._bounds[i])];
}

-(void) draw
{
	CGContextRef context = (CGContextRef) [[NSGraphicsContext currentContext] graphicsPort];
	BBPatchConnectionAnimationState_draw(&self->_state, context);
}
-(void) drawInContext: (NSGraphicsContext*) objc_context
{
	CGContextRef context = (CGContextRef) [objc_context graphicsPort];
	BBPatchConnectionAnimationState_draw(&self->_state, context);
}

@end


#pragma mark -
#pragma mark BBPatchConnectionAnimationState

void BBPatchConnectionAnimationState_getTargets(CGPoint start, CGPoint end, CGPoint * t1, CGPoint * t2)
{
	CGPoint tP1, tP2, disp = CGPointSub(start, end);
	CGFloat absDispX = fabs(disp.x);
	
	tP1 = CGPointLerp(start, end, 0.5-kConnectionStringBulge);
	tP2 = CGPointLerp(start, end, 0.5+kConnectionStringBulge);
	
	tP1.y -= pow(kConnectionStringWeight * absDispX, 0.5);
	tP2.y -= pow(kConnectionStringWeight * absDispX, 0.5);
	
	*t1 = tP1;
	*t2 = tP2;
}

void calculateBezierBounds(CGPoint a, CGPoint b, CGPoint c, CGPoint d, CGRect * bounds)
{
	CGPoint m = CGPointAdd(CGPointMul(CGPointAdd(a,d), 0.125), CGPointMul(CGPointAdd(b,c), 0.375));
	bounds[0] = CGRectBoundingPoints(a, b, m);
	bounds[1] = CGRectBoundingPoints(c, d, m);
}

void BBPatchConnectionAnimationState_calculateBounds(BBPatchConnectionAnimationStateRef state)
{
	CGPoint a, b, m;
	
	a = CGPointMake(state->_start.x + kConnectionStringStiffness, state->_start.y);
	m = CGPointLerp(state->_p1, state->_p2, 0.5);
	b = CGPointMake(state->_end.x - kConnectionStringStiffness, state->_end.y);
	
	calculateBezierBounds(state->_start, a, state->_p1, m, &state->_bounds[0]);
	calculateBezierBounds(state->_end,   b, state->_p2, m, &state->_bounds[2]);
	
	for (int i=0; i<4; ++i)
		state->_bounds[i] = NSRectToCGRect(NSInsetRect(NSRectFromCGRect(state->_bounds[i]),
													   -kConnectionLineRadius,
													   -kConnectionLineRadius));
}

CGRect BBPatchConnectionAnimationState_calculateFrame(BBPatchConnectionAnimationStateRef state)
{
	NSRect frame = NSZeroRect;
	for (int i=0; i<4; ++i)
		frame = NSUnionRect(frame, NSRectFromCGRect(state->_bounds[i]));
	return NSRectToCGRect(frame);
}

void BBPatchConnectionAnimationState_init(BBPatchConnectionAnimationStateRef state, 
										  CGPoint start, CGPoint end)
{
	BBPatchConnectionAnimationState_getTargets(start, end, &state->_p1, &state->_p2);
	state->_start = start;
	state->_end   = end;
	state->_dp1   = CGPointZero;
	state->_dp2   = CGPointZero;
	for (int i=0; i<4; ++i)
		state->_bounds[i] = CGRectZero;
	BBPatchConnectionAnimationState_calculateBounds(state);	
}

BOOL BBPatchConnectionAnimationState_updateSimulation(BBPatchConnectionAnimationStateRef state, int update_count)
{
	CGPoint tP1, tP2, dP1, dP2;
	
	if (update_count < 0)
		return NO;
	
	BOOL needsDisplay = NO;
	for (int update=0; update<update_count; ++update)
	{
		BBPatchConnectionAnimationState_getTargets(state->_start, state->_end, &tP1, &tP2);
		
		dP1 = CGPointLerp(CGPointSub(tP1, state->_p1),
						  CGPointLerp(state->_dp1, state->_dp2, 0.2),
						  kConnectionFriction);
		dP2 = CGPointLerp(CGPointSub(tP2, state->_p2),
						  CGPointLerp(state->_dp1, state->_dp2, 0.8),
						  kConnectionFriction);
		
		state->_dp1 = dP1;
		state->_dp2 = dP2;
		state->_p1 = CGPointAdd(state->_p1, dP1);
		state->_p2 = CGPointAdd(state->_p2, dP2);
		
		if (CGPointLength2(dP1) > kAnimationThreshold || CGPointLength2(dP1) > kAnimationThreshold)
		{
			needsDisplay = YES;
		}
		else
		{
			break;
		}
	}
	
	return needsDisplay;
}

BOOL BBPatchConnectionAnimationState_update(BBPatchConnectionAnimationStateRef state, CFTimeInterval dt, CGRect * redisplay)
{
	NSRect old_bounds[4];
	BOOL needsDisplay;
	
	for (int i=0; i<4; ++i)
		old_bounds[i] = NSRectFromCGRect(state->_bounds[i]);

	needsDisplay = BBPatchConnectionAnimationState_updateSimulation(state, dt * kAnimationUpdatesPerSecond);
	BBPatchConnectionAnimationState_calculateBounds(state);

	for (int i=0; i<4; ++i)
		redisplay[i] = NSRectToCGRect(NSUnionRect(old_bounds[i], 
												  NSRectFromCGRect(state->_bounds[i])));
	
	return needsDisplay;
}

void BBPatchConnectionAnimationState_draw(BBPatchConnectionAnimationStateRef state, CGContextRef context)
{
	CGMutablePathRef path;
	
	CGContextSaveGState(context);
	path = CGPathCreateMutable();
	
	CGPathMoveToPoint(path, NULL, state->_start.x, state->_start.y);
	CGPathAddCurveToPoint(path, NULL,
						  state->_start.x + kConnectionStringStiffness, state->_start.y,
						  state->_p1.x, state->_p1.y,
						  (state->_p1.x+state->_p2.x)*0.5, (state->_p1.y+state->_p2.y)*0.5);
	CGPathAddCurveToPoint(path, NULL,
						  state->_p2.x, state->_p2.y,
						  state->_end.x - kConnectionStringStiffness, state->_end.y,
						  state->_end.x, state->_end.y);
	CGContextSetLineCap(context, kCGLineCapRound);
	CGContextSetLineWidth(context, kConnectionLineRadius * 1.00);
	CGContextSetRGBStrokeColor(context, 0.070588, 0.215686, 0.447059, 1.0);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	
	CGContextSetLineWidth(context, kConnectionLineRadius * 0.80);
	CGContextSetRGBStrokeColor(context, 0.192157, 0.349020, 0.603922, 1.0);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	
	CGContextSetLineWidth(context, kConnectionLineRadius * 0.80);
	CGContextSetRGBStrokeColor(context, 0.192157, 0.349020, 0.603922, 1.0);
	CGContextAddPath(context, path);
	
	CGContextSetLineWidth(context, kConnectionLineRadius * 0.25);
	CGContextSetRGBStrokeColor(context, 0.329412, 0.482353, 0.705882, 1.0);
	CGContextAddPath(context, path);
	
	CGContextTranslateCTM(context, 0.0, 1.0);
	CGContextStrokePath(context);
	
	CGPathRelease(path);
	CGContextRestoreGState(context);
}
