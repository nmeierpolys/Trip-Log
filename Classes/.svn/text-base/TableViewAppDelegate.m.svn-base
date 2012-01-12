//
//  TableViewAppDelegate.m
//  TableView
//

#import "TableViewAppDelegate.h"
#import "Trip.h"
#import "MyLocation.h"
#import "DetailViewController.h"
#import "RootViewController.h"
#import "SplashScreen.h"

@implementation TableViewAppDelegate

@synthesize window;
@synthesize navigationController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
    // Set the application defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"YES",@"allowBackgroundUpdates",
                   @"",@"defaultEmail",
                   @"10",@"maxIdleTime",
                   @"5",@"updateInterval",
                   nil];
    [defaults registerDefaults:appDefaults];
    [defaults synchronize];
    
	//SplashScreen *dvController = [[SplashScreen alloc] ssinitWithNibName:@"SplashScreen" bundle:[NSBundle mainBundle]];
    
    //Show splash screen briefly
    //[window addSubview:[dvController view]];
	//[window makeKeyAndVisible];
    
    //sleep(2000);
    
	// Configure and show the window
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    id testView = navigationController.viewControllers.lastObject;
    if([testView isKindOfClass:[DetailViewController class]])
    {
        DetailViewController *detailView = navigationController.viewControllers.lastObject;
        [detailView enteringBackground];
    }
    
}
- (void)applicationWillEnterForeground:(UIApplication *)application {
    id testView = navigationController.viewControllers.lastObject;
    if([testView isKindOfClass:[DetailViewController class]])
    {
        DetailViewController *detailView = navigationController.viewControllers.lastObject;
        [detailView enteringForeground];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
	// Save data if appropriate
    
    id testView = navigationController.viewControllers.lastObject;
    if([testView isKindOfClass:[DetailViewController class]])
    {
        DetailViewController *detailView = navigationController.viewControllers.lastObject;
        [detailView saveInfo];
    }
}



- (void)dealloc {
	[navigationController release];
	[window release];
	[super dealloc];
}

@end
