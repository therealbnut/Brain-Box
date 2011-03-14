//
//  BBConnectionAnimationState.h
//  BrainBox2
//
//  Created by Andrew Bennett on 19/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#pragma mark Raw Interface

typedef struct _BBPatchConnectionAnimationState
{
	CGPoint _start, _end;
	CGPoint _p1, _p2;
	CGPoint _dp1, _dp2;
	CGRect  _bounds[4];	
} BBPatchConnectionAnimationState;
typedef BBPatchConnectionAnimationState * BBPatchConnectionAnimationStateRef;

void	BBPatchConnectionAnimationState_init(BBPatchConnectionAnimationStateRef state, CGPoint start, CGPoint end);
void	BBPatchConnectionAnimationState_calculateBounds(BBPatchConnectionAnimationStateRef state);
CGRect	BBPatchConnectionAnimationState_calculateFrame(BBPatchConnectionAnimationStateRef state);
BOOL	BBPatchConnectionAnimationState_updateSimulation(BBPatchConnectionAnimationStateRef state, int update_count);
BOOL	BBPatchConnectionAnimationState_update(BBPatchConnectionAnimationStateRef state, CFTimeInterval dt, CGRect * redisplay);
void	BBPatchConnectionAnimationState_draw(BBPatchConnectionAnimationStateRef state, CGContextRef context);

#pragma mark ObjC Interface

@interface BBPatchConnectionAnimation : NSObject
{
	BBPatchConnectionAnimationState _state;
	NSUInteger _snapBack;
	CFTimeInterval _snapBackTime; 
}

-initWithStart: (NSPoint) start
		   end: (NSPoint) end;

@property (readwrite) NSPoint start;
@property (readwrite) NSPoint end;

-(BOOL) update: (CFTimeInterval) dt
		inView: (NSView*) view;

-(void) setNeedsRedisplayInView: (NSView*) view;
-(void) draw;
-(void) drawInContext: (NSGraphicsContext*) context;

-(void) removeSnapBack;
-(void) snapBackStart;
-(void) snapBackEnd;

@end
