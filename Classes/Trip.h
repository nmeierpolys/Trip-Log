//
//  Trip.h
//  Trip Log
//
//  Created by Nathaniel Meierpolys on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyLocation.h"

@interface Trip : NSObject {
    NSMutableArray *locations;
    NSString *tripName;
    NSString *fileName;
    double cumulativeDistance;
    double directDistance;
}

@property (retain, nonatomic) NSMutableArray *locations;
@property (retain, nonatomic) NSString *tripName;
@property (retain, nonatomic) NSString *fileName;
@property double cumulativeDistance;
@property double directDistance;

- (void)addLocation:(MyLocation *)location;
- (void)clearLocations;
- (void)loadData;
- (void)saveData;
- (void)updateDistancesFromLocation:(MyLocation *)newLocation;
- (void)computeDistancesOfLocations;
- (double)distanceBetweenPoints:(MyLocation *)fromPoint toPoint:(MyLocation *)toPoint unitEnum:(int)unitEnum;
- (NSString *)directDistanceWithUnit:(int)unitEnum;
- (NSString *)cumulativeDistanceWithUnit:(int)unitEnum;
- (NSString *)distance:(double)distance formattedWithUnit:(int)unitEnum;
- (NSString *)cumulativeDistanceAutoformatted;
- (NSString *)directDistanceAutoformatted;
- (int)appropriateUnitForDistance:(int)distance;
@end
