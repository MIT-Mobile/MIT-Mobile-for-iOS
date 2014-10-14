#import "MITNavigationModule.h"
#import "MITMapHomeViewController.h"

@interface CMModule : MITNavigationModule
@property(nonatomic,weak) MITMapHomeViewController* rootViewController;

- (instancetype)init;
@end
