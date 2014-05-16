#import "MITShuttleRoute.h"
#import "MITShuttleStop.h"
#import "MITShuttleVehicle.h"


@implementation MITShuttleRoute

@dynamic agency;
@dynamic identifier;
@dynamic pathBoundingBox;
@dynamic pathSegments;
@dynamic predictable;
@dynamic predictionsURL;
@dynamic routeDescription;
@dynamic scheduled;
@dynamic title;
@dynamic url;
@dynamic vehiclesURL;
@dynamic stops;
@dynamic vehicles;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"url": @"url",
                                                  @"title": @"title",
                                                  @"agency": @"agency",
                                                  @"description": @"routeDescription",
                                                  @"scheduled": @"scheduled",
                                                  @"predictable": @"predictable",
                                                  @"path.bbox": @"pathBoundingBox",
                                                  @"path.segments": @"pathSegments",
                                                  @"predictions_url": @"predictionsURL",
                                                  @"vehicles_url": @"vehiclesURL"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"stops" toKeyPath:@"stops" withMapping:[MITShuttleStop objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"vehicles" toKeyPath:@"vehicles" withMapping:[MITShuttleVehicle objectMapping]]];
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

@end
