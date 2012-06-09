//
//  RootViewController.h
//  TableView
//

#import <UIKit/UIKit.h>
#import "Trip.h"
#import "InAppPurchaseManager.h"

@interface RootViewController : UITableViewController <UIApplicationDelegate> {
	
	NSMutableArray *listOfItems;
    NSMutableArray *trips;
    int updatedRow;
    Trip *updatedTrip;
    bool hasUnsavedChanges;
    InAppPurchaseManager *inAppPurchaseManager;
}

@property (nonatomic, retain) NSMutableArray *trips;
@property int updatedRow;
@property (nonatomic, retain) Trip *updatedTrip;
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
