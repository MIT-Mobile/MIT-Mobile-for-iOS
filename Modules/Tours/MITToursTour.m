#import "MITToursTour.h"
#import "MITToursLink.h"
#import "MITToursStop.h"

@implementation MITToursTour

@dynamic identifier;
@dynamic url;
@dynamic title;
@dynamic shortTourDescription;
@dynamic lengthInKM;
@dynamic descriptionHTML;
@dynamic estimatedDurationInMinutes;
@dynamic links;
@dynamic stops;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"short_description" : @"shortTourDescription",
                                                  @"length_in_km" : @"lengthInKM",
                                                  @"description_html" : @"descriptionHTML",
                                                  @"estimated_duration_in_minutes" : @"estimatedDurationInMinutes"}];
    
    [mapping addAttributeMappingsFromArray:@[@"title", @"url"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"links" toKeyPath:@"links" withMapping:[MITToursLink objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"stops" toKeyPath:@"stops" withMapping:[MITToursStop objectMapping]]];
    
    return mapping;
}

@end
