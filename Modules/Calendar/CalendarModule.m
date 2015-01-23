#import "CalendarModule.h"

#import "MITEventsHomeViewController.h"
#import "MITEventsHomeViewControllerPad.h"

@implementation CalendarModule
- (id) init {
    self = [super initWithName:MITModuleTagCalendar title:@"Events"];
    if (self != nil) {
        self.longTitle = @"Events Calendar";
        self.imageName = MITImageEventsModuleIcon;
    }

    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    UIViewController *rootViewController = nil;
    UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;

    if (UIUserInterfaceIdiomPad == userInterfaceIdiom) {
        rootViewController = [[MITEventsHomeViewControllerPad alloc] initWithNibName:nil bundle:nil];
    } else if (UIUserInterfaceIdiomPhone == userInterfaceIdiom) {
        rootViewController = [[MITEventsHomeViewController alloc] initWithNibName:nil bundle:nil];
    }

    self.rootViewController = rootViewController;
}

@end
