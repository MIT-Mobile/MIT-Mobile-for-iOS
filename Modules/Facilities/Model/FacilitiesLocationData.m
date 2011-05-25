#import "FacilitiesLocationData.h"

#import "CoreDataManager.h"
#import "FacilitiesCategory.h"
#import "FacilitiesLocation.h"
#import "FacilitiesRoom.h"
#import "MITMobileWebAPI.h"
#import "MITMobileServerConfiguration.h"
#import "ConnectionDetector.h"

NSString* const FacilitiesDidLoadDataNotification = @"MITFacilitiesDidLoadData";

NSString * const FacilitiesCategoriesKey = @"categorylist";
NSString * const FacilitiesLocationsKey = @"location";
NSString * const FacilitiesRoomsKey = @"room";

static NSString *FacilitiesFetchDatesKey = @"FacilitiesDataFetchDates";

static FacilitiesLocationData *_sharedData = nil;

@interface FacilitiesLocationData ()
@property (nonatomic,retain) NSMutableDictionary* requestsInFlight;
@property (nonatomic,retain) NSMutableDictionary* notificationBlocks;

- (BOOL)shouldUpdateDataWithRequestParams:(NSDictionary*)request;
- (NSDate*)remoteDate;

- (void)updateCategoryData;
- (void)updateLocationData;
- (void)updateRoomData;
- (void)updateRoomDataForBuilding:(NSString*)bldgnum;
- (void)updateDataForCommand:(NSString*)command params:(NSDictionary*)params;

- (FacilitiesCategory*)categoryForId:(NSString*)categoryId;
- (FacilitiesLocation*)locationForId:(NSString*)locationId;
- (void)sendNotificationToObservers:(NSString*)notificationName
                       withUserData:(id)userData
                   newDataAvailable:(BOOL)updated;

- (BOOL)isQueueEmpty;
- (void)addRequest:(MITMobileWebAPI*)request withName:(NSString*)name;
- (void)removeRequestWithName:(NSString*)name;
- (BOOL)hasActiveRequestWithName:(NSString*)name;
@end

@implementation FacilitiesLocationData
@synthesize requestsInFlight = _requestsInFlight;
@synthesize notificationBlocks = _notificationBlocks;

- (id)init {
    self = [super init]; 
    
    if (self) {
        self.requestsInFlight = [NSMutableDictionary dictionary];
        self.notificationBlocks = [NSMutableDictionary dictionary];
        _requestUpdateQueue = dispatch_queue_create("edu.mit.mobile.facilities.requestQueue", NULL);
    }
    
    return self;
}

- (void)dealloc {
    self.requestsInFlight = nil;
    self.notificationBlocks = nil;
    
    dispatch_release(_requestUpdateQueue);
    [super dealloc];
}


#pragma mark -
#pragma mark Public Methods
- (NSArray*)allCategories {
    [self updateCategoryData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                             matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSArray*)categoriesMatchingPredicate:(NSPredicate*)predicate {
    [self updateCategoryData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesCategory"
                                             matchingPredicate:predicate];
}

- (NSArray*)allLocations {
    [self updateLocationData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithValue:YES]];
}

- (NSArray*)locationsMatchingPredicate:(NSPredicate*)predicate {
    [self updateLocationData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:predicate];
}

- (NSArray*)locationsInCategory:(NSString*)categoryId {
    [self updateLocationData];
    return [[CoreDataManager coreDataManager] objectsForEntity:@"FacilitiesLocation"
                                             matchingPredicate:[NSPredicate predicateWithFormat:@"ANY categories.uid == %@", categoryId]];
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


- (void)addObserver:(id)observer withBlock:(FacilitiesDidLoadBlock)block
{
    [self.notificationBlocks setObject:[[block copy] autorelease]
                                forKey:[observer description]];
    
    if ([self isQueueEmpty]) {
        dispatch_async(dispatch_get_main_queue(), ^{ block(nil,NO,nil); });
    }
}

- (void)removeObserver:(id)observer {
    [self.notificationBlocks removeObjectForKey:[observer description]];
}


#pragma mark -
#pragma mark Private Methods
- (NSString*)stringForRequestParameters:(NSDictionary*)params {
    NSMutableString *string = [NSMutableString string];
    
    [string appendFormat:@"%@?",[MITMobileWebGetCurrentServerURL() absoluteString]];
    for (NSString *key in params) {
        [string appendFormat:@"%@=%@&",key, [params objectForKey:key]];
    }
    
    [string deleteCharactersInRange:NSMakeRange([string length]-1, 1)];
    return [NSString stringWithString:string];
}

- (BOOL)shouldUpdateDataWithRequestParams:(NSDictionary*)request {
    NSString *command = [request objectForKey:@"command"];
    
    if ([ConnectionDetector isConnected] == NO) {
        return NO;
    }
    
    NSDate *date = nil;
    
    if ([command isEqualToString:FacilitiesRoomsKey] && [request objectForKey:@"building"]) {
        FacilitiesLocation *location = [self locationForId:[request objectForKey:@"building"]];
        date = location.roomsUpdated;
    } else {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:FacilitiesFetchDatesKey];
        if (dict == nil) {
            return YES;
        }
        
        NSString *dateString = [dict objectForKey:command];
        NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
        [df setDateFormat:@"yyyy-MM-dd"];
        
        date = [df dateFromString:dateString];
    }
    
    if (date == nil) {
        return YES;  
    } else if ([[NSDate date] timeIntervalSinceDate:date] < 86400) {
        return NO;
    } else {
        return YES;
    }
}

- (NSDate*)remoteDate {
    return [NSDate distantPast];
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
        return;
    } else {
        [self updateDataForCommand:FacilitiesRoomsKey
                            params:[NSDictionary dictionaryWithObject:bldgnum forKey:@"building"]];
    }
}

- (void)updateDataForCommand:(NSString*)command params:(NSDictionary*)params {
    MITMobileWebAPI *web = [[[MITMobileWebAPI alloc] initWithJSONLoadedDelegate:self] autorelease];
    
    NSMutableDictionary *paramDict = nil;
    if (params) {
        paramDict = [NSMutableDictionary dictionaryWithDictionary:params];
    } else {
        paramDict = [NSMutableDictionary dictionary];
    }
    
    [paramDict setObject:command
               forKey:@"command"];
    
    NSString *requestDescription = [self stringForRequestParameters:paramDict];
    if ([self hasActiveRequestWithName:requestDescription] == NO) {
        if ([self shouldUpdateDataWithRequestParams:paramDict]) {
            [self addRequest:web
                    withName:requestDescription];
            [web requestObject:paramDict
                 pathExtension:@"map/"];
        } else {
            [self sendNotificationToObservers:FacilitiesDidLoadDataNotification
                                 withUserData:command
                             newDataAvailable:NO];
        }
    } 
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

- (void)updateCategoriesWithArray:(NSArray*)categories {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    [cdm deleteObjectsForEntity:@"FacilitiesCategory"];
    
    if ([[categories objectAtIndex:0] isKindOfClass:[NSString class]]) {
        for (NSString *catId in categories) {
            NSString *catName = [catId stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            catName = [catName capitalizedString];
            
            FacilitiesCategory *category = [cdm insertNewObjectForEntityForName:@"FacilitiesCategory"];
            
            category.uid = catId;
            category.name = catName;
            
            NSArray *locations = [cdm objectsForEntity:@"FacilitiesLocation"
                                     matchingPredicate:[NSPredicate predicateWithFormat:@"ANY categories.uid == %@", category.uid]];
            category.locations = [NSSet setWithArray:locations];
        }
    } else {
        for (NSDictionary *catData in categories) {
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
    }
    
    [cdm saveData];
}

- (void)updateLocationsWithArray:(NSArray*)locations {
    CoreDataManager *cdm = [CoreDataManager coreDataManager];
    NSMutableSet *addedIds = [NSMutableSet set];
    
    for (NSDictionary *loc in locations) {
        FacilitiesLocation *location = [self locationForId:[loc objectForKey:@"id"]];
        
        if (location == nil) {
            location = [cdm insertNewObjectForEntityForName:@"FacilitiesLocation"];
        }
        
        location.uid = [loc objectForKey:@"id"];
        location.name = [loc objectForKey:@"name"];
        location.number = [loc objectForKey:@"bldgnum"];
        
        location.longitude = [NSNumber numberWithDouble:[[loc objectForKey:@"long_wgs84"] doubleValue]];
        location.latitude = [NSNumber numberWithDouble:[[loc objectForKey:@"lat_wgs84"] doubleValue]];
        
        
        NSArray *categories = (NSArray*)([loc objectForKey:@"category"]);
        NSMutableSet *set = nil;
        for (NSString *categoryId in categories) {
            FacilitiesCategory *category = [self categoryForId:categoryId];
            set = [NSMutableSet setWithSet:location.categories];
            [set addObject:category];
        }
        
        location.categories = set;
        
        [addedIds addObject:location.uid];
    }
    
    NSArray *allLocations = [cdm objectsForEntity:@"FacilitiesLocation"
                                matchingPredicate:[NSPredicate predicateWithValue:YES]];
    
    for (FacilitiesLocation *location in allLocations) {
        if ([addedIds containsObject:location.uid] == NO) {
            [cdm deleteObject:location];
        }
    }
    
    [cdm saveData];
}


- (void)updateRoomsWithArray:(NSDictionary*)roomData {
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
        
        FacilitiesLocation *location = [self locationForId:building];
        location.roomsUpdated = [NSDate date];
    }
    
    [cdm saveData];
}


- (void)addRequest:(MITMobileWebAPI*)request withName:(NSString*)name {
    dispatch_async(_requestUpdateQueue, ^{
        [self.requestsInFlight setObject:request
                                  forKey:name];
    });
}

- (void)removeRequestWithName:(NSString*)name {
    dispatch_async(_requestUpdateQueue, ^{
        [self.requestsInFlight removeObjectForKey:name];
    });
}

- (BOOL)hasActiveRequestWithName:(NSString*)name {
    BOOL result = NO;
    
    dispatch_suspend(_requestUpdateQueue);
    result = ([self.requestsInFlight objectForKey:name] != nil);
    dispatch_resume(_requestUpdateQueue);
    
    return result;
}

- (BOOL)isQueueEmpty {
    BOOL result = NO;
    
    dispatch_suspend(_requestUpdateQueue);
    result = ([self.requestsInFlight count] == 0);
    dispatch_resume(_requestUpdateQueue);
    
    return result;
}


#pragma mark -
#pragma mark JSONDataLoaded Delegate
- (void)request:(MITMobileWebAPI *)request jsonLoaded:(id)JSONObject {
    NSString *command = [request.params objectForKey:@"command"];
    
    if ([command isEqualToString:FacilitiesCategoriesKey]) {
        [self updateCategoriesWithArray:(NSArray*)JSONObject];
    } else if ([command isEqualToString:FacilitiesLocationsKey]) {
        [self updateLocationsWithArray:(NSArray*)JSONObject];
    } else if ([command isEqualToString:FacilitiesRoomsKey]) {
        NSDictionary *roomData = (NSDictionary*)JSONObject;
        NSString *requestedId = [request.params objectForKey:@"building"];
        
        if (requestedId) {
            roomData = [NSDictionary dictionaryWithObject:[roomData objectForKey:requestedId]
                                                   forKey:requestedId];
        }
        
        [self updateRoomsWithArray:roomData];
    }
    
    BOOL shouldUpdateDate = !([command isEqualToString:FacilitiesRoomsKey] && [request.params objectForKey:@"building"]);
    
    if (shouldUpdateDate) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:FacilitiesFetchDatesKey]];
        NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
        [df setDateFormat:@"yyyy-MM-dd"];
        [dict setValue:[df stringFromDate:[NSDate date]]
                forKey:command];
        [[NSUserDefaults standardUserDefaults] setObject:dict
                                                  forKey:FacilitiesFetchDatesKey];
    }
    
    [self removeRequestWithName:[self stringForRequestParameters:request.params]];
    [self sendNotificationToObservers:FacilitiesDidLoadDataNotification
                         withUserData:command
                     newDataAvailable:YES];
}

- (BOOL)request:(MITMobileWebAPI *)request shouldDisplayStandardAlertForError: (NSError *)error {
    dispatch_sync(_requestUpdateQueue, ^{
        for (MITMobileWebAPI *lrequest in [self.requestsInFlight allValues]) {
            [lrequest abortRequest];
        }
        
        [self.requestsInFlight removeAllObjects];
    });
    return YES;
}


#pragma mark -
#pragma mark Singleton Implementation
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

- (void)release {
    return;
}

- (id)autorelease {
    return self;
}

@end
