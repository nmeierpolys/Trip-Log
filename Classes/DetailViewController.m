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
    [self startMonitoringLocation];
    
    //Geolocation object
    reverseGeo = [[CLGeocoder alloc] init];
    
    isUpdating = true;
    
    [summaryView setCenter:CGPointMake(summaryView.center.x, summaryView.center.y +38)];
    
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"linen_bg_tile" ofType:@"jpg"];
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:imageName];
    summaryView.backgroundColor = [UIColor colorWithPatternImage:backgroundImage];
    [backgroundImage release];
    [summaryView setOpaque:NO];
    
    lastUpdate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];   
    
    self.idleTime = [[NSDate alloc] init];
    
    [self loadAnnotationsToMap];
    
    [self loadDefaults];
    
    addresses = [[NSMutableArray alloc] init];
    
    zoomLevel = 1;
}
- (void) loadDefaults {
    [NSUserDefaults resetStandardUserDefaults];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    allowBackgroundUpdates = [defaults boolForKey:@"allowBackgroundUpdates"];
    defaultEmail = [defaults stringForKey:@"defaultEmail"];
    maxIdleTime = [[defaults stringForKey:@"maxIdleTime"] doubleValue];
    if(maxIdleTime < 1)
        maxIdleTime = 9999999;
    maxIdleTime = maxIdleTime * 60;  //multiply by 60 since the setting is given in minutes but used in seconds
    updateInterval = [[defaults stringForKey:@"updateInterval"] doubleValue];
}

- (void)viewDidDisappear:(BOOL)animated{
    [self stopMonitoringLocation];
    [self saveInfo];
}
- (void)viewDidAppear:(BOOL)animated{
    [self startMonitoringLocation];
}

- (void)enteringBackground {
    isInBackground = YES;
    if(!allowBackgroundUpdates)
        [self stopMonitoringLocation];
    self.idleTime = [NSDate date];
}
- (void)enteringForeground {
    isInBackground = NO;
    [self loadDefaults];
    [self startMonitoringLocation];
}

- (void)stopMonitoringLocation{
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
    [super dealloc];
}


- (void)loadAnnotationsToMap {
    [self zoomView:.4];
    //Clear existing mapview annotations
    //[self removeAllAnnotations];
    
    NSMutableArray *locations = [selectedTrip locations];
    
	int count = locations.count;
    for(int i=0;i<count;i++){
        MyLocation *location = [locations objectAtIndex:i];
        [_mapView addAnnotation:location];
    }
    [self drawRouteLines];
    
}

- (void)locationUpdate:(CLLocation *)location {
    [self loadDefaults];    
    
    //Unsubscribe from updates after a certain amount of idle time
    NSDate *currentTime = [NSDate date];
    NSTimeInterval interval = [currentTime timeIntervalSinceDate:self.idleTime];
    
    if(isInBackground && (!allowBackgroundUpdates || (interval > maxIdleTime)))
        [self stopMonitoringLocation];
    
    
    if(location == nil)
        return;
    
    if(![self allowUpdate])
        return;
    
    if((previousLat == location.coordinate.latitude) && 
       (previousLong == location.coordinate.longitude))
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

- (void)plotData:(CLLocationCoordinate2D)coordinate {
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
    
    
    int newPointIndex = selectedTrip.locations.count + 1;
    name = [NSString stringWithFormat:@"Point %i  (%@)",newPointIndex,time];
    
    tempAnnotation = [[MyLocation alloc] initWithName:name address:address coordinate:coordinate time:time];
    
    CLGeocoder *geo = [[CLGeocoder alloc] init];
    [geo reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if(error)
        {
            NSString *subtitle = [NSString stringWithFormat:@"No address: %@",tempAnnotation.coordName];
            [tempAnnotation setSubtitle:subtitle];
            [selectedTrip addLocation:tempAnnotation];
            [_mapView addAnnotation:tempAnnotation];    
            
            summaryBody.text = [self tripSummary:selectedTrip];
            summarySubTitle.text = [self tripNumPoints:selectedTrip];
        }
        else
        {
            CLPlacemark *placemark = [placemarks objectAtIndex:0];
            
            NSString *subtitle = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
            
            [tempAnnotation setSubtitle:subtitle];
            [selectedTrip addLocation:tempAnnotation];
            [_mapView addAnnotation:tempAnnotation];
            
            summaryBody.text = [self tripSummary:selectedTrip];
            summarySubTitle.text = [self tripNumPoints:selectedTrip];
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
    [self.mapView removeOverlay:route];
    route = newRoute;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    MKPolylineView *polylineView = [[[MKPolylineView alloc] initWithPolyline:overlay] autorelease];
    polylineView.strokeColor = [UIColor blueColor];
    polylineView.lineWidth = 2.0;
    
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
    int count = trip.locations.count;
    for(int i=0;i<count;i++){
        MyLocation *location = [trip.locations objectAtIndex:i];
        
        if((location != nil) && (location.subtitle != nil) && [location.subtitle isKindOfClass:[NSString class]]){        
            NSString *formattedSubtitle = [location.subtitle stringByReplacingOccurrencesOfString:@"\n"
                                                                        withString:@", "];
            output = [output stringByAppendingFormat:@"%i. %@ (%@)\n",i+1,formattedSubtitle,location.time];
        }
    }
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
        spanRatio = .1;
        zoomLevel = 2;
    } else if(zoomLevel == 2) {
        spanRatio = .05;
        zoomLevel = 3;
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
        if (![annotation isKindOfClass:[MKUserLocation class]])
            [_mapView removeAnnotation:annotation];
    } 
    
    //Clear from Trip locations
    [[selectedTrip locations] removeAllObjects];
        
}

- (bool)allowUpdate {
    if(selectedTrip.locations.count < 1){
        lastUpdate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];  
        return true;
    }
    
    NSDate *currentTime = [NSDate date];
    NSTimeInterval secondsSinceUpdate = [currentTime timeIntervalSinceDate:lastUpdate];
    
    if(secondsSinceUpdate >= updateInterval){
        lastUpdate = [[NSDate alloc] initWithTimeIntervalSinceNow:0];  
        return true;
    } else {
        return false;
    }
}

- (IBAction)btnToggleText:(id)sender {

    if(summaryView.alpha == 0){    
        
        summaryBody.text = [self tripSummary:selectedTrip];
        summaryTitle.text = selectedTrip.tripName;
        summaryRight.text = [self currentDate];
        summarySubTitle.text = [self tripNumPoints:selectedTrip];
        
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

- (void)openConfig
{
	self.appSettingsViewController.showDoneButton = NO;
	[self.navigationController pushViewController:self.appSettingsViewController animated:YES];
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

-(void)saveImage{       
    CGImageRef screen = UIGetScreenImage();
    UIImage* image = [UIImage imageWithCGImage:screen];
    CGImageRelease(screen);
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    NSData *imageData = UIImagePNGRepresentation(image);
}



#pragma mark - MFMailComposeController delegate


- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	switch (result)
	{
		case MFMailComposeResultCancelled:
			NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued");
			break;
		case MFMailComposeResultSaved:
			NSLog(@"Mail saved: you saved the email message in the Drafts folder");
			break;
		case MFMailComposeResultSent:
			NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send the next time the user connects to email");
			break;
		case MFMailComposeResultFailed:
			NSLog(@"Mail failed: the email message was nog saved or queued, possibly due to an error");
			break;
		default:
			NSLog(@"Mail not sent");
			break;
	}
    
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
    [super viewDidUnload];

}
@end
