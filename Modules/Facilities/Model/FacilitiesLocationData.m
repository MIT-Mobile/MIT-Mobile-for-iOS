#import "FacilitiesLocationData.h"

#import "CoreDataManager.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "FacilitiesPropertyOwner.h"
#import "FacilitiesContent.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"
#import "FacilitiesRepairType.h"
#import "ModuleVersions.h"
#import "MobileRequestOperation.h"

NSString* const FacilitiesDidLoadDataNotification = @"MITFacilitiesDidLoadData";

NSString * const FacilitiesCategoriesKey = @"categorylist";
NSString * const FacilitiesLocationsKey = @"location";
NSString * const FacilitiesRoomsKey = @"room";
NSString * const FacilitiesRepairTypesKey = @"problemtype";

static NSString *FacilitiesFetchDatesKey = @"FacilitiesDataFetchDates";

static FacilitiesLocationData *_sharedData = nil;

@interface FacilitiesLocationData ()
@property (nonatomic,retain) NSOperationQueue* requestQueue;
@property (nonatomic,retain) NSMutableDictionary* notificationBlocks;

- (BOOL)shouldUpdateDataWithRequest:(MobileRequestOperation*)request;

- (void)updateCategoryData;
- (void)updateLocationData;
- (void)updateRoomData;
- (void)updateRoomDataForBuilding:(NSString*)bldgnum;
- (void)updateRepairTypeData;
- (void)updateDataForCommand:(NSString*)command params:(NSDictionary*)params;

- (void)loadCategoriesWithArray:(id)categories;
- (void)loadLocationsWithArray:(NSArray*)locations;
- (void)loadContentsForLocation:(FacilitiesLocation*)location withData:(NSArray*)contents;
- (void)loadRoomsWithData:(NSDictionary*)roomData;
- (void)loadRepairTypesWithArray:(NSArray*)typeData;

- (FacilitiesCategory*)categoryForId:(NSString*)categoryId;
- (FacilitiesLocation*)locationForId:(NSString*)locationId;
- (FacilitiesLocation*)locationWithNumber:(NSString*)bldgNumber;
- (void)sendNotificationToObservers:(NSString*)notificationName
                       withUserData:(id)userData
                   newDataAvailable:(BOOL)updated;

- (BOOL)hasActiveRequest:(MobileRequestOperation*)request;
@end

@implementation FacilitiesLocationData
@synthesize requestQueue = _requestQueue;
@synthesize notificationBlocks = _notificationBlocks;

- (id)init {
    self = [super init]; 
    
    if (self) {
        self.requestQueue = [[[NSOperationQueue alloc] init] autorelease];
        self.requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        
        self.notificationBlocks = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc {
    self.requestQueue = nil;
    self.notificationBlocks = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public Methods
- (NSArray*)allCategories {
    [self updateCategoryData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                             matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSArray*)allLocations {
    [self updateLocationData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSArray*)locationsInCategory:(NSString*)categoryId {
    [self updateLocationData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithFormat:@"(ANY categories.uid == %@)", categoryId]];
}

- (NSArray*)locationsWithinRadius:(CLLocationDistance)radiusInMeters
                       ofLocation:(CLLocation*)location
                     withCategory:(NSString*)categoryId {
    NSMutableArray *local = [NSMutableArray array];
    NSArray *locations = nil;
    
    if (categoryId) {
        locations = [self locationsInCategory:categoryId];
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

- (NSArray*)roomsForBuilding:(NSString*)bldgnum {
    [self updateRoomDataForBuilding:bldgnum];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesRoom"
                                             matchingPredicate:[NSPredicate predicateWithFormat:@"building == %@",bldgnum]];
}

- (NSArray*)roomsMatchingPredicate:(NSPredicate*)predicate {
    [self updateRoomData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesRoom"
                                             matchingPredicate:predicate];
}

- (FacilitiesRoom*)roomInBuilding:(NSString*)building onFloor:(NSString*)floor withNumber:(NSString*)number {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(building == %@) AND (floor == %@) AND (number == %@)",
                              building,
                              floor,
                              number];
    
    NSArray *results = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesRoom"
                                                         matchingPredicate:predicate];
    
    return ([results count] > 0) ? [results objectAtIndex:0] : nil;
}

- (NSArray*)allRepairTypes {
    [self updateRepairTypeData];
    NSArray *types = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesRepairType"
                                                       matchingPredicate:[NSPredicate predicateWithValue:YES]];
    return [types sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 valueForKey:@"order"] compare:[obj2 valueForKey:@"order"]];
    }];
}

- (NSArray*)hiddenBuildings {
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithFormat:@"isHiddenInBldgServices == YES"]];
}

- (NSArray*)leasedBuildings {
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithFormat:@"isLeased == YES"]];
}


- (void)addObserver:(id)observer withBlock:(FacilitiesDidLoadBlock)block {
    [self.notificationBlocks setObject:[[block copy] autorelease]
                                forKey:[observer description]];
}

- (void)removeObserver:(id)observer {
    [self.notificationBlocks removeObjectForKey:[observer description]];
}


#pragma mark - Private Methods
- (NSString*)stringForRequestParameters:(NSDictionary*)params {
    NSMutableString *string = [NSMutableString string];
    
    [string appendFormat:@"%@?",[MITMobileWebGetCurrentServerURL() absoluteString]];
    for (NSString *key in params) {
        [string appendFormat:@"%@=%@&",key, [params objectForKey:key]];
    }
    
    [string deleteCharactersInRange:NSMakeRange([string length]-1, 1)];
    return [NSString stringWithString:string];
}

- (BOOL)shouldUpdateDataWithRequest:(MobileRequestOperation*)request {
    NSDictionary *parameters = request.parameters;
    NSString *command = request.command;
    
    if ([ConnectionDetector isConnected] == NO) {
        return NO;
    }
    
    NSDate *lastCheckDate = nil;
    if ([command isEqualToString:FacilitiesRoomsKey] && [parameters objectForKey:@"building"]) {
        FacilitiesLocation *location = [self locationWithNumber:[parameters objectForKey:@"building"]];
        [[[CoreDataManager coreDataManager] managedObjectContext] refreshObject:location mergeChanges:NO];
        lastCheckDate = location.roomsUpdated;
    } else {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:FacilitiesFetchDatesKey];
        if (dict == nil) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionary]
                                                      forKey:FacilitiesFetchDatesKey];
            return YES;
        } else {
            lastCheckDate = [dict objectForKey:command];
            
            if ([lastCheckDate isKindOfClass:[NSDate class]] == NO) {
                lastCheckDate = nil;
            }
        }
    }

    NSDate *updateDate = nil;
    NSDictionary *serverDates = nil;

    if ([command isEqualToString:FacilitiesCategoriesKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"map"];
        updateDate = [serverDates objectForKey:@"category_list"];
    } else if ([command isEqualToString:FacilitiesLocationsKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"map"];
        updateDate = [serverDates objectForKey:@"location"];
    } else if ([command isEqualToString:FacilitiesRoomsKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"facilities"];
        updateDate = [serverDates objectForKey:@"room"];
    } else if ([command isEqualToString:FacilitiesRepairTypesKey]) {
        serverDates = [[ModuleVersions sharedVersions] lastUpdateDatesForModule:@"facilities"];
        updateDate = [serverDates objectForKey:@"problem_type"];
    } else {
        updateDate = [NSDate distantFuture];
    }

    if (lastCheckDate == nil) {
        return YES;
    } else if ([lastCheckDate timeIntervalSinceDate:updateDate] < 0) {
        return YES;
    }

    return NO;
}

- (void)updateCategoryData {
    [self updateDataForCommand:FacilitiesCategoriesKey
                        params:nil];
}

- (void)updateLocationData {
    [self updateDataForCommand:FacilitiesLocationsKey
                        params:nil];
}

- (void)updateRoomData {
    [self updateDataForCommand:FacilitiesRoomsKey
                        params:nil];
}

- (void)updateRoomDataForBuilding:(NSString*)bldgnum {
    if ((bldgnum == 0) || ([bldgnum length] == 0)) {
        [self sendNotificationToObservers:FacilitiesDidLoadDataNotification
                             withUserData:FacilitiesRoomsKey
                         newDataAvailable:NO];
        return;
    } else {
        [self updateDataForCommand:FacilitiesRoomsKey
                            params:[NSDictionary dictionaryWithObject:bldgnum forKey:@"building"]];
    }
}

- (void)updateRepairTypeData {
    [self updateDataForCommand:FacilitiesRepairTypesKey
                        params:nil];
}

- (void)updateDataForCommand:(NSString*)command params:(NSDictionary*)params {
    MobileRequestOperation *request = [[[MobileRequestOperation alloc] initWithModule:@"facilities"
                                                                              command:command
                                                                           parameters:params] autorelease];
    
    request.completeBlock = ^(MobileRequestOperation *operation, id jsonResult, NSError *error) {
        NSString *command = operation.command;
        NSDictionary *parameters = operation.parameters;
        dispatch_queue_t handlerQueue = dispatch_queue_create(NULL, 0);
        
        if (error) {
            ELog(@"Request failed with error: %@",[error localizedDescription]);
        } else {
            dispatch_async(handlerQueue, ^(void) {
                if ([command isEqualToString:FacilitiesCategoriesKey]) {
                    [self loadCategoriesWithArray:(NSArray*)jsonResult];
                } else if ([command isEqualToString:FacilitiesLocationsKey]) {
                    [self loadLocationsWithArray:(NSArray*)jsonResult];
                } else if ([command isEqualToString:FacilitiesRepairTypesKey]) {
                    [self loadRepairTypesWithArray:(NSArray*)jsonResult];
                } else if ([command isEqualToString:FacilitiesRoomsKey]) {
                    NSDictionary *roomData = (NSDictionary*)jsonResult;
                    NSString *requestedId = [parameters objectForKey:@"building"];
                    
                    if (requestedId) {
                        roomData = [NSDictionary dictionaryWithObject:[roomData objectForKey:requestedId]
                                                               forKey:requestedId];
                    }
                    
                    [self loadRoomsWithData:roomData];
                }
            
                BOOL shouldUpdateDate = !([command isEqualToString:FacilitiesRoomsKey] && [parameters objectForKey:@"building"]);
                
                if (shouldUpdateDate) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:FacilitiesFetchDatesKey]];
                    [dict setObject:[NSDate date]
                             forKey:command];
                    [[NSUserDefaults standardUserDefaults] setObject:dict
                                                              forKey:FacilitiesFetchDatesKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                
                [self sendNotificationToObservers:FacilitiesDidLoadDataNotification
                                     withUserData:command
                                 newDataAvailable:YES];
            });
            
            dispatch_release(handlerQueue);
        }
    };

    if ([self hasActiveRequest:request] == NO) {
        if ([self shouldUpdateDataWithRequest:request]) {
            [self.requestQueue addOperation:request];
        } else {
            [self sendNotificationToObservers:FacilitiesDidLoadDataNotification
                                 withUserData:command
                             newDataAvailable:NO];
        }
    } 
}


#pragma mark - Internal ID accessors
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

- (FacilitiesLocation*)locationWithNumber:(NSString*)bldgNumber {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number == %@",bldgNumber];
    NSArray *fetchedData = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                                             matchingPredicate:predicate];
    if (fetchedData && ([fetchedData count] > 0)) {
        return [fetchedData objectAtIndex:0];
    } else {
        return nil;
    }
}

- (void)sendNotificationToObservers:(NSString*)notificationName
                       withUserData:(id)userData
                   newDataAvailable:(BOOL)updated
{
    dispatch_async(dispatch_get_main_queue(),^{
        NSArray *blocks = [_notificationBlocks allValues];
        for(FacilitiesDidLoadBlock block in blocks) {
            dispatch_async(dispatch_get_main_queue(),^{ block(notificationName,updated,userData); } );
        }
    });
}


#pragma mark - JSON Loading/Updating methods
- (void)loadCategoriesWithArray:(id)categories {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    [cdm deleteObjectsForEntity:@"FacilitiesCategory"];

    if ([categories isKindOfClass:[NSArray class]]) {
        NSArray *catArray = (NSArray*)categories;
        for (NSDictionary *catData in catArray) {
            FacilitiesCategory *category = [self categoryForId:[catData objectForKey:@"id"]];
                                            
            if (category == nil) {
                category = [cdm insertNewObjectForEntityForName:@"FacilitiesCategory"];
            }
            
            category.uid = [catData objectForKey:@"id"];
            category.name = [catData objectForKey:@"name"];
            
            NSArray *locations = [cdm objectsForEntity:@"FacilitiesLocation"
                                     matchingPredicate:[NSPredicate predicateWithFormat:@"ANY categories.uid == %@", category.uid]];
            category.locations = [NSSet setWithArray:locations];
        }
    } else {
        NSDictionary *catDict = (NSDictionary*)categories;
        for (NSString *categoryId in catDict) {
            FacilitiesCategory *category = [self categoryForId:categoryId];
            
            if (category == nil) {
                category = [cdm insertNewObjectForEntityForName:@"FacilitiesCategory"];
            }
            
            NSDictionary *categoryData = [catDict valueForKey:categoryId];
            category.uid = categoryId;
            category.name = [categoryData valueForKey:@"name"];
            category.locationIds = [NSSet setWithArray:[categoryData valueForKey:@"locations"]];
            
            for (NSString *locationId in category.locationIds) {
                FacilitiesLocation *location = [self locationForId:locationId];
                if (location) {
                    [location addCategoriesObject:category];
                }
            }
        }
        
        NSArray *allLocations = [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                                                  matchingPredicate:[NSPredicate predicateWithValue:YES]];
        for (FacilitiesLocation *location in allLocations) {
            for (FacilitiesCategory *category in [location.categories allObjects]) {
                if ([category.locationIds containsObject:location.uid] == NO) {
                    [category removeLocationsObject:location];
                }
            }
        }
    }
    
    [cdm saveData];
}

- (void)loadLocationsWithArray:(NSArray*)locations {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    
    NSMutableSet *allObjects = [NSSet setWithArray:[cdm objectsForEntity:@"FacilitiesLocation"
                                                       matchingPredicate:[NSPredicate predicateWithValue:YES]]];
    NSMutableSet *modifiedObjects = [NSMutableSet set];
    
    for (NSDictionary *loc in locations) {
        FacilitiesLocation *location = [[allObjects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            if ([[obj valueForKey:@"uid"] isEqualToString:[loc objectForKey:@"id"]]) {
                *stop = YES;
                return YES;
            }
            
            return NO;
        }] anyObject];
        
        if (location == nil) {
            location = [cdm insertNewObjectForEntityForName:@"FacilitiesLocation"];
            location.uid = [loc objectForKey:@"id"];
        }
        
        location.name = [loc objectForKey:@"name"];
        location.number = [loc objectForKey:@"bldgnum"];
        
        location.longitude = [NSNumber numberWithDouble:[[loc objectForKey:@"long_wgs84"] doubleValue]];
        location.latitude = [NSNumber numberWithDouble:[[loc objectForKey:@"lat_wgs84"] doubleValue]];
        
        if ([[loc objectForKey:@"hidden_bldg_services"] boolValue] == YES) {
            location.isHiddenInBldgServices = [NSNumber numberWithBool:YES];
        }
        
        if ([[loc objectForKey:@"leased_bldg_services"] boolValue] == YES) {
            NSString *name = [loc objectForKey:@"contact-name_bldg_services"];
            if (!name) {
                WLog(@"Leased location \"%@\" missing contact name.", location.uid);
            } else {
                FacilitiesPropertyOwner *propertyOwner = [cdm getObjectForEntity:@"FacilitiesPropertyOwner" attribute:@"name" value:name];
                if (!propertyOwner) {
                    propertyOwner = [cdm insertNewObjectForEntityForName:@"FacilitiesPropertyOwner"];
                    propertyOwner.name = name;
                    propertyOwner.phone = [loc objectForKey:@"contact-phone_bldg_services"];
                    propertyOwner.email = [loc objectForKey:@"contact-email_bldg_services"];
                }
                location.propertyOwner = propertyOwner;
                location.isLeased = [NSNumber numberWithBool:YES];
            }
        }
        
        [self loadContentsForLocation:location withData:[loc objectForKey:@"contents"]];
        [modifiedObjects addObject:location];
    }
    
    NSMutableSet *deletedObjects = [NSMutableSet setWithSet:allObjects];
    [deletedObjects minusSet:modifiedObjects];
    [cdm deleteObjects:[deletedObjects allObjects]];
    
    NSArray *allCategories = [cdm objectsForEntity:@"FacilitiesCategory" matchingPredicate:[NSPredicate predicateWithValue:YES]];
    
    NSPredicate *template = [NSPredicate predicateWithFormat:@"uid in $uids"];
    
    [allCategories enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        FacilitiesCategory *category = obj;
        NSSet *locationIds = category.locationIds;
        if (locationIds) {
            NSPredicate *predicate = [template predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:locationIds forKey:@"uids"]];
            category.locations = [modifiedObjects filteredSetUsingPredicate:predicate];
        }
    }];
    
    [cdm saveData];
}

- (void)loadContentsForLocation:(FacilitiesLocation*)location withData:(NSArray*)contents {
    if ((contents == nil) || [[NSNull null] isEqual:contents]) {
        return;
    }
    
    NSMutableSet *allContents = [NSMutableSet setWithSet:location.contents];
    NSMutableSet *modifiedContents = [NSMutableSet set];
    
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    
    for (NSDictionary *contentData in contents) {
        NSString *name = [contentData objectForKey:@"name"];
        FacilitiesContent *content = [[allContents objectsPassingTest:^BOOL(id obj, BOOL *stop) {
            if ([[obj valueForKey:@"name"] isEqualToString:name]) {
                *stop = YES;
                return YES;
            }
            
            return NO;
        }] anyObject];
        
        if (content == nil) {
            content = [cdm insertNewObjectForEntityForName:@"FacilitiesContent"];
            content.location = location;
            content.name = name;
        }
        
        if ([contentData objectForKey:@"url"]) {
            content.url = [NSURL URLWithString:[contentData objectForKey:@"url"]];
        }
        
        if ([contentData objectForKey:@"altname"]) {
            content.altname = [contentData objectForKey:@"altname"];
        }
        
        [modifiedContents addObject:content];
        
        // bskinner - 07/06/2011
        // Commented out, categories are not being used
        //  at the moment.
        /*
        if ([contentData objectForKey:@"category"]) {
            NSArray *contentCategories = [contentData objectForKey:@"category"];
            for (NSString *catName in contentCategories) {
                FacilitiesCategory *category = [self categoryForId:catName];
                if (category) {
                    [content addCategoriesObject:category];
                }
            }
        }
        */
    }
    
    [allContents minusSet:modifiedContents];
    [location removeContents:allContents];
    
    if ([allContents count] > 0) {
        [cdm deleteObjects:[allContents allObjects]];
    }
}


- (void)loadRoomsWithData:(NSDictionary*)roomData {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    
    for (NSString *building in [roomData allKeys]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"building == %@",building];
        NSArray *bldgRooms = [cdm objectsForEntity:@"FacilitiesRoom"
                                 matchingPredicate:predicate];
        [cdm deleteObjects:bldgRooms];
        
        NSDictionary *floorData = [roomData objectForKey:building];
        
        if ([floorData isEqual:[NSNull null]]) {
            continue;
        }
        
        for (NSString *floor in [floorData allKeys]) {
            NSArray *rooms = [floorData objectForKey:floor];
            
            for (NSString *room in rooms) {
                FacilitiesRoom *moRoom = [cdm insertNewObjectForEntityForName:@"FacilitiesRoom"];
                moRoom.number = room;
                moRoom.floor = floor;
                moRoom.building = building;
            }
        }

        FacilitiesLocation *location = [self locationWithNumber:building];
        location.roomsUpdated = [NSDate date];
    }
    
    [cdm saveData];
}

- (void)loadRepairTypesWithArray:(NSArray*)typeData {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    [cdm deleteObjectsForEntity:@"FacilitiesRepairType"];
    
    NSInteger index = 0;
    for (NSString *type in typeData) {
        FacilitiesRepairType *repairType = [cdm insertNewObjectForEntityForName:@"FacilitiesRepairType"];
        repairType.name = type;
        repairType.order = [NSNumber numberWithInteger:index];
        ++index;
    }
    
    [cdm saveData];
}

#pragma mark - MITMobileWebAPI request management
- (BOOL)hasActiveRequest:(MobileRequestOperation*)request {
    return [[self.requestQueue operations] containsObject:request];
}


#pragma mark - Singleton Implementation
+ (void)initialize {
    if (_sharedData == nil) {
        _sharedData = [[super allocWithZone:NULL] init];
    }
}

+ (FacilitiesLocationData*)sharedData {
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

- (oneway void)release {
    return;
}

- (id)autorelease {
    return self;
}

@end
