#import "AboutModule.h"
#import "MITModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule

- (id) init {
    self = [super init];
    if (self != nil) {
        self.tag = AboutTag;
        self.shortName = @"About";
        self.longName = @"About";
        self.iconName = @"about";
        self.isMovableTab = FALSE;
        
        //moduleHomeController.title = self.longName;
        
        //AboutTableViewController *aboutVC = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        //aboutVC.title = self.longName;
        
        //[self.tabNavController setViewControllers:[NSArray arrayWithObject:aboutVC]];
    }
    return self;
}

- (UIViewController *)moduleHomeController {
    if (!moduleHomeController) {
        moduleHomeController = [[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    }
    return moduleHomeController;
}

@end
