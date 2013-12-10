#import "MITMobile.h"
#import <RestKit/RKHTTPUtilities.h>

#import "CoreDataManager.h"

#import "MITMapModelController.h"
#import "MITMobileResource.h"

#pragma mark - Route Definitions
#pragma mark /calendars
NSString* const MITMobileCalendars = @"/calendars";
NSString* const MITMobileCalendar = @"/calendars/:calendar";
NSString* const MITMobileCalendarEvents = @"/calendars/:calendar/events";
NSString* const MITMobileCalendarEvent = @"/calendars/:calendar/events/:event";

#pragma mark /dining
NSString* const MITMobileDining = @"/dining";
NSString* const MITMobileDiningVenueIcon = @"/dining/venues/:type/:venue/icon";
NSString* const MITMobileDiningHouseVenues = @"/dining/venues/house";
NSString* const MITMobileDiningRetailVenues = @"/dining/venues/retail";

#pragma mark /links
NSString* const MITMobileLinks = @"/links";

#pragma mark /maps
NSString* const MITMobileMapBootstrap = @"/apis/map/bootstrap";
NSString* const MITMobileMapCategories = @"/apis/map/place_categories";
NSString* const MITMobileMapPlaces = @"/apis/map/places";
NSString* const MITMobileMapRooms = @"/apis/map/rooms";
NSString* const MITMobileMapBuilding = @"/apis/map/rooms/:building";

#pragma mark /news
NSString* const MITMobileNewsCategories = @"/news/categories";
NSString* const MITMobileNewsStories = @"/news/stories";

#pragma mark /people
NSString* const MITMobilePeople = @"/people";
NSString* const MITMobilePerson = @"/people/:id";

#pragma mark /shuttles
NSString* const MITMobileShuttlesRoutes = @"/shuttles/routes";
NSString* const MITMobileShuttlesRoute = @"/shuttles/routes/:route";
NSString* const MITMobileShuttlesStop = @"/shuttles/routes/:route/stops/:stop";

#pragma mark /techccash
NSString* const MITMobileTechcash = @"/techcash";
NSString* const MITMobileTechcashAccounts = @"/techcash/accounts";
NSString* const MITMobileTechcashAccount = @"/techcash/accounts/:id";

typedef void (^MITResourceLoadedBlock)(RKMappingResult *result, NSError *error);


#pragma mark - MITMobile
#pragma mark Private Extension
@interface MITMobile ()
@property (nonatomic,strong) RKObjectManager *objectManager;
@end

static MITMobile *gMITMobileDefaultManager = nil;
@implementation MITMobile
+ (MITMobile*)defaultManager
{
    __block MITMobile *defaultManager = nil;
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        defaultManager = gMITMobileDefaultManager;
    });
    
    return defaultManager;
}

+ (void)setDefaultManager:(MITMobile*)manager
{
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        gMITMobileDefaultManager = manager;
    });
}

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)coordinator
{
    NSParameterAssert(coordinator);
    
    self = [super init];
    if (self) {
        RKManagedObjectStore *store = [[RKManagedObjectStore alloc] initWithPersistentStoreCoordinator:coordinator];
        [RKManagedObjectStore setDefaultStore:store];
        [store createManagedObjectContexts];
        
        _objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://mobile-dev.mit.edu"]];
        _objectManager.managedObjectStore = store;
        
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithPersistentStoreCoordinator:[CoreDataManager persistentStoreCoordinator]];
}

- (void)addResource:(MITMobileResource *)resource
{
    NSParameterAssert(resource);

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
            [self.objectManager addResponseDescriptor:responseDescriptor];
        }];


        // And now register the route with the object manager's router
        RKRoute *route = [RKRoute routeWithName:resource.name
                                    pathPattern:resource.pathPattern
                                         method:method];
        [self.objectManager.router.routeSet addRoute:route];
    }];


    // Setup the fetch request generators so we can have nice things (like
    // killing orphans) for resources that provide the support
    __weak MITMobileResource *weakResource = resource;
    [self.objectManager addFetchRequestBlock:^NSFetchRequest *(NSURL *URL) {
        MITMobileResource *blockResource = weakResource;
        if (blockResource && blockResource.fetchGenerator) {
            return blockResource.fetchGenerator(URL);
        } else {
            return nil;
        }
    }];
}

- (NSFetchRequest*)getObjectsForResourceNamed:(NSString *)routeName object:(id)object parameters:(NSDictionary *)parameters completion:(MITResourceLoadedBlock)block;
{
    NSURL *url = [self.objectManager.router URLForRouteNamed:routeName method:NULL object:nil];

    __block NSFetchRequest *fetchRequest = nil;
    [self.objectManager.fetchRequestBlocks enumerateObjectsWithOptions:NSEnumerationReverse
                                                            usingBlock:^(NSFetchRequest* (^block)(NSURL*), NSUInteger idx, BOOL *stop) {
                                                                fetchRequest = block(url);
                                                                if (fetchRequest) {
                                                                    (*stop) = YES;
                                                                }
                                                            }];

    [self.objectManager getObjectsAtPathForRouteNamed:routeName
                                               object:nil
                                           parameters:parameters
                                              success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
                                                  if (block) {
                                                      block(mappingResult,nil);
                                                  }
                                              }
                                              failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                  if (block) {
                                                      block(nil,error);
                                                  }
                                              }];

    return fetchRequest;
}
@end