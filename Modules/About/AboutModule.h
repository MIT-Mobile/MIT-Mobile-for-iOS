#import "MITNavigationModule.h"
#import "AboutTableViewController.h"

@interface AboutModule : MITNavigationModule
@property(nonatomic,weak) AboutTableViewController *rootViewController;

- (instancetype)init;
@end
