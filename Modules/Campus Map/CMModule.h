#import "MITNavigationModule.h"
#import "MITMapHomeViewController.h"

@interface CMModule : MITNavigationModule
@property(nonatomic,strong) MITMapHomeViewController* rootViewController;

- (instancetype)init;
@end
