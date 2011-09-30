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
