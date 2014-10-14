#import "MITNavigationModule.h"
#import "MITCampusMapViewController.h"

@interface CMModule : MITNavigationModule
@property(nonatomic,weak) MITCampusMapViewController* rootViewController;

- (instancetype)init;
@end
