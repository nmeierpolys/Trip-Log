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
#import <Crashlytics/Crashlytics.h>

@implementation TableViewAppDelegate

@synthesize window;
@synthesize navigationController;

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:[exception name] exception:exception];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    
    //Set up exception handler
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    //Start Flurry session
    //[FlurryAnalytics startSession:@"8ESZMG4HR6K4A4IMIEP5"];  //Testing
    [FlurryAnalytics startSession:@"TDS9SNISF6JL6BSBU77K"];  //Release
    //[FlurryAnalytics startSession:@"22SMZTDB4GWNXBJJG7KN"];  //Free
    
    //Testing: 8ESZMG4HR6K4A4IMIEP5
    //Release: TDS9SNISF6JL6BSBU77K
    
    //Attach Flurry to log page views on the navigation controller
    UINavigationController *tmpNavigationController = (UINavigationController *)self.window.rootViewController;
    
    [FlurryAnalytics logAllPageViews:tmpNavigationController];
    
    // Set the application defaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(defaults != nil)
    {
        NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
                       @"YES",@"allowBackgroundUpdates",
                       @"",@"defaultEmail",
                       @"10",@"maxIdleTime",
                       @"5",@"updateInterval",
                       @"YES",@"showRouteLines",
                       @"YES",@"showPins",
                       @"0",@"distanceUnit",
                       @"YES",@"centerOnCurrentLocation",
                       nil];
        [defaults registerDefaults:appDefaults];
        [defaults synchronize];
    }
    
    if ([[options valueForKey:UIApplicationLaunchOptionsLocationKey] boolValue]) {
        NSLog(@"Launched because of location event");
        [FlurryAnalytics logEvent:@"Launched because of location event"];
    }
    
    [Crashlytics startWithAPIKey:@"7a52c82c4c1b6289860e1978cb6337cb9ca2aebc"];
    
	//SplashScreen *dvController = [[SplashScreen alloc] ssinitWithNibName:@"SplashScreen" bundle:[NSBundle mainBundle]];
    
    //Show splash screen briefly
    //[window addSubview:[dvController view]];
	//[window makeKeyAndVisible];
    
    //sleep(2000);
    
	// Configure and show the window
    [self.window setRootViewController:navigationController];
	[window addSubview:[navigationController view]];
	[window makeKeyAndVisible];
    
    // Show tutorial if needed
    bool hasViewedTutorialPart1 = [defaults objectForKey:@"hasViewedTutorialPart1"];
    if(!hasViewedTutorialPart1)
        [self showTutorialAddTrip];
    
    //APIWorker *APIobj = [[APIWorker alloc] init];
    //[APIobj sendIDInfo:@"TripLog"];
    //[Appirater appLaunched:YES];
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
    //[Appirater appEnteredForeground:YES];
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

- (void)showTutorialAddTrip {
    
    UIImageView *imageView = [[UIImageView alloc]
                              initWithImage:[UIImage imageNamed:[self getTutorial1ImageName]]];
    imageView.tag = 111;
    imageView.alpha = 0.8f;
    imageView.frame = self.navigationController.view.frame;
    
    UITapGestureRecognizer * recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapCloseTutorialAddTrip:)];
    recognizer.delegate = self;
    [imageView addGestureRecognizer:recognizer];
    imageView.userInteractionEnabled =  YES;
	[window addSubview:imageView];
}

- (NSString *)getTutorial1ImageName {
    NSString *imageName = @"Tutorial-1";
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        imageName = [imageName stringByAppendingString:@"-iPad"];
    }
    else if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if(result.height == 480)
        {
            imageName = [imageName stringByAppendingString:@"-iPhone3.5in"];
        }
        if(result.height == 568)
        {
            imageName = [imageName stringByAppendingString:@"-iPhone4in"];
        }
    }
    
    return [imageName stringByAppendingString:@".png"];
}

- (void) handleTapCloseTutorialAddTrip:(UITapGestureRecognizer *)recognize
{
    for (UIView *subView in window.subviews)
    {
        if (subView.tag == 111)
        {
            [subView removeFromSuperview];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"hasViewedTutorialPart1"];
            [defaults synchronize];
        }
    }
}

@end
