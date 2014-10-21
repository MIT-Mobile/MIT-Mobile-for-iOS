#import "MITToursStop.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursImage.h"
#import "MITToursTour.h"

@implementation MITToursStop

@dynamic coordinates;
@dynamic title;
@dynamic bodyHTML;
@dynamic identifier;
@dynamic stopType;
@dynamic images;
@dynamic directionsToNextStop;
@dynamic tour;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"type" : @"stopType",
                                                  @"body_html" : @"bodyHTML"}];
    
    [mapping addAttributeMappingsFromArray:@[@"title", @"coordinates"]];
   
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"images" toKeyPath:@"images" withMapping:[MITToursImage objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"directions_to_next_stop" toKeyPath:@"directionsToNextStop" withMapping:[MITToursDirectionsToStop objectMapping]]];
    
    return mapping;
}

@end
