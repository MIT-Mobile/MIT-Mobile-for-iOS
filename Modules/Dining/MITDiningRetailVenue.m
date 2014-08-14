#import "MITDiningRetailVenue.h"
#import "MITDiningLocation.h"
#import "MITDiningRetailDay.h"


@implementation MITDiningRetailVenue

@dynamic cuisine;
@dynamic descriptionHTML;
@dynamic homepageURL;
@dynamic iconURL;
@dynamic identifier;
@dynamic menuHTML;
@dynamic menuURL;
@dynamic name;
@dynamic payment;
@dynamic shortName;
@dynamic favorite;
@dynamic hours;
@dynamic location;

+ (RKMapping *)objectMapping
{
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    
    [mapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                  @"short_name" : @"shortName",
                                                  @"icon_url" : @"iconURL",
                                                  @"description_html" : @"descriptionHTML",
                                                  @"homepage_url" : @"homepageURL",
                                                  @"menu_html" : @"menuHTML",
                                                  @"menu_url" : @"menuURL"}];
    [mapping addAttributeMappingsFromArray:@[@"name", @"payment", @"cuisine"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"location" toKeyPath:@"location" withMapping:[MITDiningLocation objectMapping]]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"hours" toKeyPath:@"hours" withMapping:[MITDiningRetailDay objectMapping]]];
    
    [mapping setIdentificationAttributes:@[@"identifier"]];
    
    return mapping;
}

@end
