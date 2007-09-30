//
//  qsTrack.m
//  Agent Orange
//
//  Created by Jamie Hardt on 8/13/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "qsTrack.h"


@implementation qsTrack

- (id) init {
	self = [super init];
	if (self != nil) {
		trackName = [@"New Track" retain];
		showTrack = NO;
	}
	return self;
}

- (void) dealloc {
	[trackName release];
	[super dealloc];
}



@end
