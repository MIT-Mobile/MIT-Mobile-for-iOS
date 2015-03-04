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
    RKDynamicMapping *categoryMapping = [[RKDynamicMapping alloc] init];

    RKEntityMapping *categoryOrderedMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    categoryOrderedMapping.identificationAttributes = @[@"identifier"];
    [categoryOrderedMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                                 @"url" : @"url",
                                                                 @"name" : @"name",
                                                                 @"@metadata.mapping.collectionIndex" : @"order"}];

    RKEntityMapping *categoryDefaultMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    categoryDefaultMapping.identificationAttributes = @[@"identifier"];
    [categoryDefaultMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                                 @"url" : @"url",
                                                                 @"name" : @"name"}];

    [categoryMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([representation isProxy]) {
            // Looks like we are dealing with an RKMappingSourceObject proxy.
            // Grab the metadata from it so we can figure out if we should use the
            //  ordered mapping (if we are pulling from /categories) or the regular mapping
            RKRoute *route = [representation valueForKeyPath:@"@metadata.routing.route"];
            if ([route.pathPattern isEqualToString:MITNewsCategoriesPathPattern]) {
                return categoryOrderedMapping;
            }
        }

        return categoryDefaultMapping;
    }];


    return categoryMapping;
}

@end
