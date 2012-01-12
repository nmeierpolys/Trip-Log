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
}

@property (retain, nonatomic) NSMutableArray *locations;
@property (retain, nonatomic) NSString *tripName;
@property (retain, nonatomic) NSString *fileName;

- (void)addLocation:(MyLocation *)location;
- (void)clearLocations;
- (void)loadData;
- (void)saveData;

@end
