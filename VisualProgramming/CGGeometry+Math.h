//
//  CGGeometry+Math.h
//  BrainBox2
//
//  Created by Andrew Bennett on 18/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

CGPoint CGPointAdd(CGPoint a, CGPoint b);
CGPoint CGPointSub(CGPoint a, CGPoint b);
CGPoint CGPointMul(CGPoint a, CGFloat b);
CGPoint CGPointLerp(CGPoint a, CGPoint b, CGFloat t);
CGFloat CGPointDot(CGPoint a, CGPoint b);
CGFloat CGPointLength2(CGPoint a);

CGPoint CGPointMin(CGPoint a, CGPoint b);
CGPoint CGPointMax(CGPoint a, CGPoint b);
CGRect  CGRectBoundingPoints(CGPoint a, CGPoint b, CGPoint c);
