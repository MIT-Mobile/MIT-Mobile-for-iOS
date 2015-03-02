#import "MITMobileRouteConstants.h"
#import "MITEmergencyInfoResource.h"
#import "MITEmergencyInfoAnnouncement.h"
#import "MITEmergencyInfoContact.h"

@implementation MITEmergencyInfoAnnouncementResource

- (instancetype)init
{
    self = [super initWithName:MITEmergencyInfoAnnouncementResourceName pathPattern:MITEmergencyInfoAnnouncementPathPattern];
    if (self) {
        [self addMapping:[MITEmergencyInfoAnnouncement objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end

@implementation MITEmergencyInfoContactsResource

- (instancetype)init
{
    self = [super initWithName:MITEmergencyInfoContactsResourceName pathPattern:MITEmergencyInfoContactsPathPattern];
    if (self) {
        [self addMapping:[MITEmergencyInfoContact objectMapping]
               atKeyPath:nil
        forRequestMethod:RKRequestMethodGET];
    }
    return self;
}

@end
