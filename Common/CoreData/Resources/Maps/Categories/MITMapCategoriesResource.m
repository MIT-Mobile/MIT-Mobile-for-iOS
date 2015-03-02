#import "MITMapCategoriesResource.h"

#import "MITMobileRouteConstants.h"
#import "MITMobile.h"
#import "MITMapModel.h"

@implementation MITMapCategoriesResource
+ (NSFetchRequest*)categories:(MITMobileManagedResult)block
{
    // The fetch request isn't dependent on the results of the 'GET' operation so
    // we can both return it and use it in the block later
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMapCategory entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMapCategoriesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (!error) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            block(fetchRequest,[NSDate date],nil);
                                                        }];
                                                    } else {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            block(nil,nil,error);
                                                        }];
                                                    }
                                                }];

    return fetchRequest;
}

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITMapCategoriesResourceName pathPattern:MITMapCategoriesPathPattern managedObjectModel:managedObjectModel];
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
    NSEntityDescription *categoryEntity = [MITMapCategory entityDescription];
    NSAssert(categoryEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,[categoryEntity name]);

    RKEntityMapping *categoryMapping = [[RKEntityMapping alloc] initWithEntity:categoryEntity];
    [categoryMapping setIdentificationAttributes:@[@"identifier"]];
    [categoryMapping addAttributeMappingsFromDictionary:@{@"id": @"identifier",
                                                          @"url" : @"url",
                                                          @"name" : @"name",
                                                          @"@metadata.mapping.collectionIndex" : @"order"}];

    RKRelationshipMapping *subcategories = [RKRelationshipMapping relationshipMappingFromKeyPath:@"categories"
                                                                                       toKeyPath:@"children"
                                                                                     withMapping:categoryMapping];
    [categoryMapping addPropertyMapping:subcategories];

    [self addMapping:categoryMapping atKeyPath:nil forRequestMethod:RKRequestMethodGET];
}

@end
