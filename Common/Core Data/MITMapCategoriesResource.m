#import "MITMapCategoriesResource.h"
#import "MITMobile.h"
#import "MITMapModelController.h"

@implementation MITMapCategoriesResource
- (instancetype)initWithPathPattern:(NSString*)pathPattern managedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    NSParameterAssert(managedObjectModel);

    self = [super initWithPathPattern:pathPattern];
    if (self) {
        self.managedObjectModel = managedObjectModel;
    }

    return self;
}

- (instancetype)initWithPathPattern:(NSString *)pathPattern
{
    NSManagedObjectModel *managedObjectModel = [MIT_MobileAppDelegate applicationDelegate].managedObjectModel;
    return [self initWithPathPattern:pathPattern managedObjectModel:managedObjectModel];
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
    NSEntityDescription *entity = [self.managedObjectModel entitiesByName][MITMapCategoryEntityName];
    NSAssert(entity,@"Entity %@ does not exist in the managed object model", MITMapCategoryEntityName);

    RKEntityMapping *categoryMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    [categoryMapping addAttributeMappingsFromDictionary:@{@"categoryId": @"identifier",
                                                          @"url" : @"url",
                                                          @"categoryName" : @"name",
                                                          @"@metadata.mapping.collectionIndex" : @"order"}];

    RKRelationshipMapping *subcategories = [RKRelationshipMapping relationshipMappingFromKeyPath:@"subcategories"
                                                                                       toKeyPath:@"children"
                                                                                     withMapping:categoryMapping];
    [categoryMapping addPropertyMapping:subcategories];

    [self addMapping:categoryMapping atKeyPath:nil forRequestMethod:RKRequestMethodGET];
}

@end
