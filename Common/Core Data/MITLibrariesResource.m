#import "MITLibrariesResource.h"
#import "MITMobileRouteConstants.h"
#import "MITLibrariesLibrary.h"
#import "MITLibrariesLink.h"
#import "MITLibrariesAskUsModel.h"
#import "MITLibrariesWorldcatItem.h"
#import "MITLibrariesUser.h"
#import "MITLibrariesMITIdentity.h"

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

@implementation MITLibrariesAskUsResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesAskUsResourceName pathPattern:MITLibrariesAskUsPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesAskUsModel objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end

@implementation MITLibrariesSearchResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesSearchResourceName pathPattern:MITLibrariesSearchPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesWorldcatItem objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end

@implementation MITLibrariesItemDetailResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesItemDetailResourceName pathPattern:MITLibrariesItemDetailPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesWorldcatItem objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end

@implementation MITLibrariesUserResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesUserResourceName pathPattern:MITLibrariesUserPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesUser objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end

@implementation MITLibrariesMITIdentityResource

- (instancetype)init
{
    self = [super initWithName:MITLibrariesMITIdentityResourceName pathPattern:MITLibrariesMITIdentityPathPattern];
    if (self) {
        [self addMapping:[MITLibrariesMITIdentity objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end
