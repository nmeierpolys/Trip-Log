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
@synthesize cumulativeDistance;
@synthesize directDistance;

- (id)initWithName:(NSString*)name file:(NSString*)file locations:(NSMutableArray *)locationArr {
    if ((self = [super init])) {
        tripName = [name copy];
        fileName = [file copy];
        locations = locationArr;
    }
    [self computeDistancesOfLocations];
    
    return self;
}
- (void)addLocation:(MyLocation *)location{
    [self updateDistancesFromLocation:location];  // Computer distances
    [locations addObject:location];               // Add the location to the trip's locations array
}

- (void)clearLocations{
    [locations removeAllObjects];
}

- (void)loadData{
    
}

- (void)saveData{
    
}

//- (double)directDistance{
    //Return the base distance in defined units
    //TODO: Add more support for units
    //TODO: add getter which returns a string that contains the right units - actually, need a utility library and funtion to handle this.  Also need some global-level consts to handle the units -- OR change unit display based on magnitude - 1000 feet -> miles
    //return directDistance;
//}

//- (double)cumulativeDistance{
//    return cumulativeDistance;
//}

- (NSString *)cumulativeDistanceWithUnit:(int)unitEnum
{
    NSString *cumulativeString = [self distance:cumulativeDistance formattedWithUnit:1];
    return cumulativeString;
}


- (NSString *)directDistanceWithUnit:(int)unitEnum
{
    NSString *directString = [self distance:directDistance formattedWithUnit:1];
    return directString;
}

- (NSString *)cumulativeDistanceAutoformatted
{
    int unit = [self appropriateUnitForDistance:cumulativeDistance];
    NSString *cumulativeString = [self distance:cumulativeDistance formattedWithUnit:unit];
    return cumulativeString;
}

- (NSString *)directDistanceAutoformatted
{
    int unit = [self appropriateUnitForDistance:directDistance];
    NSString *directString = [self distance:directDistance formattedWithUnit:unit];
    return directString;
}

- (int)appropriateUnitForDistance:(int)distance
{
    int unitToUse = 1;
    if(distance < 1000)
        unitToUse = 3;
    else
        unitToUse = 2;
    return unitToUse;
}

- (NSString *)distance:(double)distance formattedWithUnit:(int)unitEnum
{
    double convertedDistance = 0;
    NSString *output = nil;
    if(unitEnum == 1){  //meters
        convertedDistance = distance;
        output = [NSString stringWithFormat:@"%.0f %@",convertedDistance,@"m"];
    } else if(unitEnum == 2) {  //miles
        convertedDistance = distance * 0.000621371192;
        output = [NSString stringWithFormat:@"%.1f %@",convertedDistance,@"mi"];
    } else if(unitEnum == 3) {  //feet
        convertedDistance = distance * 3.280840;
        output = [NSString stringWithFormat:@"%.0f %@",convertedDistance,@"ft"];
    }

    return output;
}

- (void)updateDistancesFromLocation:(MyLocation *)newLocation{
    int unit = 3;
    
    if(newLocation == nil)
        return;
    
    if(locations.count < 1)
        return;
    
    MyLocation *firstLocation = [locations objectAtIndex:0];
    MyLocation *lastLocation = [locations lastObject];
    
    
    directDistance = [self distanceBetweenPoints:firstLocation toPoint:newLocation unitEnum:unit];
    cumulativeDistance += [self distanceBetweenPoints:lastLocation toPoint:newLocation unitEnum:unit];
}

- (void)computeDistancesOfLocations{
    int count = locations.count;
    int unit = 1;
    
    //Only compute distances if there are multiple points
    if(count < 2)
    {
        cumulativeDistance = 0;
        directDistance = 0;
    }
    
    //Set up initial and running MyLocation objects
    MyLocation *firstLocation = [locations objectAtIndex:0];
    MyLocation *currentLocation;
    MyLocation *previousLocation = firstLocation;
    
    //Loop through all locations, incrementally compute distances and 
    for(int i=1;i<count;i++){
        currentLocation = [locations objectAtIndex:i];
        cumulativeDistance += [self distanceBetweenPoints:previousLocation toPoint:currentLocation unitEnum:unit];
        previousLocation = currentLocation;
    }
    
    directDistance = [self distanceBetweenPoints:firstLocation toPoint:currentLocation unitEnum:unit];
}

- (double)distanceBetweenPoints:(MyLocation *)fromPoint toPoint:(MyLocation *)toPoint unitEnum:(int)unitEnum{
    
    if((fromPoint == nil) || (toPoint == nil))
        return 0;
    
    //Convert to CLLocations
    CLLocation *fromLocation = [[CLLocation alloc] initWithCoordinate: fromPoint.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    CLLocation *toLocation = [[CLLocation alloc] initWithCoordinate: toPoint.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    
    //Calculate distance in meters
    CLLocationDistance baseDistance = [fromLocation distanceFromLocation:toLocation];
    
    double distance;
    if(unitEnum == 1)  //meters
        distance = baseDistance;
    else if(unitEnum == 2)  //miles
        distance = baseDistance * 0.000621371192;
    else if(unitEnum == 3)  //feet
        distance = baseDistance * 3.280840;
    
    //NSString *fromCoord = [NSString stringWithFormat:@"(%f,%f)",fromLocation.coordinate.latitude,fromLocation.coordinate.longitude];
    
    //NSString *toCoord = [NSString stringWithFormat:@"(%f,%f)",toLocation.coordinate.latitude,toLocation.coordinate.longitude];
    
    return distance;
}


@end
