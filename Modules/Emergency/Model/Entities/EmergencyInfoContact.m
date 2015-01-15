#import "EmergencyInfoContact.h"


@implementation EmergencyInfoContact

@dynamic name;
@dynamic phone;
@dynamic contactDescription;

+ (RKObjectMapping*)objectMapping
{
    RKEntityMapping *contactMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [contactMapping addAttributeMappingsFromDictionary:@{@"description" : @"contactDescription",
                                                       @"name" : @"name",
                                                       @"phone" : @"phone"}];
    return contactMapping;
}

@end
