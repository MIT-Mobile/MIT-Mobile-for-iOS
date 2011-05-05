#import "FacilitiesLocationData.h"

#import "CoreDataManager.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "MITMobileWebAPI.h"

const NSString *MITFacilitiesDidLoadNotification = @"MITFacilitiesDidLoad";
const NSString *MITFacilitiesDidFinishLoadingNotification = @"MITFacilitiesDidFinishLoading";

static NSString *FacilitiesCategoryKey = @"categories";
static NSString *FacilitiesLocationsKey = @"locations";
static FacilitiesLocationData *_sharedData = nil;

@interface FacilitiesLocationData ()
- (void)updateCachedData;
- (void)loadCategories;
- (void)loadAllLocations;
- (void)loadLocationsForCategory:(NSString*)category;
- (FacilitiesCategory*)categoryForId:(NSString*)categoryId;
- (FacilitiesLocation*)locationForId:(NSString*)locationId;
@end

@implementation FacilitiesLocationData

- (id)init {
    self = [super init]; 
    
    if (self) {
        _requestsInFlight = [[NSMutableDictionary alloc] init];
        _notificationBlocks = [[NSMutableArray alloc] init];
        _requestUpdateQueue = dispatch_queue_create("MITFacilitiesRequestUpdateQueue", NULL);
        _defaultGroup = dispatch_group_create();
        
        [self updateCachedData];
    }
    
    return self;
}

- (void)dealloc {
    [_requestsInFlight release];
    _requestsInFlight = nil;
    
    [_notificationBlocks release];
    _notificationBlocks = nil;
    
    dispatch_release(_requestUpdateQueue);
    dispatch_release(_defaultGroup);
    [super dealloc];
}


#pragma mark -
#pragma mark Public Methods
- (NSArray*)allCategories {
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                             matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSArray*)categoriesWithPredicate:(NSPredicate*)predicate {
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                             matchingPredicate:predicate];
}

- (NSArray*)allLocations {
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSArray*)locationsWithPredicate:(NSPredicate*)predicate {
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:predicate];
}

- (NSArray*)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId {
    NSMutableArray *local = [NSMutableArray array];
    NSArray *locations = nil;
    
    if (categoryId) {
        locations = [[self categoryForId:categoryId].locations allObjects];
    } else {
        locations = [self allLocations];
    }
    
    for (FacilitiesLocation *loc in locations) {
        CLLocation *bldgLocation = [[[CLLocation alloc] initWithLatitude:[loc.latitude doubleValue]
                                                               longitude:[loc.longitude doubleValue]] autorelease];
        if ([bldgLocation distanceFromLocation:location] <= radiusInMeters) {
            if ((categoryId == nil) || [loc.categories containsObject:categoryId]) {
                [local addObject:loc];
            }
        }
    }
    
    NSArray *sortedArray = [local sortedArrayUsingComparator:^(id obj1, id obj2) {
        FacilitiesLocation *b1 = (FacilitiesLocation*)obj1;
        FacilitiesLocation *b2 = (FacilitiesLocation*)obj2;
        CLLocation *loc1 = [[[CLLocation alloc] initWithLatitude:[b1.latitude doubleValue]
                                                       longitude:[b1.longitude doubleValue]] autorelease];
        CLLocation *loc2 = [[[CLLocation alloc] initWithLatitude:[b2.latitude doubleValue]
                                                       longitude:[b2.longitude doubleValue]] autorelease];
        CLLocationDistance d1 = [loc1 distanceFromLocation:location];
        CLLocationDistance d2 = [loc2 distanceFromLocation:location];
        
        if (d1 > d2) {
            return NSOrderedDescending;
        } else if (d2 < d1) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    return sortedArray;
}

- (void)notifyOnDataAvailable:(FacilitiesDataAvailableBlock)completedBlock {
    [_notificationBlocks addObject:[[completedBlock copy] autorelease]];
}

- (void)addRequest:(MITMobileWebAPI*)request toQueueName:(NSString*)queueName {
    dispatch_group_async(_defaultGroup,_requestUpdateQueue, ^{
        NSMutableArray *queue = [_requestsInFlight objectForKey:queueName];
        if (queue == nil) {
            queue = [NSMutableArray array];
            [_requestsInFlight setObject:queue
                                  forKey:queueName];
        }
        
        [queue addObject:request];
    });
}

- (void)removeRequest:(MITMobileWebAPI*)request fromQueueName:(NSString*)queueName {
    dispatch_group_async(_defaultGroup,_requestUpdateQueue, ^{
        NSMutableArray *queue = [_requestsInFlight objectForKey:queueName];
        if (queue) {
            [queue removeObject:request];
        }
    });
}

#pragma mark -
#pragma mark Private Methods
- (void)updateCachedData {
    NSString *lastUpdate = [[NSUserDefaults standardUserDefaults] stringForKey:@"FacilitiesLastUpdateDate"];
    
    if (lastUpdate) {
        dispatch_async(dispatch_get_main_queue(),^{
            NSArray *blocks = [[_notificationBlocks copy] autorelease];
            for(FacilitiesDataAvailableBlock block in blocks) {
                dispatch_async(dispatch_get_main_queue(),block);
            }
        });
        
        return;
    }
    
    [self loadCategories];
    [self loadAllLocations];
}

- (void)loadCategories {
    MITMobileWebAPI *web = [[MITMobileWebAPI alloc] initWithJSONLoadedDelegate:self];
    
    [self addRequest:web
         toQueueName:FacilitiesCategoryKey];
    
    web.userData = FacilitiesCategoryKey;
    [web requestObject:[NSDictionary dictionaryWithObject:@"categorytitles"
                                                   forKey:@"command"]
         pathExtension:@"map/"];
}

- (void)loadAllLocations {
    NSArray *categories = [self allCategories];
    
    for (FacilitiesCategory *category in categories) {
        [self loadLocationsForCategory:category.uid];
    }
}

- (void)loadLocationsForCategory:(NSString*)category{
    MITMobileWebAPI *web = [[MITMobileWebAPI alloc] initWithJSONLoadedDelegate:self];
    web.userData = FacilitiesLocationsKey;
    
    [self addRequest:web
         toQueueName:FacilitiesLocationsKey];
    
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionary];
    [paramDict setObject:@"category"
                  forKey:@"command"];
    [paramDict setObject:category
                  forKey:@"id"];
    
    [web requestObject:paramDict
         pathExtension:@"map/"];
}

- (FacilitiesCategory*)categoryForId:(NSString*)categoryId {
    NSPredicate *predicate = nil;
    if (categoryId) {
        predicate = [NSPredicate predicateWithFormat:@"uid == %@",categoryId];
    } else {
        return nil;
    }
    
    NSArray *fetchedData = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                                             matchingPredicate:predicate];
    if (fetchedData && ([fetchedData count] > 0)) {
        return [fetchedData objectAtIndex:0];
    } else {
        return nil;
    }
}

- (FacilitiesLocation*)locationForId:(NSString*)locationId {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uid == %@",locationId];
    NSArray *fetchedData = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                                             matchingPredicate:predicate];
    if (fetchedData && ([fetchedData count] > 0)) {
        return [fetchedData objectAtIndex:0];
    } else {
        return nil;
    }
}

/* Categories array should be in the form:
 *  [
 *      {
 *          'categoryName': <Name>
 *          'categoryId': <ID>
 *          'subcategories': <[Categories]>
 *      }
 *      ...
 *  ]
 */
- (void)updateCategoryTitles:(NSArray*)categories {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    NSMutableArray *addedCategories = [NSMutableArray array];
    
    for (NSDictionary *catData in categories) {
        FacilitiesCategory *category = [self categoryForId:[catData objectForKey:@"categoryId"]];
                                        
        if (category == nil) {
            category = [cdm insertNewObjectForEntityForName:@"FacilitiesCategory"];
        }
        
        category.uid = [catData objectForKey:@"categoryId"];
        category.name = [catData objectForKey:@"categoryName"];
        
        NSArray *subcategories = [catData objectForKey:@"subcategories"];
        if (subcategories) {
            for (NSDictionary *subData in subcategories) {
                FacilitiesCategory *subCat = [self categoryForId:[subData objectForKey:@"categoryId"]];
                if (subCat == nil) {
                    subCat = [[CoreDataManager coreDataManager] insertNewObjectForEntityForName:@"FacilitiesCategory"];
                }
                
                subCat.uid = [subData objectForKey:@"categoryId"];
                subCat.name = [subData objectForKey:@"categoryName"];
                subCat.parent = category;
                [addedCategories addObject:[subData objectForKey:@"categoryId"]];
            }
        }
        
        [addedCategories addObject:[catData objectForKey:@"categoryId"]];
    }
    
    NSArray *allCategories = [cdm objectsForEntity:@"FacilitiesCategory"
                                 matchingPredicate:[NSPredicate predicateWithValue:YES]];
    for (FacilitiesCategory *category in allCategories) {
        if ([addedCategories containsObject:category.uid] == NO) {
            [cdm deleteObject:category];
        }
    }
    
    [cdm saveData];
}

- (void)updateLocationsInCategory:(NSString*)categoryId
                        withArray:(NSArray*)locData {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    FacilitiesCategory *category = [self categoryForId:categoryId];
    NSMutableArray *added = [NSMutableArray array];
    
    for (NSDictionary *loc in locData) {
        FacilitiesLocation *location = [self locationForId:[loc objectForKey:@"id"]];
        
        if (location == nil) {
            location = [cdm insertNewObjectForEntityForName:@"FacilitiesLocation"];
        }
        
        location.uid = [loc objectForKey:@"id"];
        if ([loc objectForKey:@"displayname"]) {
            location.name = [loc objectForKey:@"displayname"];
        } else {
            location.name = [loc objectForKey:@"name"];
        }
        
        location.longitude = [NSNumber numberWithDouble:[[loc objectForKey:@"long_wgs84"] doubleValue]];
        location.latitude = [NSNumber numberWithDouble:[[loc objectForKey:@"lat_wgs84"] doubleValue]];
        if ([location.categories containsObject:category] == NO) {
            [location addCategoriesObject:category];
        }
        
        [added addObject:[loc objectForKey:@"id"]];
    }
    
    NSSet *tmpLocations = [NSSet setWithSet:category.locations];
    for (FacilitiesLocation *location in tmpLocations) {
        if ([added containsObject:location.uid] == NO) {
            if ([location.categories count] == 1) {
                [cdm deleteObject:location];
            } else {
                [location removeCategoriesObject:[self categoryForId:categoryId]];
            }
        }
    }
    
    [cdm saveData];
}

#pragma mark -
#pragma mark JSONDataLoaded Delegate
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    if ([request.userData isEqualToString:FacilitiesCategoryKey]) {
        [self updateCategoryTitles:(NSArray*)JSONObject];
        [self removeRequest:request
              fromQueueName:FacilitiesCategoryKey];
    } else if ([request.userData isEqualToString:FacilitiesLocationsKey]) {
        [self updateLocationsInCategory:[request.params objectForKey:@"id"]
                              withArray:(NSArray*)JSONObject];
        [self removeRequest:request
              fromQueueName:FacilitiesLocationsKey];
    }
    
    dispatch_group_notify(_defaultGroup, _requestUpdateQueue, ^{
        BOOL queueEmpty = YES;
        for(NSArray *reqs in [_requestsInFlight allValues]) {
            queueEmpty = queueEmpty && ([reqs count] == 0);
        }
        
        if (queueEmpty) {
            dispatch_async(dispatch_get_main_queue(),^{
                NSArray *blocks = [[_notificationBlocks copy] autorelease];
                for(FacilitiesDataAvailableBlock block in blocks) {
                    dispatch_async(dispatch_get_main_queue(),block);
                }
            });
        }
    });
 }

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
    return NO;
}


#pragma mark -
#pragma mark Singleton Implementation
+ (FacilitiesLocationData*)sharedData {
    if (_sharedData == nil) {
        _sharedData = [[super allocWithZone:NULL] init];
    }
    
    return _sharedData;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedData] retain];
}

- (id)copyWithZone:(NSZone*)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)release {
    return;
}

- (id)autorelease {
    return self;
}

@end
