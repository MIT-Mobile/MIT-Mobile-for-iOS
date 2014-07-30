#import "MITCalendarsSponsor.h"

@implementation MITCalendarsSponsor

@dynamic groupID;
@dynamic name;
@dynamic email;
@dynamic websiteURL;
@dynamic location;
@dynamic phone;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"group_id": @"groupID",
                                                  @"website_url" : @"websiteURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"email", @"location", @"phone"]];

    [mapping setIdentificationAttributes:@[@"websiteURL", @"name"]];
    
    return mapping;
}

@end
