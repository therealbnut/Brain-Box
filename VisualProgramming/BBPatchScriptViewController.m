//
//  BBPatchScriptController.m
//  BrainBox2
//
//  Created by Andrew Bennett on 15/11/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BBPatchScriptViewController.h"
#import <AGRegex/AGRegex.h>

NSString * const kBBSyntaxHighlightingKey = @"BBSyntaxHighlighting";
NSString * const kBBKeywordHighlightingKey = @"BBKeywordHighlighting";
NSString * const kBBSyntaxHighlightingSyntaxKey = @"syntax";
NSString * const kBBSyntaxHighlightingRedKey = @"red";
NSString * const kBBSyntaxHighlightingGreenKey = @"green";
NSString * const kBBSyntaxHighlightingBlueKey = @"blue";

@implementation BBPatchScriptViewController

@synthesize scriptView = _scriptView;

-init
{
	if (self = [super init])
	{
		NSArray * syntax_array;
		NSDictionary * i;

		i = [[[NSBundle mainBundle] infoDictionary] objectForKey: kBBKeywordHighlightingKey];
		self->_keyword = [[AGRegex alloc] initWithPattern: [i objectForKey: kBBSyntaxHighlightingSyntaxKey]
												  options: 0];
		if (self->_keyword != nil)
		{
			self->_keywordColour = [[NSColor colorWithDeviceRed: [[i objectForKey: kBBSyntaxHighlightingRedKey] doubleValue]
														  green: [[i objectForKey: kBBSyntaxHighlightingGreenKey] doubleValue]
														   blue: [[i objectForKey: kBBSyntaxHighlightingBlueKey] doubleValue]
														  alpha: 1.0] retain];
			if (self->_keywordColour == nil)
			{
				[self->_keyword release];
				self->_keyword = nil;
				NSLog(@"Failed to create colour for expression: %@", [i objectForKey: kBBSyntaxHighlightingSyntaxKey]);
			}
		}
		else
		{
			NSLog(@"Failed to compile expression: %@", [i objectForKey: kBBSyntaxHighlightingSyntaxKey]);
		}

		syntax_array = [[[NSBundle mainBundle] infoDictionary] objectForKey: kBBSyntaxHighlightingKey];
		if (!syntax_array)
		{
			NSLog(@"No '%@' key found in nib!", kBBSyntaxHighlightingKey);
		}
		else
		{
			NSMutableArray * s = [[NSMutableArray alloc] init];
			NSMutableArray * c = [[NSMutableArray alloc] init];
			for (i in syntax_array)
			{
				AGRegex * expr = [[AGRegex alloc] initWithPattern: [i objectForKey: kBBSyntaxHighlightingSyntaxKey]
														  options: 0];
				if (!expr)
				{
					NSLog(@"Failed to compile expression: %@", [i objectForKey: kBBSyntaxHighlightingSyntaxKey]);
					continue;
				}
				NSColor * colour = [[NSColor colorWithDeviceRed: [[i objectForKey: kBBSyntaxHighlightingRedKey] doubleValue]
														  green: [[i objectForKey: kBBSyntaxHighlightingGreenKey] doubleValue]
														   blue: [[i objectForKey: kBBSyntaxHighlightingBlueKey] doubleValue]
														  alpha: 1.0] retain];
				if (colour == nil) 
				{
					NSLog(@"Failed to create colour for expression: %@", [i objectForKey: kBBSyntaxHighlightingSyntaxKey]);
					[expr release];
					[colour release];
					continue;
				}
				[s addObject: expr];
				[c addObject: colour];
				[expr release];
				[colour release];
			}
			self->_syntax = [s copy];
			self->_colours = [c copy];
			[s release];
			[c release];
		}
	}
	return self;
}

-(void) awakeFromNib
{
	[self->_scriptView setDelegate: self];
//	[[self->_scriptView textStorage] setDelegate: self];
}

//- (void)textStorageDidProcessEditing: (NSNotification *)aNotification
//{
//	NSLog(@"textStorageDidProcessEditing: %@", aNotification);
//}

-(void) setColor: (NSColor*) colour
		forRange: (NSRange) range
{
	NSLayoutManager * layoutManager;
	layoutManager	= [self->_scriptView layoutManager];
	[layoutManager setTemporaryAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
											colour, NSForegroundColorAttributeName,
											nil]
						forCharacterRange: range];
}

-(void) syntaxHighlightRange: (NSRange) range
{
	NSString * string, * substring;
	NSRange effectiveRange;
	NSUInteger substringLength;

	string	= [self->_scriptView string];
	effectiveRange	= [string lineRangeForRange: range];
//	effectiveRange	= NSUnionRange([string lineRangeForRange: NSMakeRange(range.location, 0)],
//								   [string lineRangeForRange: NSMakeRange(NSMaxRange(range), 0)]);

	substring = [string substringWithRange: effectiveRange];
	substringLength = [substring length];

	if (substringLength == 0)
		return;

	NSSet* keywords = [[NSSet alloc] initWithObjects:
					  @"break",		@"continue",	@"do",			@"for",		@"import",		@"new",		@"this",	@"void",
					  @"case",		@"default",		@"else",		@"function",@"in",			@"return",	@"typeof",	@"while",
					  @"comment",	@"delete",		@"export",		@"if",		@"label",		@"switch",	@"var",		@"with",
					  @"abstract",	@"implements",	@"protected",	@"boolean",	@"instanceOf",	@"public",
					  @"byte",		@"int",			@"short",		@"char",	@"interface",	@"static",
					  @"double",	@"long",		@"synchronized",@"false",	@"native",		@"throws",
					  @"final",		@"null",		@"transient",	@"float",	@"package",		@"true",	@"goto",	@"private",
					  nil];
	AGRegex * expression;
	AGRegexMatch * match;
	NSArray * matches;
	NSColor * colour;
	
	[self setColor: [NSColor blackColor]
		  forRange: effectiveRange];
	
	if (self->_keyword)
	{
		colour = self->_keywordColour;
		matches = [self->_keyword findAllInString: substring];
		
		for (match in matches)
		{
			NSRange range = [match range];
			range.location += effectiveRange.location;
			if ([keywords member: [substring substringWithRange: range]] != nil)
			{
				[self setColor: colour
					  forRange: range];
			}
		}
	}	
	
	NSEnumerator * expression_enumerator = [self->_syntax objectEnumerator];
	NSEnumerator * colour_enumerator = [self->_colours objectEnumerator];
	while (expression = [expression_enumerator nextObject])
	{
		colour = [colour_enumerator nextObject];
		matches = [expression findAllInString: substring];
		
		for (match in matches)
		{
			NSRange range = [match range];
			range.location += effectiveRange.location;
			[self setColor: colour
				  forRange: range];
		}
	}

	[keywords release];
}

- (void)textDidChange:(NSNotification *)notification
{
	NSTextContainer * textContainer;
	NSScrollView * scrollView;
	NSLayoutManager * layoutManager;
	NSRect visibleRect;
	NSRange visibleRange;
	
	textContainer	= [self->_scriptView textContainer];
	scrollView		= [self->_scriptView enclosingScrollView];
	layoutManager	= [self->_scriptView layoutManager];
	visibleRect		= [[scrollView contentView] documentVisibleRect];
	visibleRange	= [layoutManager glyphRangeForBoundingRect: visibleRect inTextContainer: textContainer];

	[self syntaxHighlightRange: visibleRange];
}

@end
