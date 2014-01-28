#import "MITNewsStoriesResource.h"

#import "MITMobileRouteConstants.h"
#import "MITMobile.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"

NSString * const MITNewsStoryEntityName = @"NewsStory";
NSString * const MITNewsImageEntityName = @"NewsImage";
NSString * const MITNewsImageRepresentationEntityName = @"NewsImageRep";
NSString * const MITNewsCategoryEntityName = @"NewsCategory";

@implementation MITNewsStoriesResource
- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITNewsStoriesResourceName pathPattern:MITNewsStoriesPathPattern managedObjectModel:managedObjectModel];
    if (self) {

    }

    return self;
}

- (NSFetchRequest*)fetchRequestForURL:(NSURL*)url
{
    if (!url) {
        return (NSFetchRequest*)nil;
    }

    NSMutableString *path = [[NSMutableString alloc] initWithString:[url relativePath]];
    
    if ([url query]) {
        [path appendFormat:@"?%@",[url query]];
    }
    
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:path];
    NSDictionary *parameters = nil;
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];

    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITNewsStory entityName]];
        
        if (parameters[@"category"]) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category.identifier == %@", parameters[@"category"]];
        }
        
        return fetchRequest;
    } else {
        return (NSFetchRequest*)nil;
    }
}

- (void)loadMappings
{
    NSEntityDescription *newsStoryEntity = [self.managedObjectModel entitiesByName][MITNewsStoryEntityName];
    NSAssert(newsStoryEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,MITNewsStoryEntityName);

    NSEntityDescription *newsImageEntity = [self.managedObjectModel entitiesByName][MITNewsImageEntityName];
    NSAssert(newsImageEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,MITNewsImageEntityName);

    NSEntityDescription *newsImageRepresentationEntity = [self.managedObjectModel entitiesByName][MITNewsImageRepresentationEntityName];
    NSAssert(newsImageRepresentationEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,MITNewsImageRepresentationEntityName);

    RKEntityMapping *storyMapping = [[RKEntityMapping alloc] initWithEntity:newsStoryEntity];
    storyMapping.identificationAttributes = @[@"identifier"];
    [storyMapping setModificationAttributeForName:@"publishedAt"];
    [storyMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                       @"source_url" : @"sourceURL",
                                                       @"title" : @"title",
                                                       @"published_at" : @"publishedAt",
                                                       @"author" : @"author",
                                                       @"dek" : @"dek",
                                                       @"featured" : @"featured",
                                                       @"body" : @"body"}];


    RKEntityMapping *imageMapping = [[RKEntityMapping alloc] initWithEntity:newsImageEntity];
    [imageMapping addAttributeMappingsFromDictionary:@{@"caption" : @"caption",
                                                       @"credits" : @"credits"}];

    RKEntityMapping *imageRepresentationMapping = [[RKEntityMapping alloc] initWithEntity:newsImageRepresentationEntity];
    imageRepresentationMapping.forceCollectionMapping = YES;
    [imageRepresentationMapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    [imageRepresentationMapping addAttributeMappingsFromDictionary:@{@"(name).url" : @"url",
                                                                     @"(name).width" : @"width",
                                                                     @"(name).height" : @"height"}];


    RKRelationshipMapping *imageRepresentations = [RKRelationshipMapping relationshipMappingFromKeyPath:@"representations"
                                                                                              toKeyPath:@"representations"
                                                                                            withMapping:imageRepresentationMapping];
    [imageMapping addPropertyMapping:imageRepresentations];


    RKRelationshipMapping *storyImages = [RKRelationshipMapping relationshipMappingFromKeyPath:@"images"
                                                                                     toKeyPath:@"images"
                                                                                   withMapping:imageMapping];
    [storyMapping addPropertyMapping:storyImages];


    [self addMapping:storyMapping atKeyPath:nil forRequestMethod:RKRequestMethodGET];
}

@end
