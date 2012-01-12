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
    
}

@property (copy) NSString *name;
@property (copy) NSString *address;
@property (copy) NSString *time;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSDate *foundDate;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate;

- (id)initWithName:(NSString*)name address:(NSString*)address coordinate:(CLLocationCoordinate2D)coordinate time:(NSString*)time;
- (id)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)convertToDictionary;

- (NSString *)coordName;

- (NSString *)latStr;
- (NSString *)longStr;

- (void)setLat:(NSString *)latStr;
- (void)setLong:(NSString *)longStr;
- (void)setSubtitle:(NSString *)subtitle;

@end
