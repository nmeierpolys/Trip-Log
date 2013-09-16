//
//  RootViewController.h
//  TableView
//

#import <UIKit/UIKit.h>
#import "Trip.h"

@interface RootViewController : UITableViewController <UIApplicationDelegate> {
	
	NSMutableArray *listOfItems;
    NSMutableArray *trips;
    int updatedRow;
    Trip *updatedTrip;
    bool hasUnsavedChanges;
}

@property (nonatomic, strong) NSMutableArray *trips;
@property int updatedRow;
@property (nonatomic, strong) Trip *updatedTrip;
@property bool hasUnsavedChanges;

- (void)loadDummyTrips;
- (void)addTripsFromArray:(NSMutableArray *)newTrips;
- (void)saveTripToPlist:(int)index;
- (void)addNew:(NSString *)tripName;
- (void)importTap;
- (void)loadTripContents;
- (void)loadTripFromPlist:(int)index;
- (void)saveTripListToPlist;
- (void)loadTripListFromPlist;


@end
