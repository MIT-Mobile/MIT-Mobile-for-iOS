#import "MITCalendarsContact.h"


@implementation MITCalendarsContact

@dynamic name;
@dynamic email;
@dynamic websiteURL;
@dynamic location;
@dynamic phone;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"website_url": @"websiteURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"email", @"location", @"phone"]];
    
    [mapping setIdentificationAttributes:@[@"name", @"email",  @"websiteURL"]];
    
    return mapping;
}

@end
