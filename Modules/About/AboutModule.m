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
        
        AboutTableViewController *aboutVC = [[[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
        aboutVC.title = self.longName;
        
        [self.tabNavController setViewControllers:[NSArray arrayWithObject:aboutVC]];
    }
    return self;
}

@end
