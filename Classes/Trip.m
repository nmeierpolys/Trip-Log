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
@synthesize useMetric;
@synthesize logData;
@synthesize startInstant = _startInstant;

- (id)initWithName:(NSString*)name file:(NSString*)file locations:(NSMutableArray *)locationArr {
    if ((self = [super init])) {
        tripName = [name copy];
        fileName = [file copy];
        locations = locationArr;
        logData = YES;
        startInstant = [NSDate date];
        useMetric = NO;
    }
    [self computeDistancesOfLocations];
    
    return self;
}
- (void)addLocation:(MyLocation *)location{
    if((locations == nil) || (location == nil))
        return;
    
    [self updateDistancesFromLocation:location];  // Compute distances
    [locations addObject:location];               // Add the location to the trip's locations array
}

- (void)removeLocationAtIndex:(NSUInteger)index{
    if((locations == nil) || (index < 0) || (index > locations.count))
        return;
    
    [locations removeObjectAtIndex:index];
    [self computeDistancesOfLocations];
}

- (void)removeLocation:(MyLocation *)location {
    if(locations == nil)
        return;
    
    [locations removeObject:location];
    [self updateLocationIndexes];
    [self computeDistancesOfLocations];
}

- (void)updateLocationIndexes {
    int count = locations.count;
    
    //Loop through all locations, updating the index value of each
    for(int i=0;i<count;i++){
        [[locations objectAtIndex:i] setIndex:i];
    }
}

- (void)clearLocations{
    if((locations != nil) && (locations.count > 0))
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

//Units:
//  1-Meters
//  2-Miles
//  3-Feet
//  4-Kilometres
- (int)appropriateUnitForDistance:(int)distance
{
    int unitToUse = 1;
    
    if(useMetric)
    {
        if(distance < 1000)
            unitToUse = 1;
        else
            unitToUse = 4;
    }
    else
    {
        if(distance < 1000)
            unitToUse = 3;
        else
            unitToUse = 2;
    }
    return unitToUse;
}

- (NSString *)distance:(double)distance
     formattedWithUnit:(int)unitEnum
{
    double convertedDistance = 0;
    NSString *output = nil;
    
    if(unitEnum == 1)  //metres
    {
        convertedDistance = distance;
        output = [NSString stringWithFormat:@"%.0f %@",convertedDistance,@"m"];
    }
    else if(unitEnum == 2)  //miles
    {
        convertedDistance = distance * 0.000621371192; //mile/ft   //mile/m=>0.000621371192
        output = [NSString stringWithFormat:@"%.1f %@",convertedDistance,@"mi"];
    }
    else if(unitEnum == 3)  //feet
    {
        convertedDistance = distance * 3.280840;
        output = [NSString stringWithFormat:@"%.0f %@",convertedDistance,@"ft"];
    }
    else if(unitEnum == 4)  //kilometres
    {
        convertedDistance = distance *0.001;
        output = [NSString stringWithFormat:@"%.1f %@",convertedDistance,@"km"];
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
    int unit = 3;
    
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
    cumulativeDistance = 0;
    for(int i=1;i<count;i++){
        currentLocation = [locations objectAtIndex:i];
        cumulativeDistance += [self distanceBetweenPoints:previousLocation toPoint:currentLocation unitEnum:unit];
        NSLog(@"%f / %f",[self distanceBetweenPoints:previousLocation toPoint:currentLocation unitEnum:unit],cumulativeDistance);
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
    double baseDistance = [fromLocation distanceFromLocation:toLocation] / 3.25;  // 4/3/13: 3.25 is arbitrary.  I have no idea why things are off by about that amount.
    
    double distance = 0;
    if(unitEnum == 1)  //metres
        distance = baseDistance;
    else if(unitEnum == 2)  //miles
        distance = baseDistance * 0.000621371192;
    else if(unitEnum == 3)  //feet
        distance = baseDistance * 3.280840;
    else if(unitEnum == 3)  //kilometres
        distance = baseDistance * 0.001;
    
    return distance;
}

- (void)setLogDataWithNum:(NSNumber *)logDataNum
{
    if(logDataNum == nil)
        self.logData = YES;
    self.logData = [logDataNum boolValue];
}

- (NSNumber *)getLogDataNumber
{
    return [NSNumber numberWithBool:self.logData];
}

- (NSTimeInterval)intervalSinceStart
{
    if(self.startInstant == nil)
        return 0;
    return [self.startInstant timeIntervalSinceNow];
}

- (NSDate *)startInstant
{
//    //Get the date in order of priority
//    //1. startInstant
//    //2. first location's found date
//    //3. current date
    if(locations.count > 0)
    {
        MyLocation *firstLocation = [locations objectAtIndex:0];
        if(firstLocation.datePopulated)
            startInstant = firstLocation.foundDate;
    }
    return startInstant;
}

- (NSString *)currentDate{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"M/d/yyyy"];
    NSString *currentDate = [dateFormatter stringFromDate:today]; 
    return [NSString stringWithFormat:@"%@",currentDate];
}

- (NSString *)startDate{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"M/d/yyyy"];
    NSString *currentDate = [dateFormatter stringFromDate:self.startInstant]; 
    return [NSString stringWithFormat:@"%@",currentDate];
}

- (NSString *)dateRangeString
{
    if(self.startInstant == nil)
    {
        return [self currentDate];
    }
    else
    {
        NSString *currentDate = [self currentDate];
        NSString *startDate = [self startDate];
        if([currentDate isEqualToString:startDate])
            return currentDate;
            
        return [NSString stringWithFormat:@"%@ - %@",startDate,currentDate];
    }
}


@end
