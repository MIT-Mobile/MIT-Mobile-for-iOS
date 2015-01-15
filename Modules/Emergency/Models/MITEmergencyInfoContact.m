#import "MITEmergencyInfoContact.h"
#import "Foundation+MITAdditions.h"

@implementation MITEmergencyInfoContact

+ (RKObjectMapping*)objectMapping
{
    RKObjectMapping *mapping = [[RKObjectMapping alloc] initWithClass:[MITEmergencyInfoContact class]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"description" : @"descriptionText",
                                                  @"name" : @"name",
                                                  @"phone" : @"phone"}];
    return mapping;
}

@end
