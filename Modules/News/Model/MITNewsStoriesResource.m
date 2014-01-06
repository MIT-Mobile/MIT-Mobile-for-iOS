#import "MITNewsStoriesResource.h"

#import "MITCoreData.h"
#import "MITNewsStory.h"
#import "MITNewsCategory.h"

NSString * const MITNewsStoryEntityName = @"NewsStory";
NSString * const MITNewsImageEntityName = @"NewsImage";
NSString * const MITNewsImageRepresentationEntityName = @"NewsImageRep";
NSString * const MITNewsCategoryEntityName = @"NewsCategory";

@implementation MITNewsStoriesResource
+ (void)storiesForQuery:(NSString*)queryString
             afterStory:(NSString*)storyID
                  limit:(NSUInteger)limit
                 loaded:(MITMobileResult)block
{
    NSParameterAssert(queryString);

    MITMobile *remoteObjectManager = [[MIT_MobileAppDelegate applicationDelegate] remoteObjectManager];

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    parameters[@"q"] = queryString;

    if (storyID) {
        parameters[@"last_story"] = storyID;
    }

    if (limit) {
        parameters[@"limit"] = @(limit);
    }

    [remoteObjectManager getObjectsForResourceNamed:MITNewsStoriesResourceName
                                             object:nil
                                         parameters:parameters
                                         completion:^(RKMappingResult *result, NSError *error) {
                                             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                 if (block) {
                                                     if (!error) {
                                                         NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITNewsStory entityName]];
                                                         fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                                                                          [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:NO],
                                                                                          [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
                                                         fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF IN %@",[result array]];

                                                         NSError *fetchError = nil;
                                                         NSManagedObjectContext *mainContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                         NSArray *objects = [mainContext executeFetchRequest:fetchRequest error:&fetchError];
                                                         if (!fetchError) {
                                                             block(objects,nil);
                                                         } else {
                                                             block(nil,fetchError);
                                                         }
                                                     } else {
                                                         block(nil,error);
                                                     }
                                                 }
                                             }];
                                         }];
}

+ (NSFetchRequest*)storiesInCategory:(NSString*)categoryID afterStory:(NSString*)storyID limit:(NSUInteger)limit loaded:(MITMobileManagedResult)block
{
    MITMobile *remoteObjectManager = [[MIT_MobileAppDelegate applicationDelegate] remoteObjectManager];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITNewsStory entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"publishedAt" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"featured" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];


    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

    if (categoryID) {
        parameters[@"category"] = categoryID;

        // TODO: Add support for fetch requests when specifying a category
        //  [2013.12.24] Support cannot be added since 'stories' does not contain any foreign keys
        //                  to 'NewsCategory' entities
        /*
         NSPredicate *categoryPredicate = [NSPredicate predicateWithFormat:@"ANY categories.identifer == %@",categoryID];
         fetchRequest.predicate = categoryPredicate;
         */
    }


    // Paging by storyID is a server-side option we cannot construct an immediate fetch request
    // for it (since the fetch depends on the results of the request)
    if (storyID) {
        parameters[@"last_story"] = storyID;
    }

    if (limit > 0) {
        parameters[@"limit"] = @(limit);
    }

    [remoteObjectManager getObjectsForResourceNamed:MITNewsStoriesResourceName
                                             object:nil
                                         parameters:parameters
                                         completion:^(RKMappingResult *result, NSError *error) {
                                             if (!error) {
                                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                     if (block) {
                                                         block(fetchRequest,[NSDate date],error);
                                                     }
                                                 }];
                                             } else {
                                                 [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                     if (block) {
                                                         block(nil,nil,error);
                                                     }
                                                 }];
                                             }
                                         }];

    return fetchRequest;
}

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

    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[url relativePath]];
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:NO parsedArguments:nil];

    if (matches) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapCategory"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];
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
