#import "AboutModule.h"
#import "AboutTableViewController.h"

@implementation AboutModule
- (instancetype) init {
    self = [super initWithName:MITModuleTagAbout title:@"About"];
    if (self) {
        self.imageName = @"about";
    }
    
    return self;
}

- (void)loadRootViewController
{
    AboutTableViewController *rootViewController = [[AboutTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.rootViewController = rootViewController;
}

@end
