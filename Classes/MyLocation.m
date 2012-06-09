//
//  MyLocation.m
//  Trip Log
//
//  Created by Nathaniel Meierpolys on 9/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MyLocation.h"

@implementation MyLocation
@synthesize name = _name;
@synthesize address = _address;
@synthesize coordinate = _coordinate;
@synthesize foundDate = _foundDate;
@synthesize time;
@synthesize userNote = _userNote;
@synthesize index = _index;
@synthesize intervalSinceTripStart = _intervalSinceTripStart;
@synthesize datePopulated = _datePopulated;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate index:(int)newIndex{
    if ((self = [super init])) {
        _name = [name copy];
        _address = [address copy];
        _coordinate = coordinate;
        self.foundDate = [NSDate date];
        time = @"";
        userNote = @"";
        _index = newIndex;
        self.datePopulated = [NSNumber numberWithBool:YES];
    }
    return self;
}

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate time:(NSString*)timeIn index:(int)newIndex{
    if ((self = [super init])) {
        _name = [name copy];
        _address = [address copy];
        _coordinate = coordinate;
        self.foundDate = [NSDate date];
        self.time = timeIn;
        userNote = @"";
        _index = newIndex;
        self.datePopulated = [NSNumber numberWithBool:YES];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if ((self = [super init])) {
        _name = [dictionary objectForKey:@"name"];
        _address = [dictionary objectForKey:@"address"];
        time = [dictionary objectForKey:@"time"];
        userNote = [dictionary objectForKey:@"userNote"];
        if(userNote == nil)
            userNote = @"";
        NSNumber *indexNum = (NSNumber *)[dictionary objectForKey:@"index"];
        _index = [indexNum intValue];
        self.datePopulated = [NSNumber numberWithBool:YES];
    }
    [self setLat:[dictionary objectForKey:@"latitude"]];
    [self setLong:[dictionary objectForKey:@"longitude"]];
    
    self.foundDate = [NSDate date];
     
    return self;
}

- (NSDictionary *)convertToDictionary{    
    NSNumber *indexNum = [NSNumber numberWithInt:_index];
    NSDictionary *output = [[NSDictionary alloc] initWithObjectsAndKeys:
                           _name,@"name",
                           _address,@"address",
                            time,@"time",
                           [self latStr],@"latitude",
                           [self longStr],@"longitude", 
                           _userNote,@"userNote",
                           indexNum,@"index",
                           nil];
    return output;
}

- (NSString *)title {
    return _name;
}

- (NSString *)subtitle {
    return _address;
}

- (NSString *)coordName {            
    NSString *output = [NSString stringWithFormat:@"(%.4f, %.4f)",_coordinate.latitude,_coordinate.longitude];
    return output;
}

- (NSString *)latStr {
    return [NSString stringWithFormat:@"%f",_coordinate.latitude];
}

- (NSString *)longStr {
    return [NSString stringWithFormat:@"%f",_coordinate.longitude];
}

- (void)setLat:(NSString *)latStr{
    CLLocationDegrees latDegree = [latStr doubleValue];
    _coordinate.latitude = latDegree;
}

- (void)setLong:(NSString *)longStr{
    CLLocationDegrees longDegree = [longStr doubleValue];
    _coordinate.longitude = longDegree;
}

- (void)setSubtitle:(NSString *)subtitle{
    [subtitle retain];
    _address = subtitle;
}

//- (NSNumber *)getIntervalSinceTripStartNum
//{
//    return [NSNumber numberWithDouble:self.intervalSinceTripStart];
//}
//
//- (void)setIntervalSinceTripStart:(NSNumber *)numToSet
//{
//    //if(numToSet == nil)
//        self.intervalSinceTripStart = 0;
//    //self.intervalSinceTripStart = [numToSet doubleValue];
//    
//}

- (void)dealloc
{
    [_name release];
    _name = nil;
    [_address release];
    _address = nil; 
    [time release];
    time = nil;   
    [super dealloc];
}

@end