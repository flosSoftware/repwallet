//
//  IndexableString.m
//  repWallet
//
//  Created by Alberto Fiore on 10/31/12.
//  Copyright 2012 Alberto Fiore. All rights reserved.
//

#import "IndexableString.h"


@implementation IndexableString

@synthesize string;

+ (id)indexableStringWithString:(NSString *)s
{
	IndexableString *str = [[[self alloc] init] autorelease];
	[str setString:s];
	return str;
}


- (void)dealloc
{
	[self.string release];
	[super dealloc];
}

@end
