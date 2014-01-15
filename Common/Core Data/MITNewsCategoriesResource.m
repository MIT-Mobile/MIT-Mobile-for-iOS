#import "MITNewsCategoriesResource.h"

#import "MITMobile.h"
#import "MITMobileRouteConstants.h"

#import "MITNewsStory.h"
#import "MITNewsCategory.h"
#import "MITNewsImage.h"
#import "MITNewsImageRepresentation.h"

@implementation MITNewsCategoriesResource
+ (NSFetchRequest*)categories:(MITMobileManagedResult)block
{
    MITMobile *remoteObjectManager = [[MIT_MobileAppDelegate applicationDelegate] remoteObjectManager];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITNewsCategory entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

    [remoteObjectManager getObjectsForResourceNamed:MITNewsCategoriesResourceName
                                             object:nil
                                         parameters:nil
                                         completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                 if (block) {
                                                     if (!error) {
                                                         block(fetchRequest,[NSDate date],error);
                                                     } else {
                                                         block(nil,nil,error);
                                                     }
                                                 }
                                             }];
                                         }];

    return fetchRequest;
}

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITNewsCategoriesResourceName pathPattern:MITNewsCategoriesPathPattern managedObjectModel:managedObjectModel];
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
    NSString *categoryEntityName = [MITNewsCategory entityName];
    NSEntityDescription *categoryEntity = [self.managedObjectModel entitiesByName][categoryEntityName];
    NSAssert(categoryEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,categoryEntityName);
    
    NSString *storyEntityName = [MITNewsStory entityName];
    NSEntityDescription *storyEntity = [self.managedObjectModel entitiesByName][categoryEntityName];
    NSAssert(storyEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,storyEntityName);

    RKEntityMapping *categoryMapping = [[RKEntityMapping alloc] initWithEntity:categoryEntity];
    categoryMapping.identificationAttributes = @[@"identifier"];
    [categoryMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                          @"url" : @"url",
                                                          @"name" : @"name",
                                                          @"@metadata.mapping.collectionIndex" : @"order"}];
    
    [categoryMapping addConnectionForRelationship:@"stories" connectedBy:@{@"identifier" : @"identifier"}];

    [self addMapping:categoryMapping atKeyPath:nil forRequestMethod:RKRequestMethodGET];
}
@end
