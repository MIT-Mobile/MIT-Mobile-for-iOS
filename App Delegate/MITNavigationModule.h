#import "MITModule.h"

@interface MITNavigationModule : MITModule
@property(nonatomic,weak) UINavigationController *navigationController;
@property(nonatomic,strong) UIViewController *rootViewController;

- (instancetype)initWithName:(NSString *)name title:(NSString *)title;

- (BOOL)isRootViewControllerLoaded;
- (void)loadRootViewController;
@end
