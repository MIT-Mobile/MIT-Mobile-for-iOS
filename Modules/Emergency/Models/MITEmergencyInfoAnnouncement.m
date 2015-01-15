#import "MITEmergencyInfoAnnouncement.h"
#import "Foundation+MITAdditions.h"

@implementation MITEmergencyInfoAnnouncement

+ (RKObjectMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITEmergencyInfoAnnouncement class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"announcement_html" : @"announcement_html",
                                                  @"announcement_text" : @"announcement_text",
                                                  @"published_at" : @"published_at",
                                                  @"url" : @"url"}];
    return mapping;
}

@end
