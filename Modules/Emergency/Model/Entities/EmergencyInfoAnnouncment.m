#import "EmergencyInfoAnnouncment.h"


@implementation EmergencyInfoAnnouncment

@dynamic url;
@dynamic published_at;
@dynamic announcement_text;
@dynamic announcement_html;

+ (RKObjectMapping*)objectMapping
{
    RKEntityMapping *contactMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [contactMapping addAttributeMappingsFromDictionary:@{@"announcement_html" : @"announcement_html",
                                                         @"announcement_text" : @"announcement_text",
                                                         @"published_at" : @"published_at",
                                                         @"url" : @"url"}];
    return contactMapping;
}

@end
