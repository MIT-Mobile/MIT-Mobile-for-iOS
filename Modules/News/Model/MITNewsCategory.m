#import "MITNewsCategory.h"
#import "MITNewsStory.h"


@implementation MITNewsCategory

@dynamic identifier;
@dynamic name;
@dynamic order;
@dynamic url;
@dynamic stories;

+ (RKObjectMapping*)objectMapping
{
    RKEntityMapping *categoryMapping = [[RKEntityMapping alloc] initWithEntity:[self entityDescription]];
    categoryMapping.identificationAttributes = @[@"identifier"];
    [categoryMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                          @"url" : @"url",
                                                          @"name" : @"name",
                                                          @"@metadata.mapping.collectionIndex" : @"order"}];

    return categoryMapping;
}

@end
