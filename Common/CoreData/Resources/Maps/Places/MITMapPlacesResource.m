#import "MITMapPlacesResource.h"

#import "MITMobileRouteConstants.h"
#import "MITMobile.h"
#import "MITCoreData.h"
#import "MITAdditions.h"

#import "MITMapModelController.h"

@implementation MITMapPlacesResource

+ (void)placesWithQuery:(NSString*)queryString loaded:(MITMobileResult)block
{
    NSParameterAssert(queryString);
    NSParameterAssert(block);

    [[MITMobile defaultManager] cancelAllRequestOperationsForRequestMethod:RKRequestMethodGET atResourcePath:MITMapPlacesPathPattern];
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMapPlacesResourceName
                                                parameters:@{@"q" : queryString}
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {

                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                        if (!error) {
                                                            NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
                                                            NSArray *mappedObjects = [mainQueueContext transferManagedObjects:[result array]];

                                                            block(mappedObjects,nil);
                                                        } else {
                                                            block(nil,error);
                                                        }
                                                    }];
                                                }];
}

+ (NSFetchRequest*)placesInCategory:(NSString*)categoryID loaded:(MITMobileManagedResult)block
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMapPlace entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier != nil"];
    // use a natural sort, so that Building 7 comes before Building 10
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier"
                                                                   ascending:YES
                                                                    selector:@selector(localizedStandardCompare:)]];
    
    // TODO (bskinner - 2013.12.18): The Mobile v3 map/place_categories call is currently broken;
    //  The URL is not included and the fields are named incorrectly. Manually formatting the 'category'
    //  parameter (instead of just using the URL directly until it is fixed
    NSDictionary *parameters = nil;
    if (categoryID) {
        parameters = @{@"category" : categoryID};
    }
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMapPlacesResourceName
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                        if (!error) {
                                                            if (categoryID) {
                                                                NSArray *objectIDs = [NSManagedObjectContext objectIDsForManagedObjects:[result array]];
                                                                NSArray *predicates = @[fetchRequest.predicate, [NSPredicate predicateWithFormat:@"SELF IN %@",objectIDs]];
                                                                fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
                                                            }
                                                            
                                                            block(fetchRequest,[NSDate date],nil);
                                                        } else {
                                                            block(nil,nil,error);
                                                        }
                                                    }];
                                                }];
    
    if (categoryID) {
        return nil;
    } else {
        return fetchRequest;
    }
}

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITMapPlacesResourceName pathPattern:MITMapPlacesPathPattern managedObjectModel:managedObjectModel];
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

    NSDictionary *parameters = nil;
    BOOL matches = [pathMatcher matchesPattern:self.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];

    if (matches) {
        if (parameters[@"q"]) {
            // Can't calculate a fetch request for search queries. This completely
            // depends on the server's response, not the URL of the request.
            return (NSFetchRequest*)nil;
        } else if (parameters[@"category"]) {
            // Can't build a fetch request for this either (at the moment).
            // As of 2013.12.04, the categories returned by the place_categories
            // resource and the categories at a MapPlace's 'categories' subkey do
            // not match up.
            return (NSFetchRequest*)nil;
        } else {
            // Ok, we can *probably* build some sort of a fetch request!
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMapPlace entityName]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier != nil"];
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
            return fetchRequest;
        }
    }
    
    return (NSFetchRequest*)nil;
}

- (void)loadMappings
{
    NSEntityDescription *placeEntity = [MITMapPlace entityDescription];
    NSAssert(placeEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,[placeEntity name]);

    NSEntityDescription *placeContentEntity = [MITMapPlaceContent entityDescription];
    NSAssert(placeContentEntity,@"[%@] entity %@ does not exist in the managed object model",self.name,[placeContentEntity name]);

    RKEntityMapping *placeMapping = [[RKEntityMapping alloc] initWithEntity:placeEntity];
    placeMapping.identificationAttributes = @[@"identifier"]; // RKEntityMapping converts this to an NSAttributeDescription internally
    placeMapping.assignsNilForMissingRelationships = YES;
    [placeMapping addAttributeMappingsFromDictionary:@{@"id" : @"identifier",
                                                       @"name" : @"name",
                                                       @"bldgimg" : @"imageURL",
                                                       @"bldgnum" : @"buildingNumber",
                                                       @"viewangle" : @"imageCaption",
                                                       @"architect" : @"architect",
                                                       @"mailing" : @"mailingAddress",
                                                       @"street" : @"streetAddress",
                                                       @"city" : @"city",
                                                       @"lat_wgs84" : @"latitude",
                                                       @"long_wgs84" : @"longitude",
                                                       @"category" : @"categoryIds"}];
    
    NSRelationshipDescription *categoriesRelationship = [placeEntity relationshipsByName][@"categories"];
    RKConnectionDescription *categoriesConnection = [[RKConnectionDescription alloc] initWithRelationship:categoriesRelationship attributes:@{@"categoryIds": @"identifier"}];
    [placeMapping addConnection:categoriesConnection];
    
    RKEntityMapping *contentsMapping = [[RKEntityMapping alloc] initWithEntity:placeContentEntity];
    [contentsMapping addAttributeMappingsFromDictionary:@{@"name" : @"name",
                                                          @"url" : @"url",
                                                          @"category" : @"categoryIds"}];
    
    NSRelationshipDescription *contentCategoriesRelationship = [placeContentEntity relationshipsByName][@"categories"];
    RKConnectionDescription *contentCategoriesConnection = [[RKConnectionDescription alloc] initWithRelationship:contentCategoriesRelationship attributes:@{@"categoryIds": @"identifier"}];
    [contentsMapping addConnection:contentCategoriesConnection];

    [placeMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"contents" toKeyPath:@"contents" withMapping:contentsMapping]];

    [self addMapping:placeMapping atKeyPath:nil forRequestMethod:RKRequestMethodAny];
}

@end

@implementation MITMapObjectResource

+ (void)placesWithObjectID:(NSString *)objectID loaded:(MITMobileResult)block
{
    NSParameterAssert(objectID);
    NSParameterAssert(block);
    
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMapObjectResourceName object:@{@"objectID" : objectID} parameters:nil completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (!error) {
                NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];
                NSArray *mappedObjects = [mainQueueContext transferManagedObjects:[result array]];
                block(mappedObjects,nil);
            } else {
                block(nil,error);
            }
        }];
    }];
}

- (NSFetchRequest*)fetchRequestForURL:(NSURL*)url
{
    return (NSFetchRequest*)nil;
}

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel*)managedObjectModel
{
    self = [super initWithName:MITMapObjectResourceName pathPattern:MITMapObjectPathPattern managedObjectModel:managedObjectModel];
    return self;
}

@end
