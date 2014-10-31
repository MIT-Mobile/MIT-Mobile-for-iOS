#import "MITToursStop.h"
#import "MITToursDirectionsToStop.h"
#import "MITToursImage.h"
#import "MITToursTour.h"

@implementation MITToursStop

@dynamic bodyHTML;
@dynamic coordinates;
@dynamic identifier;
@dynamic stopType;
@dynamic title;
@dynamic directionsToNextStop;
@dynamic images;
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

- (NSString *)thumbnailURL
{
    MITToursImage *image = self.images[0];
    return image.thumbnailURL;
}

- (CLLocation *)locationForStop
{
    return [[CLLocation alloc] initWithLatitude:[self.coordinates[1] doubleValue] longitude:[self.coordinates[0] doubleValue]];
}

@end
