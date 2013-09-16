//
//  TableViewAppDelegate.h
//  TableView

#import <UIKit/UIKit.h>
#import "DetailViewController.h"

@interface TableViewAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UINavigationController *navigationController;

@end

