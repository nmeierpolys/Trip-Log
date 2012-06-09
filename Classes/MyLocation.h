//
//  MyLocation.h
//  Trip Log
//
//  Created by Nathaniel Meierpolys on 9/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyLocation : NSObject <MKAnnotation> {
    NSString *_name;
    NSString *_address;
    CLLocationCoordinate2D _coordinate;
    NSDate *foundDate;
    NSString *time;
    NSString *userNote;
    int index;
    NSTimeInterval intervalSinceTripStart;
    NSNumber *datePopulated;
}

@property (copy) NSString *name;
@property (copy) NSString *address;
@property (copy) NSString *time;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (copy) NSDate *foundDate;
@property (copy) NSString *userNote;
@property int index;
@property NSTimeInterval intervalSinceTripStart;
@property (copy) NSNumber *datePopulated;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate index:(int)newIndex;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate time:(NSString*)time index:(int)newIndex;

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)convertToDictionary;

- (NSString *)coordName;

- (NSString *)latStr;
- (NSString *)longStr;

- (void)setLat:(NSString *)latStr;
- (void)setLong:(NSString *)longStr;
- (void)setSubtitle:(NSString *)subtitle;
- (NSNumber *)getIntervalSinceTripStartNum;
- (void)setIntervalSinceTripStartNum:(NSNumber *)numToSet;

@end
