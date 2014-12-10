#import "MITToursImageRepresentation.h"
#import "MITToursImage.h"

@implementation MITToursImageRepresentation

@dynamic url;
@dynamic width;
@dynamic height;
@dynamic image;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];

    [mapping addAttributeMappingsFromArray:@[@"url", @"width", @"height"]];
    
    return mapping;
}

@end
