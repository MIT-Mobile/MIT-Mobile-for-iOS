#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
//#import <RestKit/RKMapperOperation.h>

#import "MITNewsCategory.h"
#import "MITNewsStory.h"
#import "MITMobileRouteConstants.h"


@implementation MITNewsCategory

@dynamic identifier;
@dynamic name;
@dynamic order;
@dynamic url;
@dynamic stories;

+ (RKMapping*)objectMapping
{
    RKEntityMapping *categoryOrderedMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    categoryOrderedMapping.identificationAttributes = @[@"identifier"];
    [categoryOrderedMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                                 @"url" : @"url",
                                                                 @"name" : @"name",
                                                                 @"@metadata.mapping.collectionIndex" : @"order"}];

    return categoryOrderedMapping;
}

+ (RKMapping*)storyObjectMapping
{
    RKEntityMapping *categoryDefaultMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    categoryDefaultMapping.identificationAttributes = @[@"identifier"];
    [categoryDefaultMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                                 @"url" : @"url",
                                                                 @"name" : @"name"}];
    
    return categoryDefaultMapping;
}

@end
