#import "MITToursImage.h"
#import "MITToursImageRepresentation.h"
#import "MITToursStop.h"

@implementation MITToursImage

@dynamic representations;
@dynamic stop;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
       [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"representations" toKeyPath:@"representations" withMapping:[MITToursImageRepresentation objectMapping]]];
    
    return mapping;
}

@end
