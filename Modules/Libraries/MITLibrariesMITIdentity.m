#import "MITLibrariesMITIdentity.h"

@implementation MITLibrariesMITIdentity

+ (RKMapping *)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITLibrariesMITIdentity class]];
    [mapping addAttributeMappingsFromDictionary:@{@"shib_identity" : @"shibIdentity",
                                                  @"username" : @"username",
                                                  @"is_mit_identity" : @"isMITIdentity"}];
    return mapping;
}

@end
