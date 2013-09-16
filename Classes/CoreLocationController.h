//
//  CoreLocationController.h
//  TableView
//
//  Created by Nathaniel Meierpolys on 10/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol CoreLocationControllerDelegate
@required

- (void)locationUpdate:(CLLocation *)location;
- (void)locationError:(NSError *)error;

@end


@interface CoreLocationController : NSObject <CLLocationManagerDelegate> {
	CLLocationManager *locMgr;
	id __unsafe_unretained delegate;
}

@property (nonatomic, strong) CLLocationManager *locMgr;
@property (nonatomic, unsafe_unretained) id delegate;

@end
