#import <UIKit/UIKit.h>
#import "MITNavigationModule.h"
#import "LinksViewController.h"

@interface LinksModule : MITNavigationModule
@property(nonatomic,strong) LinksViewController *rootViewController;

- (instancetype)init;
@end
