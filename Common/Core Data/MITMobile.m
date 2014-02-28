#import "MITMobile.h"
#import <RestKit/RestKit.h>

#import "MITMapModelController.h"
#import "MITMobileResource.h"
#import "MITMobileServerConfiguration.h"

typedef void (^MITResourceLoadedBlock)(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error);

NSString* const MITMobileErrorDomain = @"MITMobileErrorDomain";
#pragma mark - MITMobile
#pragma mark Private Extension
@interface MITMobile ()
@property (nonatomic,strong) NSMutableDictionary *objectManagers;
@property (nonatomic,strong) NSMutableDictionary *mutableResources;
@property (nonatomic,strong) RKManagedObjectStore *managedObjectStore;

- (RKObjectManager*)objectManagerForURL:(NSURL*)url;
@end

@implementation MITMobile
+ (MITMobile*)defaultManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        RKCompoundValueTransformer *compoundTransformer = [RKValueTransformer defaultValueTransformer];

        NSDateFormatter *spaceDelimitedISO8601 = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        [spaceDelimitedISO8601 setLocale:enUSPOSIXLocale];
        spaceDelimitedISO8601.dateFormat =@"yyyy-MM-dd HH:mm:ssZ";
        [compoundTransformer addValueTransformer:spaceDelimitedISO8601];

        [RKValueTransformer setDefaultValueTransformer:compoundTransformer];
    });

    return [[MIT_MobileAppDelegate applicationDelegate] remoteObjectManager];
}

- (instancetype)init;
{
    self = [super init];
    if (self) {
        _objectManagers = [[NSMutableDictionary alloc] init];
        _mutableResources = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)setManagedObjectStore:(RKManagedObjectStore *)managedObjectStore
{
    if (![self.managedObjectStore isEqual:managedObjectStore]) {
        _managedObjectStore = managedObjectStore;

        [self.objectManagers enumerateKeysAndObjectsUsingBlock:^(id key, RKObjectManager *objectManager, BOOL *stop) {
            [objectManager.operationQueue cancelAllOperations];
            objectManager.managedObjectStore = _managedObjectStore;
        }];
    }
}

- (void)addResource:(MITMobileResource *)resource
{
    NSParameterAssert(resource);
    NSAssert([resource isKindOfClass:[MITMobileResource class]], @"resource is not descended from MITMobileResource");
    NSAssert(!(self.mutableResources[resource.name]), @"resource with name '%@' already exists",resource.name);

    self.mutableResources[resource.name] = resource;
}

- (MITMobileResource*)resourceForName:(NSString *)name
{
    return self.mutableResources[name];
}

- (NSDictionary*)resources
{
    return [self.mutableResources copy];
}

- (void)getObjectsForResourceNamed:(NSString *)routeName parameters:(NSDictionary *)parameters completion:(MITResourceLoadedBlock)block
{
    // Trim off any additional paths. Right now, the API prefix (for the Mobile v3, '/apis')
    // is included in the route name but the current server URL defaults to a path of '/api'.
    // Passing the current server URL directly into the routing subsystem confuses it.
    NSURL *serverURL = [[NSURL URLWithString:@"/"
                              relativeToURL:MITMobileWebGetCurrentServerURL()] absoluteURL];

    RKObjectManager *objectManager = [self objectManagerForURL:serverURL];
    NSString *uniquedRouteName = [NSString stringWithFormat:@"%@ %@",RKStringFromRequestMethod(RKRequestMethodGET),routeName];

    [objectManager getObjectsAtPathForRouteNamed:uniquedRouteName
                                               object:nil
                                           parameters:parameters
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  if (block) {
                                                      block(mappingResult,operation.HTTPRequestOperation.response,nil);
                                                  }
                                              }
                                              failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  if (block) {
                                                      block(nil,operation.HTTPRequestOperation.response,error);
                                                  }
                                              }];
}

- (void)getObjectsForURL:(NSURL*)url completion:(MITResourceLoadedBlock)block
{
    __block MITMobileResource *targetResource = nil;
    __block NSDictionary *queryParameters = nil;
    
    // TODO: Check to see if -[NSURL query] is URLEncoded or not
    // bskinner - 2014.20.01
    NSMutableString *path = [NSMutableString stringWithFormat:@"%@?%@",[url path],[url query]];
    [path replaceOccurrencesOfString:@"/" withString:@"" options:0 range:NSMakeRange(0, 1)];
    
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:path];
    [self.resources enumerateKeysAndObjectsUsingBlock:^(NSString *name, MITMobileResource *resource, BOOL *stop) {
        NSDictionary *parameters = nil;
        
        BOOL pathMatchesPattern = [pathMatcher matchesPattern:resource.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
        if (pathMatchesPattern) {
            targetResource = resource;
            queryParameters = parameters;
            (*stop) = YES;
        }
    }];

    if (targetResource) {
        [self getObjectsForResourceNamed:targetResource.name
                              parameters:queryParameters
                              completion:block];
    } else {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not match any registered resources",[url path]];
        NSError *error = [NSError errorWithDomain:MITMobileErrorDomain
                                             code:MITMobileResourceNotFound
                                         userInfo:@{NSLocalizedDescriptionKey : reason}];
        DDLogWarn(@"%@",reason);
        block(nil,nil,error);
    }
}

- (RKObjectManager*)objectManagerForURL:(NSURL *)url
{
    RKObjectManager *objectManager = self.objectManagers[url];
    if (!objectManager) {
        objectManager = [RKObjectManager managerWithBaseURL:url];

        RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
        [errorMapping addPropertyMapping: [RKAttributeMapping attributeMappingFromKeyPath:@"error" toKeyPath:@"errorMessage"]];
        RKResponseDescriptor *errorResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping
                                                                                                     method:RKRequestMethodAny
                                                                                                pathPattern:nil
                                                                                                    keyPath:nil
                                                                                                statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
        [objectManager addResponseDescriptor:errorResponseDescriptor];

        [self.resources enumerateKeysAndObjectsUsingBlock:^(NSString *name, MITMobileResource *resource, BOOL *stop) {
            NSIndexSet *successfulStatusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
            
            // Setup the response descriptors for the resource. This will probably be done a different way
            // when (if) we move away from RKObjectManager.
            [resource enumerateMappingsByRequestMethodUsingBlock:^(RKRequestMethod method, NSDictionary *mappings) {
                [mappings enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, RKMapping *mapping, BOOL *stop) {
                    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
                                                                                                            method:method
                                                                                                       pathPattern:resource.pathPattern
                                                                                                           keyPath:keyPath
                                                                                                       statusCodes:successfulStatusCodes];
                    [objectManager addResponseDescriptor:responseDescriptor];
                }];
                
                // And now register the route with the object manager's router. The request method is being
                // added here to unique the route name, otherwise, RKRouter will complain if there
                // are multiple routes with the same name (even if the method differs)
                RKRoute *route = [RKRoute routeWithName:[NSString stringWithFormat:@"%@ %@",RKStringFromRequestMethod(method),name]
                                            pathPattern:resource.pathPattern
                                                 method:method];
                
                [objectManager.router.routeSet addRoute:route];
            }];
            

            if ([resource isKindOfClass:[MITMobileManagedResource class]]) {
                MITMobileManagedResource *managedResource = (MITMobileManagedResource*)resource;

                // Setup the fetch request generators so we can have nice things like orphaned object
                // deletion.
                __weak MITMobileManagedResource *weakResource = managedResource;
                [objectManager addFetchRequestBlock:^(NSURL *URL) {
                    return [weakResource fetchRequestForURL:URL];
                }];
            }
        }];
        
        self.objectManagers[url] = objectManager;
    }

    if (!(objectManager.managedObjectStore || self.managedObjectStore)) {
        DDLogWarn(@"an RKManagedObjectStore has not been assigned; mappings requiring CoreData will not be performed");
    } else if (!objectManager.managedObjectStore) {
        objectManager.managedObjectStore = self.managedObjectStore;
    }


    return objectManager;
}

@end