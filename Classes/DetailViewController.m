//
//  DetailViewController.m
//  TableView
//

#import "DetailViewController.h"
#import "MyLocation.h"
#import "TripsView.h"
#import "Trip.h"
#import <MessageUI/MessageUI.h>
#import <QuartzCore/CoreAnimation.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "FlurryAnalytics.h"
#import "TSAlertView.h"


@implementation DetailViewController
@synthesize mapView = _mapView;
@synthesize CLController;
@synthesize selectedTrip;
@synthesize selectedLocation;
@synthesize parentTable;
@synthesize previousLat;
@synthesize previousLong;
@synthesize reverseGeo;
@synthesize selectedLocationIndex;
@synthesize lastUpdate;
@synthesize idleTime;
@synthesize addresses;
@synthesize appSettingsViewController;
@synthesize route;
@synthesize nextValidPointTime;
@synthesize baseInstant;

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] initWithNibName:@"IASKAppSettingsView" bundle:nil];
		appSettingsViewController.delegate = self;
        appSettingsViewController.showCreditsFooter = false;
	}
	return appSettingsViewController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Set the title of the navigation bar
	self.navigationItem.title = selectedTrip.tripName;
    
    UIBarButtonItem *btnMail = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(openMail)];
    
    NSString* gearImageName = [[NSBundle mainBundle] pathForResource:@"gears" ofType:@"png"];
    UIImage * gearImage = [[UIImage alloc] initWithContentsOfFile:gearImageName];
    
    UIBarButtonItem *btnConfig = [[UIBarButtonItem alloc] initWithImage:gearImage style:UIBarButtonItemStyleBordered target:self action:@selector(openConfig)];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:btnMail,btnConfig, nil];
    
    //Set up delegate for getting map updates
    CLController = [[CoreLocationController alloc] init];
	CLController.delegate = self;
    
    //Geolocation object
    reverseGeo = [[CLGeocoder alloc] init];
    
    isUpdating = true;
    needsFlurryUpdate = true;
    
    //Set up the SummaryView initial location and background image
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    int summaryViewOffset = 0;
    if(screenRect.size.height == 480)
        summaryViewOffset = 38;
    else
        summaryViewOffset = 125;
    [summaryView setCenter:CGPointMake(summaryView.center.x, summaryView.center.y + summaryViewOffset)];
    
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"linen_bg_tile" ofType:@"jpg"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:imageName];
    summaryView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
    [backgroundImage release];
    [summaryView setOpaque:NO];
    
    
    lastUpdate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];   
    
    self.idleTime = [[NSDate alloc] init];
    
    showPins = true;
    
    [self loadDefaults:false];
    
    [self loadAnnotationsToMap];
    
    addresses = [[NSMutableArray alloc] init];
    
    zoomLevel = 1;
    
    [self drawRouteLines];
    if(self.selectedTrip.locations.count < 1)
        self.selectedTrip.logData = YES;
    switchLogData.on = self.selectedTrip.logData;
}
- (void) loadDefaults:(bool)preserveBaseInstant {
    [NSUserDefaults resetStandardUserDefaults];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    allowBackgroundUpdates = [defaults boolForKey:@"allowBackgroundUpdates"];
    defaultEmail = [defaults stringForKey:@"defaultEmail"];
    maxIdleTime = [[defaults stringForKey:@"maxIdleTime"] doubleValue];
    if(maxIdleTime < 1)
        maxIdleTime = 9999999;
    maxIdleTime = maxIdleTime * 60;  //multiply by 60 since t he setting is given in minutes but used in seconds
    updateInterval = [[defaults stringForKey:@"updateInterval"] doubleValue];
    showRouteLines = [defaults boolForKey:@"showRouteLines"];
    showPins = [defaults boolForKey:@"showPins"];
    
    //Reset baseInstant date as current date
    if(!preserveBaseInstant)
    {
        self.baseInstant = [NSDate date];
        self.nextValidPointTime = self.baseInstant;
    }
}

- (double)numSecondsBetweenStartDate:(NSDate *)start andEndDate:(NSDate *)end
{
    if((start == nil) || (end == nil))
        return 0;
    return (double)[end timeIntervalSinceDate:start];
}


//Divide all time into blocks of the user-defined interval.  
//Find start of the next block.
- (void)updateValidPointTimeWithNextValidTime
{
    NSTimeInterval timeDiff = -[self numSecondsBetweenStartDate:[NSDate date] andEndDate:self.baseInstant];
    double diffFromThisIntervalAndExpected = fmod(timeDiff, updateInterval);
    
    NSTimeInterval intervalForNextPoint = timeDiff - diffFromThisIntervalAndExpected + updateInterval;
    self.nextValidPointTime = [self.baseInstant dateByAddingTimeInterval:intervalForNextPoint];
}


- (void)viewDidDisappear:(BOOL)animated{
    [self stopMonitoringLocation];
}
- (void)viewDidAppear:(BOOL)animated{
    [self loadDefaults:false];
    
    if(changedSettings)
    {
        changedSettings = false;
        
        //Change from Showing pins -> not showing pins
        if(previousShowPins && !showPins)
        {
            for (id annotation in _mapView.annotations) {
                if ((![annotation isKindOfClass:[MKUserLocation class]]) && (annotation != nil))
                    [_mapView removeAnnotation:annotation];
            } 
        }
        
        //Change from not showing pins -> showing pins
        if(!previousShowPins && showPins)
        {
            for(MyLocation *location in self.selectedTrip.locations)
            {
                [_mapView addAnnotation:location];
            }
        }
        previousShowPins = showPins;
        
        NSDictionary *dictionary = 
        [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i",allowBackgroundUpdates],  @"allowBackgroundUpdates",
                                                    defaultEmail, @"defaultEmail",
                                                    [NSString stringWithFormat:@"%.0f",maxIdleTime], @"maxIdleTime",
                                                    [NSString stringWithFormat:@"%.0f",updateInterval], @"updateInterval",
                                                    [NSString stringWithFormat:@"%i",showRouteLines], @"showRouteLines",
                                                    [NSString stringWithFormat:@"%i",showPins], @"showPins",
                                                    nil];
        [FlurryAnalytics logEvent:@"loadDefaults" withParameters:dictionary];
    }
    
    if(self.selectedTrip.logData)
        [self startMonitoringLocation];
    else
        [self stopMonitoringLocation];
    
    [self drawRouteLines];
}

- (void)enteringBackground {
    isInBackground = YES;
    if(!allowBackgroundUpdates)
        [self stopMonitoringLocation];
    self.idleTime = [NSDate date];
}
- (void)enteringForeground {
    isInBackground = NO;
    [self loadDefaults:false];
    [self UpdateLogDataState];
    [self drawRouteLines];
}

- (void)stopMonitoringLocation{
    [self saveInfo];
    [CLController.locMgr stopUpdatingLocation];
}
- (void)startMonitoringLocation{
    [CLController.locMgr startUpdatingLocation];
}

- (void)saveInfo{
    parentTable.hasUnsavedChanges = YES;
    parentTable.updatedTrip = selectedTrip; 
    [parentTable saveTripToPlist:parentTable.updatedRow];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [self saveInfo];
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [summaryView release];
    [summaryTitle release];
    [summaryRight release];
    [summaryBody release];
    [summaryTitle release];
    [summarySubTitle release];
    [MapTypeValue release];
    [switchLogData release];
    [super dealloc];
}


- (void)loadAnnotationsToMap {
    [self zoomView:.4];
    //Clear existing mapview annotations
    //[self removeAllAnnotations];
    
    if(showPins)
    {
        for(MyLocation *location in self.selectedTrip.locations){
            [_mapView addAnnotation:location];
        }
    }
    
    [self drawRouteLines];
}

- (void)locationUpdate:(CLLocation *)location {
    
    //Update Flurry user location the first time
    if(needsFlurryUpdate)
    {
        [FlurryAnalytics setLatitude:location.coordinate.latitude
                           longitude:location.coordinate.longitude            
                  horizontalAccuracy:location.horizontalAccuracy            
                    verticalAccuracy:location.verticalAccuracy]; 
        needsFlurryUpdate = false;
    }
    
    [self loadDefaults:true];
    
    //Unsubscribe from updates after a certain amount of idle time
    NSDate *currentTime = [NSDate date];
    NSTimeInterval interval = [currentTime timeIntervalSinceDate:self.idleTime];
    if(isInBackground && (!allowBackgroundUpdates || (interval > maxIdleTime)))
        [self stopMonitoringLocation];
    
    if(![self allowUpdate])
        return;
    
    if(location == nil)
        return;
        
    if((fabsf(previousLat - location.coordinate.latitude) < .00001) &&
       (fabsf(previousLong - location.coordinate.longitude) < .00001))
        return;
    
    [_mapView setCenterCoordinate:location.coordinate];
    
    previousLat = location.coordinate.latitude;
    previousLong = location.coordinate.longitude;
    
    if(isUpdating)
        [self plotData:location.coordinate];     
}

- (void)receivePlacemark:(CLPlacemark *)placemark{
    
    //MyLocation *location = [[selectedTrip locations] lastObject];
    //int count = selectedTrip.locations.count;
    //[location setSubtitle:[placemark.addressDictionary objectForKey:@"Street"]];
    //[[selectedTrip locations] replaceObjectAtIndex:count withObject:location];
}

- (void)locationError:(NSError *)error {
}

- (double)distanceBetweenPoints:(MyLocation *)fromPoint toPoint:(MyLocation *)toPoint unitEnum:(int)unitEnum{
    
    if((fromPoint == nil) || (toPoint == nil))
        return 0;

    //Convert to CLLocations
    CLLocation *fromLocation = [[CLLocation alloc] initWithCoordinate: fromPoint.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    CLLocation *toLocation = [[CLLocation alloc] initWithCoordinate: toPoint.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    
    //Calculate distance in meters
    CLLocationDistance baseDistance = [fromLocation distanceFromLocation:toLocation];
    
    double distance;
    if(unitEnum == 1)  //meters
        distance = baseDistance;
    else if(unitEnum == 2)  //miles
        distance = baseDistance * 0.000621371192;
    else if(unitEnum == 3)  //feet
        distance = baseDistance * 3.280840;
    
    return distance;
}

- (UIImageView *)GetUserNoteImageView
{
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"document_prepare" ofType:@"png"];
    UIImage * image = [[UIImage alloc] initWithContentsOfFile:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [imageView setCenter:CGPointMake(imageView.center.x-3, imageView.center.y+5)];
    [imageView setBounds:CGRectMake(imageView.center.x, imageView.center.y, 16, 16)];
    return imageView;
}

// Generates the custom view for each annotation. Includes icon, color, and callout info.
// Ref: http://stackoverflow.com/questions/5330788/iphone-mapview-annotation-pin-different-color
- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation
{
    MKPinAnnotationView *annotationView = nil;
    if(!showPins)
        return nil;
    
    //Standard pin - no  note entered
    static NSString *defaultID = @"com.invasivecode.pin";
    
    annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:defaultID];
    
    if (annotation != self.mapView.userLocation) {
        MyLocation *location = (MyLocation *)annotation;
        
        if (annotationView == nil) 
            annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:defaultID] autorelease];
        
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop= NO;
        
        if(location.userNote.length > 0)
        {
            UIImageView *imageView = [self GetUserNoteImageView];
            [annotationView addSubview:imageView];
            annotationView.pinColor = MKPinAnnotationColorPurple;
        }
        else {
            for(UIView *view in annotationView.subviews)
            {
                if(view != nil)
                    [view removeFromSuperview];
            }
            
            annotationView.pinColor = MKPinAnnotationColorRed;
        }
    
        UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        //NSInteger annotationValue = [annView indexOfObject:annotation];
        //rightButton.tag = annotationValue;
        [rightButton addTarget:self action:@selector(userNoteButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        annotationView.rightCalloutAccessoryView = rightButton;
        
    } 
    else {
    }
    
    return annotationView;
    
}

- (void)mapView:(MKMapView *)mapView1 didSelectAnnotationView:(MKAnnotationView *)mapView2
{
    if (mapView2.annotation != self.mapView.userLocation) {
        highlightedAnnotation = (MyLocation *)mapView2.annotation;
    }
}

// Fires when user presses the + button in the current location callout view. Pops an alert.
- (void)userNoteButtonPressed
{ 
    selectedLocationIndex = highlightedAnnotation.index;
    
    if((selectedLocationIndex < selectedTrip.locations.count) && 
       (selectedLocationIndex >= 0))
    {
        MyLocation *location = [selectedTrip.locations objectAtIndex:selectedLocationIndex];
        //////Advanced
        TSAlertView* av = [[[TSAlertView alloc] init] autorelease];
        NSString *header = [self pointName:selectedLocationIndex];
        header = [NSString stringWithFormat:@"Point %i (%@)",selectedLocationIndex+1,header];
        
        NSString *subtitle = highlightedAnnotation.address;
        subtitle = [subtitle stringByReplacingOccurrencesOfString:@"\n" withString:@", "];
        if(subtitle.length > 31)
            subtitle = [[subtitle substringToIndex:29] stringByAppendingString:@".."];
        
        NSString *currentNote = location.userNote;
        if(currentNote.length < 1)
            currentNote = @"Add a note:";
        
        av.title = [NSString stringWithFormat:@"%@",header];
        av.message = [NSString stringWithFormat:@"%@\n%@",subtitle,currentNote];
        av.inputTextField.text = location.userNote;
                      
        
        [av addButtonWithTitle: @"Ok"];
        [av addButtonWithTitle: @"Cancel"];
        
        
        av.style = TSAlertViewStyleInput;
        av.buttonLayout = TSAlertViewButtonLayoutNormal;
        av.delegate = (id<TSAlertViewDelegate>)self;
        
        [av show];
    }
}

// This is triggered when the user presses OK or Cancel when adding a note to a point.
// Updates the location in selectedTrip.locations and closes the callout.
- (void) alertView: (TSAlertView *) alertView 
didDismissWithButtonIndex: (NSInteger) buttonIndex
{
    if([[alertView.title substringToIndex:5] isEqualToString:@"Point"])
        {
        // cancel
        if( buttonIndex == 1 )
            return;
        
        NSString *userNote = alertView.inputTextField.text;
            
        MKAnnotationView* aView = [_mapView viewForAnnotation:highlightedAnnotation];
        MyLocation *initialAnnotation = highlightedAnnotation;
            
        //update current location with user note
        MyLocation *highlightedLocationObj = [selectedTrip.locations objectAtIndex:selectedLocationIndex];
        if (userNote.length > 0) {
            highlightedLocationObj.name = [NSString stringWithFormat:@"Point %i: %@",selectedLocationIndex+1,userNote];
        }
        else {
            highlightedLocationObj.name = [NSString stringWithFormat:@"Point %i  (%@)",selectedLocationIndex+1,highlightedLocationObj.time];
        }
        
        highlightedLocationObj.userNote = userNote;
        
        if(initialAnnotation != nil)
            [_mapView removeAnnotation:initialAnnotation];
        [_mapView addAnnotation:highlightedLocationObj];
            
        //Add note icon or clear previous note icon
        if(userNote.length > 0)
        {
            [aView addSubview:[self GetUserNoteImageView]];
            
            NSDictionary *dictionary = 
            [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i",userNote.length],  @"length",nil];
            [FlurryAnalytics logEvent:@"AddNote" withParameters:dictionary];
        }
        
        //Reload callout
        //[_mapView deselectAnnotation:(id <MKAnnotation>)highlightedAnnotation animated:NO];
        [_mapView selectAnnotation:(id <MKAnnotation>)highlightedAnnotation animated:NO];
        if(summaryView.alpha != 0)
            summaryBody.text = [self tripSummary:selectedTrip];
            
        summaryBody.text = [self tripSummary:selectedTrip];
    }
}

- (void)printTripInfo
{
    NSString *debugMsg = @"";
    int count = 0;
    for(MyLocation *location in selectedTrip.locations)
    {
        count++;
        debugMsg = [debugMsg stringByAppendingFormat:@"%i/%i %@\n",count,location.index,location.name];
    }
    
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip info" 
                                                    message:debugMsg
                                                   delegate:self
                                          cancelButtonTitle:@"OK" 
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)plotData:(CLLocationCoordinate2D)coordinate {
    [FlurryAnalytics logEvent:@"NewLocation"];
    
    MyLocation *lastPoint = selectedTrip.locations.lastObject;
    CLLocation *newLocation = [[CLLocation alloc] initWithCoordinate: coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    CLLocation *oldLocation = [[CLLocation alloc] initWithCoordinate: lastPoint.coordinate altitude:1 horizontalAccuracy:1 verticalAccuracy:-1 timestamp:nil];
    
    NSString * name = [self coordinateString:coordinate];
    
    NSString * address;
    if(selectedTrip.locations.count > 1){
        CLLocationDistance distance = [newLocation distanceFromLocation:oldLocation] * 0.000621371192;  //in Miles
        address = [NSString stringWithFormat:@"%.2f Miles from last point",distance];
    } else {
        address = @"";
    }
    
    NSString *time = [self currentTime];
    
    
    int newPointIndex = selectedTrip.locations.count;
    name = [NSString stringWithFormat:@"Point %i  (%@)",newPointIndex+1,time];
    
    tempAnnotation = [[MyLocation alloc] initWithName:name address:address coordinate:coordinate time:time index:newPointIndex];
    //tempAnnotation.intervalSinceTripStart = [selectedTrip intervalSinceStart];
    
    CLGeocoder *geo = [[CLGeocoder alloc] init];
    [geo reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error)
        {
            NSString *subtitle = [NSString stringWithFormat:@"No address: %@",tempAnnotation.coordName];
            [tempAnnotation setSubtitle:subtitle];
            [selectedTrip addLocation:tempAnnotation];
            if(showPins)
                [_mapView addAnnotation:tempAnnotation];    
            
            if(summaryBody.alpha > 0)
            {
                summaryBody.text = [self tripSummary:selectedTrip];
                summarySubTitle.text = [self tripNumPoints:selectedTrip];
            }
            [self drawRouteLines];
        }
        else
        {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            
            NSString *subtitle = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
            
            [tempAnnotation setSubtitle:subtitle];
            [selectedTrip addLocation:tempAnnotation];
            if(showPins)
                [_mapView addAnnotation:tempAnnotation];
            
            if(summaryBody.alpha > 0)
            {
                summaryBody.text = [self tripSummary:selectedTrip];
                summarySubTitle.text = [self tripNumPoints:selectedTrip];
            }
            [self drawRouteLines];
        
        }
    }];
    
}

- (void)updateAnnotations{
    int count = selectedTrip.locations.count;
    if(count <= 0)
        return;
    
    for (int i=0; i<count; i++) {
        NSString *newName = [self pointName:i];
        [[selectedTrip.locations objectAtIndex:i] setName:newName];
        [[_mapView.annotations objectAtIndex:i] setName:newName];
    }
    [self drawRouteLines];
    
}

- (void)drawRouteLines
{
    if(!showRouteLines)
    {
        if(route != nil)
        {
            [self.mapView removeOverlay:route];
            route = nil;
        }
        return;
    }
    //Add drawing of route line
    
    CLLocationCoordinate2D coordinates[self.selectedTrip.locations.count];
    
    int i = 0;
    for (MyLocation *location in self.selectedTrip.locations)
    {
        coordinates[i] = location.coordinate;
        i++;
    }
    
    MKPolyline *newRoute = [MKPolyline polylineWithCoordinates: coordinates count: self.selectedTrip.locations.count];
    [self.mapView addOverlay:newRoute];
    if(route != nil)
        [self.mapView removeOverlay:route];
    route = newRoute;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    MKPolylineView *polylineView = [[[MKPolylineView alloc] initWithPolyline:overlay] autorelease];
    polylineView.strokeColor = [UIColor blueColor];
    polylineView.lineWidth = 4.0;
    
    return polylineView;
    
}
- (NSString *)pointName:(int)index{
    if(index <0)
        return @"";
    
    MyLocation *pointLocation = [[selectedTrip locations] objectAtIndex:index];
    
    if(pointLocation == nil)
        return @"";
    
    //Format time
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm:ss a"];
    
    NSString *currentTime;
    if(pointLocation.foundDate == nil)
        currentTime = @"";
    else
        currentTime = [dateFormatter stringFromDate:[NSDate date]]; //pointLocation.foundDate
    [dateFormatter release];
    
    //Build name
    NSString *name = [NSString stringWithFormat:@"%@",currentTime];
    
    return name; 
}

- (NSString *)currentTime{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"h:mm:ss a"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    [dateFormatter release];
    return [NSString stringWithFormat:@"%@",currentTime];
}

- (NSString *)currentDate{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSString *currentDate = [dateFormatter stringFromDate:today]; 
    [dateFormatter release];
    return [NSString stringWithFormat:@"%@",currentDate];
}

- (NSString *)locationString:(CLLocation *)location {
    NSString *output = [NSString stringWithFormat:@"(%f,%f)",location.coordinate.latitude,location.coordinate.longitude];
    return output;
}
- (NSString *)coordinateString:(CLLocationCoordinate2D)coordinate {
    NSString *output = [NSString stringWithFormat:@"(%f,%f)",coordinate.latitude,coordinate.longitude];
    return output;
}

- (NSString *)tripSummary:(Trip *)trip{ 
    NSString *output = [[NSString alloc] init];
    NSString *distances = [NSString stringWithFormat:@"Cumulative Distance: %@\n",
                           [trip cumulativeDistanceAutoformatted]];
    distances = [distances stringByAppendingFormat:@"Direct Distance: %@\n",
                           [trip directDistanceAutoformatted]];
                 
    output = distances;
    NSString *interval = @"";
    int count = trip.locations.count;
    for(int i=0;i<count;i++){
        MyLocation *location = [trip.locations objectAtIndex:i];
        if(location.datePopulated)
            interval = [self formattedIntervalSinceStart:selectedTrip.startInstant andDate:location.foundDate];
        
        if(interval.length > 0)
            interval = [NSString stringWithFormat:@", %@",interval];
        
        if((location != nil) && (location.subtitle != nil) && [location.subtitle isKindOfClass:[NSString class]]){        
            NSString *formattedSubtitle = [location.subtitle stringByReplacingOccurrencesOfString:@"\n" withString:@", "];
            
            output = [output stringByAppendingFormat:@"%i. %@ (%@%@)\n",i+1,formattedSubtitle,location.time,interval];
            
            if(location.userNote.length > 0)
                output = [output stringByAppendingFormat:@" -- %@\n\n",location.userNote];
        }
    }
    return output;
}



- (NSString *)formattedIntervalSinceStart:(NSDate *)startDate andDate:(NSDate *)endDate
{
    if((endDate == nil) || (startDate == nil))
        return @"";
    NSTimeInterval interval = [endDate timeIntervalSinceDate:startDate];
    int hours = floor(interval/3600);
    int minutes = floor((interval-(hours*3600))/60);
    int seconds = round(interval - (hours *3600) - (minutes * 60));
    NSString *output = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,seconds];
    return output;
}

- (NSString *)tripNumPoints:(Trip *)trip{ 
    NSString *output = [[NSString alloc] init];
    
    int count = trip.locations.count;
    output = [NSString stringWithFormat:@"Points: %i",count];
    return output;
}

- (IBAction)btnMapType:(id)sender {
    int selectedIndex = MapTypeValue.selectedSegmentIndex;
    if(selectedIndex == 0)
        _mapView.mapType = MKMapTypeStandard;
    else if(selectedIndex == 1)
        _mapView.mapType = MKMapTypeSatellite;
    else
        _mapView.mapType = MKMapTypeHybrid;
}

- (IBAction)btnZoom:(id)sender {
    double spanRatio;
    if(zoomLevel == 0){
        spanRatio = 5;
        zoomLevel = 1;
    } else if(zoomLevel == 1) {
        spanRatio = .5;
        zoomLevel = 2;
    } else if(zoomLevel == 2) {
        spanRatio = .1;
        zoomLevel = 3;
    } else if(zoomLevel == 3) {
        spanRatio = .05;
        zoomLevel = 4;
    } else {
        spanRatio = .001;
        zoomLevel = 0;
    }
    [self zoomView:spanRatio];
}

- (void)zoomView:(double) zoomLevelLocal{
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = zoomLevelLocal;
    span.longitudeDelta = zoomLevelLocal;
    
    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(0,0);
    //CLLocationCoordinate2D location = _mapView.userLocation.coordinate;
        //If the user location is unknown (0,0), center the map on the last point
    //in the selected trip's array.
    if((location.latitude == 0) && (location.longitude == 0) && (selectedTrip.locations.count > 0))
    {
        MyLocation *lastLocation = selectedTrip.locations.lastObject;
        if(lastLocation != nil)
            location = lastLocation.coordinate;
    }
    
    region.span = span;
    region.center = location;
    
    [_mapView setRegion:region animated:TRUE];
}

//Removes from both the mapView annotations array and the Trip locations array
- (void)removeAllAnnotations {
    
    //Clear from mapView annotations
    for (id annotation in _mapView.annotations) {
        if ((![annotation isKindOfClass:[MKUserLocation class]]) && (annotation != nil))
            [_mapView removeAnnotation:annotation];
    } 
    
    //Clear from Trip locations
    [[selectedTrip locations] removeAllObjects];
        
}

- (bool)allowUpdate {
    if(selectedTrip.locations.count < 1)
    {
        lastUpdate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];  
        [self updateValidPointTimeWithNextValidTime];
        return true;
    }
    
    //Now, we just care if CurrentDate > nextVAlidPointTime
    if([self.nextValidPointTime timeIntervalSinceNow] < 0)
    {
        [self updateValidPointTimeWithNextValidTime];
        return true;
    }
    
    return false;
}

- (IBAction)btnToggleText:(id)sender {

    if(summaryView.alpha == 0){    
        summaryTitle.text = selectedTrip.tripName;
        summaryRight.text = [selectedTrip dateRangeString];
        summarySubTitle.text = [self tripNumPoints:selectedTrip];
        summaryBody.text = [self tripSummary:selectedTrip]; 
        summaryBody.alpha = 1;
        summaryBody.userInteractionEnabled = YES;
        
        summaryView.alpha = 1;   
        //Animate in summary view
        [UIView setAnimationDelegate:self];
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            summaryView.transform = CGAffineTransformMakeTranslation (0, -375);
            _mapView.transform = CGAffineTransformMakeTranslation(0,-225);
        } else {
            
            summaryView.transform = CGAffineTransformMakeTranslation (0, -106);
            _mapView.transform = CGAffineTransformMakeTranslation(0,-50);
        }
        
        [UIView commitAnimations];
        
    } else {
        //Animate out summary view
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        
        summaryView.transform = CGAffineTransformMakeTranslation (0, 0);
        _mapView.transform = CGAffineTransformMakeTranslation(0, 0);
        
        summaryView.alpha = 0;
        
        
        [UIView commitAnimations];
    }
}

- (IBAction)switchLogDataChanged:(id)sender {
    [self UpdateLogDataState];
}

- (void)UpdateLogDataState {
    self.selectedTrip.logData = switchLogData.on;
    
    //Turn on monitoring if set to ON.  Turn it off otherwise.
    if(self.selectedTrip.logData)
    {
        [self loadDefaults:false];
        [self startMonitoringLocation];
    }
    else
    {
        [self stopMonitoringLocation];
    }
}

- (void)openConfig
{
    previousShowPins = showPins;
	self.appSettingsViewController.showDoneButton = NO;
	[self.navigationController pushViewController:self.appSettingsViewController animated:YES];
    changedSettings = true;
}

- (void)openMail
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        mailer.mailComposeDelegate = self;
        
        NSString *subject = [NSString stringWithFormat:@"Trip Log history for Trip: %@",selectedTrip.tripName];
        NSString *contents = [self tripSummary:selectedTrip];
        
        [mailer setSubject:subject];
        
        if(defaultEmail.length > 0)
        {
            NSArray *toRecipients = [NSArray arrayWithObjects:defaultEmail, nil];
            [mailer setToRecipients:toRecipients];
        }
        UIGraphicsBeginImageContext(self.mapView.frame.size);
        [self.mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData *imageData = UIImagePNGRepresentation(image);
        
        [mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"My Trip Log trip.jpg"];
        
        [mailer setMessageBody:contents isHTML:NO];
        
        [self presentModalViewController:mailer animated:YES];
        
        [mailer release];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure" 
                                                        message:@"Your device doesn't support the composer sheet" 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }
    
}

//-(void)saveImage{       
//    CGImageRef screen = UIGetScreenImage();
//    UIImage* image = [UIImage imageWithCGImage:screen];
//    CGImageRelease(screen);
//    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//    
//    NSData *imageData = UIImagePNGRepresentation(image);
//}



#pragma mark - MFMailComposeController delegate


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
    NSString *message;
	switch (result)
	{
		case MFMailComposeResultCancelled:
			message = @"Cancelled";
			break;
		case MFMailComposeResultSaved:
			message = @"Saved";
			break;
		case MFMailComposeResultSent:
			message = @"Sent";
			break;
		case MFMailComposeResultFailed:
			message = @"Failed";
			break;
		default:
			message = @"Sent";
			break;
	}
    
    //Flurry SendMail event
    NSDictionary *dictionary = 
    [NSDictionary dictionaryWithObjectsAndKeys:message, 
     @"SendMailResult", 
     nil];
    [FlurryAnalytics logEvent:@"SendMail" withParameters:dictionary];
    
	[self dismissModalViewControllerAnimated:YES];
}


- (void)viewDidUnload {
    [summaryView release];
    summaryView = nil;
    [summaryRight release];
    summaryRight = nil;
    [summaryBody release];
    summaryBody = nil;
    [summaryTitle release];
    summaryTitle = nil;
    [summarySubTitle release];
    summarySubTitle = nil;
    [MapTypeValue release];
    MapTypeValue = nil;
    [switchLogData release];
    switchLogData = nil;
    [super viewDidUnload];

}
@end
