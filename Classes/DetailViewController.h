//
//  DetailViewController.h
//  TableView 
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Trip.h"
#import "RootViewController.h"
#import "CoreLocationController.h"


@interface DetailViewController : UIViewController <CoreLocationControllerDelegate, MKMapViewDelegate> {
	CoreLocationController *CLController;
    CLGeocoder *reverseGeo;
    
    MyLocation *tempAnnotation;
    
    Trip *selectedTrip;
    
    int selectedLocationIndex;
    
    MKMapView *_mapView; 
    RootViewController *parentTable;
    
    int zoomLevel;
    bool isUpdating;
    bool isInBackground;
    
    NSDate *lastUpdate;
    NSDate *idleTime;
    
    //Outlets
    IBOutlet UIView *summaryView;
    IBOutlet UILabel *summaryTitle;
    IBOutlet UILabel *summaryRight;
    IBOutlet UITextView *summaryBody;
    IBOutlet UILabel *summarySubTitle;
    IBOutlet UISegmentedControl *MapTypeValue;
    
    //Defaults
    bool allowBackgroundUpdates;
    NSString *defaultEmail;
    double maxIdleTime;
    double updateInterval;
}
- (IBAction)btnMapType:(id)sender;

- (IBAction)btnZoom:(id)sender;
- (IBAction)btnToggleText:(id)sender;
@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) CoreLocationController *CLController;
@property (nonatomic, retain) CLGeocoder *reverseGeo;
@property (nonatomic, retain) Trip *selectedTrip;
@property (nonatomic, retain) MyLocation *selectedLocation;
@property (nonatomic, retain) UIViewController *parentTable;
@property (nonatomic, retain) NSDate *lastUpdate;
@property (nonatomic, retain) NSDate *idleTime;
@property CLLocationDegrees previousLat;
@property CLLocationDegrees previousLong;
@property int selectedLocationIndex;
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
- (void)loadDefaults;
- (void)stopMonitoringLocation;
- (void)startMonitoringLocation;


@end
