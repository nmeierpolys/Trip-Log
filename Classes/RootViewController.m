//
//  RootViewController.m
//  TableView
//
//

#import "RootViewController.h"
#import "TableViewAppDelegate.h"
#import "DetailViewController.h"
#import "MyLocation.h"
#import "TripsView.h"
#import "Trip.h"
#import "TSAlertView.h"
#import "SplashScreen.h"
#import "FlurryAnalytics.h"
#import "InAppPurchaseManager.h"

#define IsFreeVersion YES

@implementation RootViewController

@synthesize trips;
@synthesize updatedRow;
@synthesize updatedTrip;
@synthesize hasUnsavedChanges;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	//Initialize the array.
	listOfItems = [[NSMutableArray alloc] init];
	
	//Set the title
	self.navigationItem.title = @"Trip Log";
    self.navigationItem.leftBarButtonItem = self.editButtonItem;    
    
    UIBarButtonItem *tempButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTap)];
    self.navigationItem.rightBarButtonItem = tempButton;
    [tempButton release];
    
    //Mine
    trips = [[NSMutableArray alloc] init];    
    [self loadTripListFromPlist];
    //[self loadDummyTrips];
    //[self addTripsFromArray:trips];
    
    updatedRow = -1;
    updatedTrip = nil;
    
    bool isProUpgradePurchased = [[NSUserDefaults standardUserDefaults] boolForKey:@"isProUpgradePurchased"];
} 

- (void) viewDidDisappear:(BOOL)animated{
}

- (void)saveTripListToPlist{
    //Plist path
	
    NSString *plistFile = @"TripLogFreeTrips";
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:plistFile];
    
    //Grab annotations array from _mapView
    NSMutableArray *plistArr = [[NSMutableArray alloc] init];  //array to send to plist
    
    //Move each annotation object into a dictionary and add to plistArr
    NSUInteger count = [trips count];
     
    for (NSUInteger i = 0; i < count; i++) {
        Trip *trip = [trips objectAtIndex:i];
        if(trip != nil){
            if([trip fileName] != nil){   
                if(trip.startInstant == nil)
                    trip.startInstant = [NSDate date];
                NSDictionary *tripInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
                                          [trip tripName],@"tripName",
                                          [trip fileName],@"fileName", 
                                          [trip startInstant],@"startInstant",
                                          nil];
                [plistArr addObject:tripInfo];
            }
        }
    }    
    
    //Write to plist
    [plistArr writeToFile:plistPath atomically:YES];
}

- (void)loadTripListFromPlist{
    
    //Initialize    
    NSArray *plistArr = [[NSArray alloc] init];
    
    //Plist document path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *plistFile = @"TripLogFreeTrips";
    
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:plistFile];
	
    //Populate array from plist
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]){
        plistArr = [NSArray arrayWithContentsOfFile:plistPath];
	} else {;
        return;
	}
    
    //Translate plist array into annotation objects and add to _mapView
    NSUInteger count = [plistArr count];
    for (NSUInteger i = 0; i < count; i++) {
        
        //Retrieve objects out of this element's dictionary
        NSDictionary *tripInfo = [plistArr objectAtIndex:i];
        NSString *tripName = [tripInfo objectForKey:@"tripName"];
        NSString *fileName = [tripInfo objectForKey:@"fileName"];
        
        NSNumber *logDataNum = [NSNumber numberWithBool:YES];
        if([tripInfo objectForKey:@"logData"] != nil)
            logDataNum = (NSNumber *)[tripInfo objectForKey:@"logData"];
        
        NSDate *startInstant = [tripInfo objectForKey:@"startInstant"];
        
        //Build trip, add to trips list and add to table view list
        if(fileName != nil){
            Trip *newTrip = [[Trip alloc] init];
            newTrip.tripName = tripName;
            newTrip.fileName = fileName;
            NSMutableArray *newLocations = [[NSMutableArray alloc] init];
            newTrip.locations = newLocations;
            [newTrip setLogDataWithNum:logDataNum];
            if(startInstant != nil)
                newTrip.startInstant = startInstant;
            [trips addObject:newTrip];
            [listOfItems addObject:tripName];
        }
    }  
    [self loadTripContents];
}


- (void)addNew:(NSString *)tripName {
    [FlurryAnalytics logEvent:@"NewTrip"];
    //Build dummy trip and fill it with basic info
    Trip *newTrip = [[Trip alloc] init];
    NSMutableArray *newLocations = [[NSMutableArray alloc] init];
    
    //Get the next index based on one beyond the last trip in the array.
    Trip *lastTrip = [trips lastObject];
    NSString *lastFileName = lastTrip.fileName;
    NSString *lastIndexStr = [lastFileName substringFromIndex:4];
    lastIndexStr = [lastIndexStr substringToIndex:[lastIndexStr length] - 6];
    int lastIndex = [lastIndexStr intValue];
    int i = lastIndex + 1;
    
    newTrip.tripName = tripName;
    newTrip.fileName = [NSString stringWithFormat:@"temp%db.plist",i];
    newTrip.locations = newLocations; 
    newTrip.logData = YES;
    
    //Add trip to trips array
    [trips addObject:newTrip];
    
    //Add name to tableview list array
    [listOfItems addObject:newTrip.tripName];
    
    //Refresh tableview to show changes
    [self.tableView reloadData];
    
    //Save this new trip
    [self saveTripToPlist:trips.count-1];
    
    //Persist changes to trip list.
    [self saveTripListToPlist];
}

- (void)ShowAddTripDialog
{
    TSAlertView* av = [[[TSAlertView alloc] init] autorelease];
    av.title = @"Trip name:";
    av.message = @"";
    
    [av addButtonWithTitle: @"Ok"];
    [av addButtonWithTitle: @"Cancel"];
    
    
    av.style = TSAlertViewStyleInput;
    av.buttonLayout = TSAlertViewButtonLayoutNormal;
    av.delegate = (id<TSAlertViewDelegate>)self;
    
    [av show];
}

- (void)GetUpgradeOrFailAddTrip
{
    [FlurryAnalytics logEvent:@"triedUpgradeAndBailed"];
    if(inAppPurchaseManager == nil)
    {
        inAppPurchaseManager = [[InAppPurchaseManager alloc] init];
        [inAppPurchaseManager loadStore];
    }
    
    if([inAppPurchaseManager canMakePurchases])
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upgrade to My Trip Log Pro" message:@"Upgrade to the Pro version for $.99 to create additional trips." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Upgrade",nil];
        [alertView show];
    }
}

- (void) addButtonTap
{
    bool isProUpgradePurchased = NO;
    
    //Only check for upgrade if this is the free version (IAP supported)
    //For paid version, it's always purchased.
    if(IsFreeVersion)
    {
        isProUpgradePurchased = [[NSUserDefaults standardUserDefaults] boolForKey:@"isProUpgradePurchased"];
    }
    else 
    {
        isProUpgradePurchased = YES;
    }
    
    //Need to check license when user has more than one trip and 
    //wants to add another
    if((trips.count > 0) && (!isProUpgradePurchased))
    {
        //Give option to purchase upgrade
        [self GetUpgradeOrFailAddTrip];
    }
    else 
    {
        //This is either the first trip created
        //OR
        //User has purchased the pro upgrade
        [self ShowAddTripDialog];
    }

}

- (void)productPurchased:(NSNotification *)notification 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    NSString *productIdentifier = (NSString *) notification.object;
    
    bool isProUpgradePurchased = [[NSUserDefaults standardUserDefaults] boolForKey:@"isProUpgradePurchased"];
    if(isProUpgradePurchased)
    {
        [FlurryAnalytics logEvent:@"upgradePurchased"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Successfully upgraded to Trip Log Pro." message:@"Go wild and create as many trips as you'd like" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        
        [alertView show];
    }
    
}

- (void)productPurchaseFailed:(NSNotification *)notification 
{
    [FlurryAnalytics logEvent:@"upgradePurchaseFailed"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Upgrade failed" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
}

// after animation
- (void) alertView: (TSAlertView *) alertView didDismissWithButtonIndex: (NSInteger) buttonIndex
{
    if([alertView.title isEqualToString:@"Upgrade to My Trip Log Pro"])
    {
        if( buttonIndex == 0 )
            return;
        else 
        {
            [inAppPurchaseManager purchaseProUpgrade];
        }
    }
    else if([alertView.title isEqualToString:@"Successfully upgraded to Trip Log Pro."])
    {
        //Do nothing here
    }
    else if([alertView.title isEqualToString:@"Upgrade failed"])
    {
        //Do nothing here
    }
    else
    {
        // cancel
        if( buttonIndex == 1 )
            return;
        
        NSString *tripName = alertView.inputTextField.text;
        
        if([tripName length] >=1){
            [self addNew:alertView.inputTextField.text];
        }
    }
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated{
    [super setEditing:editing animated:animated];
    if(editing){
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}
   


- (void)viewDidAppear:(BOOL)animated{
    if(!hasUnsavedChanges)
        return;
    if((updatedTrip != nil) && (updatedRow >= 0))
    {
        hasUnsavedChanges = NO;
        if([trips objectAtIndex:updatedRow] != nil){
            [trips replaceObjectAtIndex:updatedRow withObject:updatedTrip];
        }
    }
}

- (void)loadDummyTrips{
    
    int count=5;
    for(int i=1; i<count;i++){
        NSMutableArray *newLocations = [[NSMutableArray alloc] init];
        
        
        Trip *newTrip = [[Trip alloc] init];
        newTrip.tripName = [NSString stringWithFormat:@"My trip name %d",i];
        newTrip.fileName = [NSString stringWithFormat:@"temp%db.plist",i];
        newTrip.locations = newLocations;
        
        [trips addObject:newTrip];
    }
}

- (void)addTripsFromArray:(NSMutableArray *)newTrips{
    int count=newTrips.count;
    for(int i=0;i<count;i++){
        Trip *newTrip = [newTrips objectAtIndex:i];
        if(newTrip != nil){
            [listOfItems addObject:newTrip.tripName];
        }
    }
}
- (void)saveTripToPlist:(int)index {     
    [self saveTripListToPlist];
    
    if(index >= trips.count){
        return;
    }
    
    //Plist path
    NSString *plistFile;
    Trip *selectedTripObj = [trips objectAtIndex:index];
    
    
    if(selectedTripObj != nil)
    {
        plistFile = selectedTripObj.fileName;
    }
    else {
        return;
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:plistFile];
    
    //Grab annotations array from _mapView
    NSMutableArray *plistArr = [[NSMutableArray alloc] init];  //array to send to plist
    NSMutableArray *locations = [selectedTripObj locations];   //array to loop on
    
    //Move each annotation object into a dictionary and add to plistArr
    NSUInteger count = [locations count];
    
    //Flurry SaveTrip event
    NSDictionary *dictionary = 
    [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%i",count], 
     @"NumPoints", 
     nil];
    [FlurryAnalytics logEvent:@"SaveTrip" withParameters:dictionary];
    
    //Save points
    for (NSUInteger i = 0; i < count; i++) {
        MyLocation *location = [locations objectAtIndex:i];
        if(location != nil){
            if([location coordName] != nil){   
                NSDictionary *coord;
                if(location.userNote == nil)
                    location.userNote = @"";
                if((location.datePopulated.boolValue) && [location.foundDate isKindOfClass:[NSDate class]])
                {
                    coord = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [location title],@"name",
                       [location address],@"address",
                       [location latStr],@"latitude",
                       [location longStr],@"longitude", 
                       [location time],@"time",
                       [location userNote],@"userNote",
                       [location datePopulated],@"datePopulated",
                       [location foundDate],@"foundDate",
                       nil];
                }
                else 
                {
                   coord = [[NSDictionary alloc] initWithObjectsAndKeys:
                       [location title],@"name",
                       [location address],@"address",
                       [location latStr],@"latitude",
                       [location longStr],@"longitude", 
                       [location time],@"time",
                       [location userNote],@"userNote",
                       [location datePopulated],@"datePopulated",
                       nil];
                }
                [plistArr addObject:coord];
            }
        }
    }    
    
    //Write to plist
    [plistArr writeToFile:plistPath atomically:YES];
}

- (void)loadTripContents{
    int count = trips.count;
    for(int i=0;i<count;i++){
        [self loadTripFromPlist:i];
    }
}

- (void)loadTripFromPlist:(int)index{

    //Initialize    
    NSArray *plistArr = [[NSArray alloc] init];
    
    //Plist document path
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *plistFile;
    
    Trip *selectedTrip = [trips objectAtIndex:index];
    if(selectedTrip != nil){
        plistFile = selectedTrip.fileName;
    }
    else {
        return;
    }
    
    NSString *plistPath = [documentsDirectory stringByAppendingPathComponent:plistFile];
	
    //Populate array from plist
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]){
        plistArr = [NSArray arrayWithContentsOfFile:plistPath];
	} else {;
        return;
	}
    
    if(plistArr == nil)
        return;
    if(plistArr.count == 0)
        return;
    //Translate plist array into annotation objects and add to _mapView
    NSUInteger count = [plistArr count];
    for (NSUInteger i = 0; i < count; i++) {
        
        //Retrieve objects out of this element's dictionary
        NSDictionary *coord = [plistArr objectAtIndex:i];
        NSString *latitude = [coord objectForKey:@"latitude"];
        NSString *longitude = [coord objectForKey:@"longitude"];
        NSString *name = [coord objectForKey:@"name"];
        NSString *address = [coord objectForKey:@"address"];
        NSString *time = [coord objectForKey:@"time"];
        NSString *userNote = [coord objectForKey:@"userNote"];
        //NSNumber *intervalSinceTripStart = [coord objectForKey:@"intervalSinceTripStart"];
        NSDate *foundDate = [coord objectForKey:@"foundDate"];
        NSNumber *datePopulated = [coord objectForKey:@"datePopulated"];
        
        //Build annotation and add to _mapView
        if((latitude != nil) && (latitude != nil)){
            CLLocationCoordinate2D endCoord;
            MyLocation *location = [[MyLocation alloc] initWithName:name address:address coordinate:endCoord time:time index:i];
            [location setLat:latitude];
            [location setLong:longitude];
            if(userNote == nil)
                userNote = @"";
            [location setUserNote:userNote];
            if(datePopulated.boolValue)
                location.foundDate = foundDate;
            location.datePopulated = datePopulated;
            [selectedTrip addLocation:location];
        }
    }  
    [trips replaceObjectAtIndex:index withObject:selectedTrip];
}


- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:kInAppPurchaseManagerTransactionSucceededNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(productPurchaseFailed:) name:kInAppPurchaseManagerTransactionFailedNotification object: nil];
    
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
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

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [listOfItems count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"MyIdentifier"] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // Set up the cell...
    Trip *tripForCell = [trips objectAtIndex:indexPath.row];
    
    NSString *tripTitle = tripForCell.tripName;
    NSString *tripSubtitle = [[NSString alloc] init];
    
    //Get and format date
    if(false)
    {
        MyLocation *lastPoint = (MyLocation *)tripForCell.locations.lastObject;
        if((lastPoint != nil) && (lastPoint.foundDate != nil))
        {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
            
            id tripDate = [dateFormatter stringFromDate:lastPoint.foundDate]; 
            [dateFormatter release];
            
            tripSubtitle = tripDate;
        }
    }
    
    
    //Add trip count string
    int numLocations = tripForCell.locations.count;
    if(numLocations > 0)
    {
        if(tripSubtitle.length > 0)
            tripSubtitle = [NSString stringWithFormat:@"%@      ",tripSubtitle];
        
        tripSubtitle = [NSString stringWithFormat:@"%@ %i point(s)",tripSubtitle,numLocations];
    }
    
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"imgres" ofType:@"jpeg"];
    
	cell.textLabel.text = tripTitle;
    cell.detailTextLabel.text = tripSubtitle;
    UIImage * backgroundImage = [[UIImage alloc] initWithContentsOfFile:imageName];
    cell.imageView.image = backgroundImage;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//[self saveTripToPlist:indexPath.row];
	[self setEditing:NO animated:NO];
	//Initialize the detail view controller and display it.
    DetailViewController *dvController;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        dvController = [[DetailViewController alloc] initWithNibName:@"DetailViewIPad" bundle:[NSBundle mainBundle]];
    }
    else
    {
        dvController = [[DetailViewController alloc] initWithNibName:@"DetailView" bundle:[NSBundle mainBundle]];
    }
    
    
    if(indexPath.row >= trips.count){
        TSAlertView* av = [[[TSAlertView alloc] init] autorelease];
        av.title = @"Problem";
        av.message = @"Trip exists in table with no plist";
        
        [av addButtonWithTitle: @"Ok"];
        
        av.style = TSAlertViewStyleNormal;
        av.buttonLayout = TSAlertViewButtonLayoutNormal;
        
        [av show];
        return;
    }
    updatedRow = indexPath.row;
    updatedTrip = [trips objectAtIndex:indexPath.row];
    
    dvController.selectedTrip = updatedTrip;
    dvController.parentTable = self;
    
	[self.navigationController pushViewController:dvController animated:YES];
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	//return UITableViewCellAccessoryDetailDisclosureButton;
	return UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}




// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationRight];
        [listOfItems removeObjectAtIndex:indexPath.row];
        [trips removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
    [tableView endUpdates];
    [self saveTripListToPlist];
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


- (void)dealloc {
	
	[listOfItems release];
    [super dealloc];
}

@end

