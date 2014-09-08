#import "MITCalendarsContact.h"
#import "MITCalendarsEvent.h"

@implementation MITCalendarsContact

@dynamic email;
@dynamic location;
@dynamic name;
@dynamic phone;
@dynamic websiteURL;
@dynamic events;

+(RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"website_url": @"websiteURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"email", @"location", @"phone"]];
    
    [mapping setIdentificationAttributes:@[@"name", @"email",  @"websiteURL"]];
    
    return mapping;
}

@end