#import "AboutModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule
- (instancetype) init {
    self = [super initWithName:MITModuleTagAbout title:@"About"];
    if (self) {
        self.imageName = MITImageAboutModuleIcon;
    }
    
    return self;
}

- (BOOL)supportsCurrentUserInterfaceIdiom
{
    return YES;
}

- (void)loadRootViewController
{
    AboutTableViewController *rootViewController = [[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.rootViewController = rootViewController;
}

@end
