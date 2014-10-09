#import "MITModule.h"

@interface MITNavigationModule : MITModule
@property(nonatomic,weak) UINavigationController *navigationController;
@property(nonatomic,weak) UIViewController *rootViewController;

- (instancetype)initWithName:(NSString *)name title:(NSString *)title;
- (void)loadRootViewController;
@end
