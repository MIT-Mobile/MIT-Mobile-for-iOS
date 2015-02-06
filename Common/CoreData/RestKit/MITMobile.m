#import "MITMobile.h"
#import <RestKit/RestKit.h>

#import "MITMapModelController.h"
#import "MITMobileResource.h"
#import "MITMobileServerConfiguration.h"
#import "MITTouchstoneRequestOperation.h"
#import "MITAdditions.h"
#import "MIT_MobileAppDelegate.h"

typedef void (^MITResourceLoadedBlock)(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error);

NSString* const MITMobileErrorDomain = @"MITMobileErrorDomain";
#pragma mark - MITMobile
#pragma mark Private Extension
@interface MITMobile ()
@property (nonatomic,strong) NSMutableDictionary *objectManagers;
@property (nonatomic,strong) NSMutableDictionary *mutableResources;

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
    [self getObjectsForResourceNamed:routeName object:nil parameters:parameters completion:block];
}

- (void)getObjectsForResourceNamed:(NSString *)routeName object:(id)object parameters:(NSDictionary *)parameters completion:(MITResourceLoadedBlock)block
{
    // Trim off any additional paths. Right now, the API prefix (for the Mobile v3, '/apis')
    // is included in the route name but the current server URL defaults to a path of '/api'.
    // Passing the current server URL directly into the routing subsystem confuses it.
    NSURL *serverURL = [[NSURL URLWithString:@"/"
                               relativeToURL:MITMobileWebGetCurrentServerURL()] absoluteURL];
    
    RKObjectManager *objectManager = [self objectManagerForURL:serverURL];
    NSString *uniquedRouteName = [NSString stringWithFormat:@"%@ %@",RKStringFromRequestMethod(RKRequestMethodGET),routeName];
    
    [objectManager getObjectsAtPathForRouteNamed:uniquedRouteName
                                          object:object
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
    NSParameterAssert(url);

    NSMutableString *path = [[NSMutableString alloc] initWithString:[url path]];
    [path replaceOccurrencesOfString:@"/" withString:@"" options:0 range:NSMakeRange(0, 1)];

    // Some resources in the MIT Mobile API have a required trailing slash and NSURL seems to silently discard
    //  it when asking for the path. When this happens, the path matching fails and everything barfs.
    //  This code checks to see if the last path component of the url ends in a '/' and, if it does,
    //  appends a '/' to the end of the path
    NSString *lastPathComponent = [NSString stringWithFormat:@"%@/",[url lastPathComponent]];
    NSRange queryRange = [[url absoluteString] rangeOfString:lastPathComponent];
    if ((queryRange.location != NSNotFound)) {
        [path appendString:@"/"];
    }

    __block MITMobileResource *targetResource = nil;
    
    // For URLs with a trailing '/' before the query component, path matching will fail here
    // unless we manually add the '/'
    if ([url.absoluteString rangeOfString:@"/?"].length > 0) {
        [path replaceOccurrencesOfString:@"?" withString:@"/?" options:0 range:NSMakeRange(0, path.length)];
    }
    
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:path];
    [self.resources enumerateKeysAndObjectsUsingBlock:^(NSString *name, MITMobileResource *resource, BOOL *stop) {
        BOOL pathMatchesPattern = [pathMatcher matchesPattern:resource.pathPattern tokenizeQueryStrings:NO parsedArguments:nil];
        if (pathMatchesPattern) {
            targetResource = resource;
            (*stop) = YES;
        }
    }];

    if (targetResource) {
        // Trim off any additional paths. Right now, the API prefix (for the Mobile v3, '/apis')
        // is included in the route name but the current server URL defaults to a path of '/api'.
        // Passing the current server URL directly into the routing subsystem confuses it.
        NSURL *serverURL = [[NSURL URLWithString:@"/"
                                   relativeToURL:MITMobileWebGetCurrentServerURL()] absoluteURL];

        RKObjectManager *objectManager = [self objectManagerForURL:serverURL];
        NSDictionary *queryParameters = [url URLDecodedQueryDictionary];
        [objectManager getObjectsAtPath:path
                             parameters:queryParameters
                                success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                    NSHTTPURLResponse *response = operation.HTTPRequestOperation.response;
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        if (block) {
                                            block(mappingResult,response,nil);
                                        }
                                    }];
                                }
                                failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                    NSHTTPURLResponse *response = operation.HTTPRequestOperation.response;
                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                        if (block) {
                                            block(nil,response,error);
                                        }
                                    }];
                                }];
    } else {
        NSString *reason = [NSString stringWithFormat:@"'%@' does not match any registered resources",path];
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
        
        // Incompatible with AFNetworking 2.0.
        // TODO: Be sure to upgrade this once RestKit updates (although it will likely break anyway)
        AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];
        [httpClient registerHTTPOperationClass:[MITTouchstoneRequestOperation class]];
        objectManager = [[RKObjectManager alloc] initWithHTTPClient:httpClient];
        [objectManager setAcceptHeaderWithMIMEType:RKMIMETypeJSON];
        objectManager.requestSerializationMIMEType = RKMIMETypeFormURLEncoded;
        [objectManager registerRequestOperationClass:[MITTouchstoneRequestOperation class]];

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
                for (NSFetchRequest *(^fetchRequestBlock)(NSURL *URL) in [weakResource fetchRequestForURLBlocks]) {
                    [objectManager addFetchRequestBlock:fetchRequestBlock];
                }
                
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

- (void)cancelAllRequestOperationsForRequestMethod:(RKRequestMethod)requestMethod atResourcePath:(NSString *)resourcePath
{
    NSURL *serverURL = [[NSURL URLWithString:@"/"
                               relativeToURL:MITMobileWebGetCurrentServerURL()] absoluteURL];
    
    RKObjectManager *objectManager = [self objectManagerForURL:serverURL];
    [objectManager cancelAllObjectRequestOperationsWithMethod:requestMethod matchingPathPattern:resourcePath];
}

@end