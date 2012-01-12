//
//  Trip.m
//  Trip Log
//
//  Created by Nathaniel Meierpolys on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Trip.h"

@implementation Trip

@synthesize locations;
@synthesize tripName;
@synthesize fileName;

- (id)initWithName:(NSString*)name file:(NSString*)file locations:(NSMutableArray *)locationArr {
    if ((self = [super init])) {
        tripName = [name copy];
        fileName = [file copy];
        locations = locationArr;
    }
    return self;
}
- (void)addLocation:(MyLocation *)location{
    [locations addObject:location];
}

- (void)clearLocations{
    [locations removeAllObjects];
}

- (void)loadData{
    
}

- (void)saveData{
    
}


@end
