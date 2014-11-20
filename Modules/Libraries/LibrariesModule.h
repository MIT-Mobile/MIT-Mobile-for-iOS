#import <Foundation/Foundation.h>
#import "MITNavigationModule.h"
#import "LibrariesViewController.h"

@interface LibrariesModule : MITNavigationModule
@property(nonatomic,strong) LibrariesViewController *rootViewController;
@property(nonatomic,strong) NSOperationQueue *requestQueue;

- (instancetype)init;
@end
