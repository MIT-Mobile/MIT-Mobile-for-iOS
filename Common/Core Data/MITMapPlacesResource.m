#import "MITMapPlacesResource.h"
#import "MITMobile.h"
#import "MITMapModelController.h"

@implementation MITMapPlacesResource
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
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"failed to call designated initializer. Use initWithinitWithPathPattern:managedObjectModel: instead"
                                 userInfo:nil];
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
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapPlaceEntityName];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier != nil"];
            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
            return fetchRequest;
        }
    }
    
    return (NSFetchRequest*)nil;
}

- (void)loadMappings
{
    NSEntityDescription *entity = [self.managedObjectModel entitiesByName][MITMapPlaceEntityName];
    NSAssert(entity,@"Entity %@ does not exist in the managed object model", MITMapPlaceEntityName);

    RKEntityMapping *placeMapping = [[RKEntityMapping alloc] initWithEntity:entity];
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
                                                       @"long_wgs84" : @"longitude"}];

    
    NSEntityDescription *contentsEntity = [self.managedObjectModel entitiesByName][MITMapPlaceContentEntityName];
    NSAssert(contentsEntity,@"Entity %@ does not exist in the managed object model", MITMapPlaceContentEntityName);
    
    RKEntityMapping *contentsMapping = [[RKEntityMapping alloc] initWithEntity:contentsEntity];
    [contentsMapping addAttributeMappingsFromDictionary:@{@"name" : @"name",
                                                          @"url" : @"url"}];
    
    RKRelationshipMapping *contentsRelationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"contents"
                                                                                              toKeyPath:@"contents"
                                                                                            withMapping:contentsMapping];
    contentsRelationship.assignmentPolicy = RKAssignmentPolicyReplace;
    [placeMapping addPropertyMapping:contentsRelationship];

    [self addMapping:placeMapping atKeyPath:nil forRequestMethod:RKRequestMethodAny];
}

@end
