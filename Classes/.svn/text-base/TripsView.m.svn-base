//
//  TripsView.m
//  Trip Log
//
//  Created by Nathaniel Meierpolys on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TripsView.h"
#import "Trip.h"

@implementation TripsView
@synthesize trips;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        trips = [[NSMutableArray alloc] init];
        [self populateList];
    }
    return self;
}

- (void)populateList{
	listOfItems = [[NSMutableArray alloc] init];
    int count = [trips count];
    
    for(int i=0;i<count;i++){
        NSString *tripName = [[trips objectAtIndex:i] tripName];
        [listOfItems addObject:tripName];        
    }
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
	listOfItems = [[NSMutableArray alloc] init];
	
	//Add items
    //	[listOfItems addObject:@"Iceland"];
    //	[listOfItems addObject:@"Greenland"];
    //	[listOfItems addObject:@"Switzerland"];
    //	[listOfItems addObject:@"Norway"];
    //	[listOfItems addObject:@"New Zealand"];
    //	[listOfItems addObject:@"Greece"];
    //	[listOfItems addObject:@"Italy"];
    //	[listOfItems addObject:@"Ireland"];
}


- (void)addTripsFromArray:(NSMutableArray *)newTrips{
    int numTrips = newTrips.count;
    for(int i=0;i<numTrips;i++){
        Trip *thisTrip = [newTrips objectAtIndex:i];
        [listOfItems addObject:thisTrip.tripName];
    } 
}
    
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)btnBackClicked:(id)sender {
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
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Set up the cell...
	NSString *cellValue = [listOfItems objectAtIndex:indexPath.row];
	cell.textLabel.text = cellValue;
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//Get the selected country
	//NSString *selectedTrip = [listOfItems objectAtIndex:indexPath.row];
	
	//Initialize the detail view controller and display it.
    
    if(indexPath.row == 1){
        //demoView.selectedTrip = @"annotations.plist";
    }
    else{
        //demoView.selectedTrip = @"annotations2.plist";
    }
    //demoView.selectedTripIndex = indexPath.row;
    
    //self.view = demoView.view;
}

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	//return UITableViewCellAccessoryDetailDisclosureButton;
	return UITableViewCellAccessoryDisclosureIndicator;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
