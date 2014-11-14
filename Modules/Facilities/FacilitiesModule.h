#import <Foundation/Foundation.h>

#import "MITNavigationModule.h"
#import "FacilitiesRootViewController.h"

@interface FacilitiesModule : MITNavigationModule
@property(nonatomic,weak) FacilitiesRootViewController *rootViewController;

- (instancetype)init;
@end
