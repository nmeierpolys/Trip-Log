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
#import "Wrapper.h"
#import "APIWorker.h"
#import "FlurryAnalytics.h"
#import "Appirater.h"

@implementation TableViewAppDelegate

@synthesize window;
@synthesize navigationController;

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:[exception name] exception:exception];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    //Set up exception handler
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    //Start Flurry session
    [FlurryAnalytics startSession:@"8ESZMG4HR6K4A4IMIEP5"];  //Testing
    //[FlurryAnalytics startSession:@"TDS9SNISF6JL6BSBU77K"];  //Release
    //[FlurryAnalytics startSession:@"22SMZTDB4GWNXBJJG7KN"];  //Free
    
    //Testing: 8ESZMG4HR6K4A4IMIEP5
    //Release: TDS9SNISF6JL6BSBU77K
    
    //Attach Flurry to log page views on the navigation controller
    UINavigationController *tmpNavigationController = (UINavigationController *)self.window.rootViewController;
    
    [FlurryAnalytics logAllPageViews:tmpNavigationController];
    
    // Set the application defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"YES",@"allowBackgroundUpdates",
                   @"",@"defaultEmail",
                   @"10",@"maxIdleTime",
                   @"5",@"updateInterval",
                   @"YES",@"showRouteLines",
                   @"YES",@"showPins",
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
    
    //APIWorker *APIobj = [[APIWorker alloc] init];
    //[APIobj sendIDInfo:@"TripLog"];
    [Appirater appLaunched:YES];
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
    [Appirater appEnteredForeground:YES];
    id testView = navigationController.viewControllers.lastObject;
    if([testView isKindOfClass:[DetailViewController class]])
    {
        //APIWorker *APIobj = [[APIWorker alloc] init];
        //[APIobj sendIDInfo:@"TripLog"];
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
