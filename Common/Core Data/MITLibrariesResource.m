#import "MITLibrariesResource.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesLink.h"
#import "MITMobileRouteConstants.h"

@implementation MITLibrariesResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesResourceName pathPattern:MITLibrariesPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesLibrary objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end

@implementation MITLibrariesLinksResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesLinksResourceName pathPattern:MITLibrariesLinksPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesLink objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end