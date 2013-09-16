//
//  TripsView.h
//  Trip Log
//
//  Created by Nathaniel Meierpolys on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TripsView : UIViewController {
	NSMutableArray *listOfItems;
    NSMutableArray *trips;
}
@property (nonatomic, strong) NSMutableArray *trips;

- (IBAction)btnBackClicked:(id)sender;

- (void)populateList;
- (void)addTripsFromArray:(NSMutableArray *)newTrips;

@end
