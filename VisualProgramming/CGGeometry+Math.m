//
//  CGGeometry+Math.m
//  BrainBox2
//
//  Created by Andrew Bennett on 18/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CGGeometry+Math.h"

CGPoint CGPointAdd(CGPoint a, CGPoint b) {return CGPointMake(a.x+b.x, a.y+b.y);}
CGPoint CGPointSub(CGPoint a, CGPoint b) {return CGPointMake(a.x-b.x, a.y-b.y);}
CGPoint CGPointMul(CGPoint a, CGFloat b) {return CGPointMake(a.x*b, a.y*b);}
CGPoint CGPointLerp(CGPoint a, CGPoint b, CGFloat t) {return CGPointMake(a.x+(b.x-a.x)*t, a.y+(b.y-a.y)*t);}
CGFloat CGPointDot(CGPoint a, CGPoint b) {return a.x*b.x + a.y*b.y;}
CGFloat CGPointLength2(CGPoint a) {return a.x*a.x + a.y*a.y;}

CGPoint CGPointMin(CGPoint a, CGPoint b) {return CGPointMake(fmin(a.x, b.x), fmin(a.y, b.y));}
CGPoint CGPointMax(CGPoint a, CGPoint b) {return CGPointMake(fmax(a.x, b.x), fmax(a.y, b.y));}
CGRect  CGRectBoundingPoints(CGPoint a, CGPoint b, CGPoint c)
{
	CGPoint min, max;
	
	min = a;
	min = CGPointMin(min, b);
	min = CGPointMin(min, c);
	//	min = CGPointMin(min, d);
	
	max = a;
	max = CGPointMax(max, b);
	max = CGPointMax(max, c);
	//	max = CGPointMax(max, d);
	
	return CGRectMake(min.x, min.y, max.x-min.x, max.y-min.y);
}
