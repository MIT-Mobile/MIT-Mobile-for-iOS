#import <Foundation/Foundation.h>

#import "MITNavigationModule.h"
#import "FacilitiesRootViewController.h"

@interface FacilitiesModule : MITNavigationModule
@property(nonatomic,strong) FacilitiesRootViewController *rootViewController;

- (instancetype)init;
@end
