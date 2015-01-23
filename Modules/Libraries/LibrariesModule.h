#import <Foundation/Foundation.h>
#import "MITNavigationModule.h"

@interface LibrariesModule : MITNavigationModule
@property(nonatomic,strong) NSOperationQueue *requestQueue;

- (instancetype)init;
@end
