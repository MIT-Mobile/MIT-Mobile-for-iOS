#import "MITShuttleStop.h"
#import "MITShuttlePrediction.h"
#import "MITShuttleRoute.h"


@implementation MITShuttleStop

@dynamic identifier;
@dynamic latitude;
@dynamic longitude;
@dynamic predictionsURL;
@dynamic shortTitle;
@dynamic stopNumber;
@dynamic title;
@dynamic url;
@dynamic predictions;
@dynamic route;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                  @"url": @"url",
                                                  @"title": @"title",
                                                  @"short_title": @"shortTitle",
                                                  @"stop_number": @"stopNumber",
                                                  @"lat": @"latitude",
                                                  @"lon": @"longitude",
                                                  @"predictions_url": @"predictionsURL"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"predictions" toKeyPath:@"predictions" withMapping:[MITShuttlePrediction objectMapping]]];
    [mapping setIdentificationAttributes:@[@"identifier"]];
    return mapping;
}

@end
