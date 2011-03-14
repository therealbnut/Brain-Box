//
//  BBAppDelegate.m
//  BrainBox2
//
//  Created by Andrew Bennett on 18/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBAppDelegate.h"


@implementation BBAppDelegate

-(NSString *) licencePath
{
	return [[NSBundle mainBundle] pathForResource: @"licence" ofType: @"rtf"];
}

-(NSString *) creditsPath
{
	return [[NSBundle mainBundle] pathForResource: @"credits" ofType: @"rtf"];
}

-(NSString *) localizedAppNameAndVersion
{
	id name = [[[NSBundle mainBundle] infoDictionary] objectForKey: (id)kCFBundleNameKey];
	id version = [[[NSBundle mainBundle] infoDictionary] objectForKey: (id)kCFBundleVersionKey];
	return [NSString stringWithFormat: @"%@ v%@", name, version];
}

@end
