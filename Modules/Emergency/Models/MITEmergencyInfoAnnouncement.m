#import "MITEmergencyInfoAnnouncement.h"
#import "Foundation+MITAdditions.h"

@implementation MITEmergencyInfoAnnouncement

+ (RKObjectMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITEmergencyInfoAnnouncement class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"announcement_html" : @"announcementHTML",
                                                  @"announcement_text" : @"announcementText",
                                                  @"published_at" : @"publishedAt",
                                                  @"url" : @"url"}];
    return mapping;
}

@end
