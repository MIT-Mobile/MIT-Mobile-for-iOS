#import "MITDiningDining.h"
#import "MITDiningLinks.h"
#import "MITDiningVenues.h"

@implementation MITDiningDining

@dynamic announcementsHTML;
@dynamic url;
@dynamic links;
@dynamic venues;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromArray:@[@"url"]];
    [mapping addAttributeMappingsFromDictionary:@{@"announcements_html" : @"announcementsHTML"}];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"links" toKeyPath:@"links" withMapping:[MITDiningLinks objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"venues" toKeyPath:@"venues" withMapping:[MITDiningVenues objectMapping]]];
    
    [mapping setIdentificationAttributes:@[@"url"]];
    
    return mapping;
}

@end
