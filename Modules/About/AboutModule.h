#import "MITNavigationModule.h"
#import "AboutTableViewController.h"

@interface AboutModule : MITNavigationModule
@property(nonatomic,strong) AboutTableViewController *rootViewController;

- (instancetype)init;
@end
