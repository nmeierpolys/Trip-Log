//
//  DetailViewController.h
//  TableView 
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <AddressBook/AddressBook.h>
#import "Trip.h"
#import "RootViewController.h"
#import "CoreLocationController.h"
#import "IASKAppSettingsViewController.h"


@interface DetailViewController : UIViewController <CoreLocationControllerDelegate, 
                                                    MKMapViewDelegate, 
                                                    MFMailComposeViewControllerDelegate> {
	CoreLocationController *CLController;
    CLGeocoder *reverseGeo;
    MKPolyline *route;
    
    MyLocation *tempAnnotation;
    
    Trip *selectedTrip;
    
    int selectedLocationIndex;
                                                        
    MyLocation *highlightedAnnotation;
                                                        
    MKMapView *_mapView; 
    RootViewController *parentTable;
    
    int zoomLevel;
    bool isUpdating;
    bool isInBackground;
    bool changedSettings;
    bool needsFlurryUpdate;
    
    NSDate *lastUpdate;
    NSDate *idleTime;
    NSDate *nextValidPointTime;
    NSDate *baseInstant;    
                                                        
    //Outlets
    IBOutlet UIView *summaryView;
    IBOutlet UILabel *summaryTitle;
    IBOutlet UILabel *summaryRight;
    IBOutlet UITextView *summaryBody;
    IBOutlet UILabel *summarySubTitle;
    IBOutlet UISegmentedControl *MapTypeValue;
    IBOutlet UISwitch *switchLogData;
    
    //Defaults
    bool allowBackgroundUpdates;
    NSString *defaultEmail;
    double maxIdleTime;
    double updateInterval;
    bool showRouteLines;
    bool showPins;
    bool previousShowPins;
    int distanceUnit;
    bool centerOnCurrentLocation;
    
    //InAppSettings view
    IASKAppSettingsViewController *appSettingsViewController;
}


- (IBAction)btnMapType:(id)sender;

- (IBAction)btnZoom:(id)sender;
- (IBAction)btnToggleText:(id)sender;
- (IBAction)switchLogDataChanged:(id)sender;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CoreLocationController *CLController;
@property (nonatomic, strong) CLGeocoder *reverseGeo;
@property (nonatomic, strong) Trip *selectedTrip;
@property (nonatomic, strong) MyLocation *selectedLocation;
@property (nonatomic, strong) UIViewController *parentTable;
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, strong) NSDate *idleTime;
@property (nonatomic, strong) MKPolyline *route;
@property CLLocationDegrees previousLat;
@property CLLocationDegrees previousLong;
@property int selectedLocationIndex;
@property (nonatomic, strong)
    NSMutableArray *addresses;
@property (nonatomic, strong) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic, strong) NSDate *nextValidPointTime;
@property (nonatomic, strong) NSDate *baseInstant;
- (void)zoomView:(double) zoomLevelLocal;
- (void)loadAnnotationsToMap;
- (void)saveInfo;
- (void)plotData:(CLLocationCoordinate2D)coordinate;
- (NSString *)coordinateString:(CLLocationCoordinate2D)coordinate;
- (NSString *)currentTime;
- (NSString *)tripSummary:(Trip *)trip;
- (NSString *)tripNumPoints:(Trip *)trip;
- (void)receivePlacemark:(CLPlacemark *)placemark;
- (NSString *)pointName:(int)index;
- (void)updateAnnotations;
- (void)openMail;
- (void)saveImage;
- (bool)allowUpdate;
- (void)enteringBackground;
- (void)enteringForeground;
- (void)loadDefaults:(bool)preserveBaseInstant;
- (void)stopMonitoringLocation;
- (void)startMonitoringLocation;
- (void)updateValidPointTimeWithNextValidTime;

@end
