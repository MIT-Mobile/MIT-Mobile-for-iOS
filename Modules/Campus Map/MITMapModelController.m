#import <CoreData/CoreData.h>
#import "CoreDataManager.h"

#import "MITMobileServerConfiguration.h"
#import "MITMapModelController.h"
#import "MobileRequestOperation.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MapSearch.h"
#import "MITAdditions.h"

static NSString* const MITMapResourceCategoryTitles = @"categorytitles";
static NSString* const MITMapResourceCategory = @"category";

static NSString* const MITMapDefaultsPlacesFetchDateKey = @"MITMapDefaultsPlacesFetchDate";

NSString* const MITMapSearchEntityName = @"MapSearch";

@interface MITMapModelController ()
@property (nonatomic,strong) NSOperationQueue *requestQueue;
@property (nonatomic,strong) NSDate *placesFetchDate;

- (void)addRecentSearch:(NSString*)queryString;
@end

@implementation MITMapModelController
@synthesize placesFetchDate = _placesFetchDate;

+ (MITMapModelController*)sharedController
{
    static MITMapModelController *sharedController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedController = [[MITMapModelController alloc] init];
    });
    
    return sharedController;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = 1;

        // Default to 1 week (measured in seconds) expiration interval for recent searches and
        // cached place data
        _searchExpiryInterval = (60. * 60. * 24. * 7);
        _placeExpiryInterval = (60. * 60. * 24. * 7);
    }
    
    return self;
}

#pragma mark - Dynamic Properties
- (void)setPlacesFetchDate:(NSDate *)placesFetchDate
{
    if (![_placesFetchDate isEqualToDate:placesFetchDate]) {
        _placesFetchDate = placesFetchDate;
        [[NSUserDefaults standardUserDefaults] setObject:_placesFetchDate forKey:MITMapDefaultsPlacesFetchDateKey];
    }
}

- (NSDate*)placesFetchDate
{
    if (!_placesFetchDate) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [defaults removeObjectForKey:MITMapDefaultsPlacesFetchDateKey];
        NSDate *fetchDate = [defaults objectForKey:MITMapDefaultsPlacesFetchDateKey];

        if (fetchDate) {
            // Directly assign to the ivar so we don't trigger the setter's side effect
            // of writing the date to the user defaults
            _placesFetchDate = fetchDate;
        } else {
            _placesFetchDate = [NSDate distantPast];
        }
    }

    return _placesFetchDate;
}


#pragma mark - Search, Create, Read methods
#pragma mark Synchronous
- (void)addRecentSearch:(NSString*)queryString
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];

    [context performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"searchTerm == %@", queryString];

        MapSearch *mapSearch = [[context executeFetchRequest:fetchRequest error:nil] lastObject];
        if (!mapSearch) {
            mapSearch = [NSEntityDescription insertNewObjectForEntityForName:MITMapSearchEntityName
                                                      inManagedObjectContext:context];
        }

        mapSearch.searchTerm = queryString;
        mapSearch.date = [NSDate date];

        NSError *error = nil;
        [context save:&error];

        if (error) {
            DDLogError(@"Failed to save search: %@", error);
        }
    }];
}

/** Synchronously updates cached MapPlace entities in the CoreData model.
 *
 *  @param placesData The array of 'place' dictionaries.
 *  @param partialUpdate If NO, delete any cached entities which do not have any associated data in placesData
 *  @see MITMapPlace
 */
- (void)updateCachedPlaces:(NSArray*)placesData partialUpdate:(BOOL)partialUpdate
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
    [context performBlockAndWait:^{
        NSMutableDictionary *placesByIdentifier = [[NSMutableDictionary alloc] init];
        for (NSDictionary *placeDictionary in placesData) {
            placesByIdentifier[placeDictionary[@"id"]] = placeDictionary;
        }


        // Fetch any existing cached objects and massage them into a dictionary (by identifier)
        // so it's a bit easier to figure out adds/deletes/updates
        NSMutableDictionary *fetchedPlaces = [[NSMutableDictionary alloc] init];
        {
            NSFetchRequest *placesFetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MapPlace"];
            if (partialUpdate) {
                // If we are performing a partial update, don't delete anything
                // Just get any existing cached objects (matching in the 'id' key)
                // and update/insert any new ones
                placesFetchRequest.predicate = [NSPredicate predicateWithFormat:@"(identifier != nil) AND (identifier IN %@)", [placesByIdentifier allKeys]];
            }

            NSError *error = nil;
            NSArray *places = [context executeFetchRequest:placesFetchRequest error:&error];

            // If the fetch failed, don't even try to update the database with what we have;
            // Something seriously bad happened so just abort the whole thing.
            if (error) {
                DDLogError(@"'places' update failed on fetch: %@", error);
                return;
            }

            for (MITMapPlace *place in places) {
                if (place.identifier) {
                    fetchedPlaces[place.identifier] = place;
                }
            }
        }


        NSSet *fetchedIdentifiers = [NSSet setWithArray:[fetchedPlaces allKeys]];
        NSSet *newIdentifiers =  [NSSet setWithArray:[placesByIdentifier allKeys]];

        NSMutableSet *modifiedIdentifiers = [[NSMutableSet alloc] initWithSet:fetchedIdentifiers];
        [modifiedIdentifiers intersectSet:newIdentifiers];
        [modifiedIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, BOOL *stop) {
            MITMapPlace *place = fetchedPlaces[identifier];
            [place performUpdate:placesByIdentifier[identifier] inManagedObjectContext:context];

        }];

        NSMutableSet *insertedIdentifiers = [[NSMutableSet alloc] initWithSet:newIdentifiers];
        [insertedIdentifiers minusSet:fetchedIdentifiers];
        [insertedIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, BOOL *stop) {
            MITMapPlace *place = [NSEntityDescription insertNewObjectForEntityForName:@"MapPlace" inManagedObjectContext:context];
            [place performUpdate:placesByIdentifier[identifier] inManagedObjectContext:context];
        }];

        if (!partialUpdate) {
            NSMutableSet *deletedIdentifiers = [[NSMutableSet alloc] initWithSet:fetchedIdentifiers];
            [deletedIdentifiers minusSet:newIdentifiers];
            [deletedIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, BOOL *stop) {
                [context deleteObject:fetchedPlaces[identifier]];
            }];
        }

        NSError *error = nil;
        [context save:&error];

        if (error) {
            DDLogError(@"Failed to save 'place' update: %@", error);
        }
    }];
}

#pragma mark Asynchronous
- (void)recentSearches:(MITMapResponse)block
{
    [self recentSearchesForPartialString:nil loaded:block];
}

- (void)recentSearchesForPartialString:(NSString*)string loaded:(MITMapResponse)block
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];

    [context performBlock:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"searchTerm" ascending:YES]];

        if (string) {
            request.predicate = [NSPredicate predicateWithFormat:@"token BEGINSWITH[d] %@", [string stringBySearchNormalization]];
        }

        NSError *fetchError = nil;
        NSArray *searches = [context executeFetchRequest:request
                                                   error:&fetchError];

        NSMutableOrderedSet *searchObjectIDs = nil;
        if (!fetchError) {
            searchObjectIDs = [[NSMutableOrderedSet alloc] init];

            // Run through all the search objects and unique them based
            // on their normalized form (same-cased & whitespace and punctuation removed)
            [searches enumerateObjectsUsingBlock:^(MapSearch *search, NSUInteger idx, BOOL *stop) {
                NSTimeInterval searchInterval = fabs([search.date timeIntervalSinceNow]);
                if (searchInterval > self.searchExpiryInterval) {
                    [context deleteObject:search];
                } else {
                    [searchObjectIDs addObject:[search objectID]];
                }
            }];

            [context save:nil];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(searchObjectIDs,[NSDate date],YES,fetchError);
            }
        });
    }];
}


- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMapResponse)block
{
    NSDictionary *parameters = nil;
    if (queryString) {
        parameters = @{@"q" : queryString};
    }
    
    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"search"
                                                                             parameters:parameters];
    
    apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
        [self addRecentSearch:queryString];
        [self updateCachedPlaces:content partialUpdate:YES];

        if (!error) {
            NSMutableOrderedSet *identifiers = [[NSMutableOrderedSet alloc] init];
            for (NSDictionary *placeData in content) {
                [identifiers addObject:placeData[@"id"]];
            }

            NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(identifier != nil) AND (identifier IN %@)", identifiers];
            [self placesWithPredicate:fetchPredicate loaded:block];
        }
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}


- (void)categories:(MITMapResponse)block
{
    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"categorytitles"
                                                                             parameters:nil];
    
    apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {
        NSMutableOrderedSet *categories = [[NSMutableOrderedSet alloc] init];
        
        for (NSDictionary *categoryData in content) {
            MITMapCategory *category = [[MITMapCategory alloc] initWithDictionary:categoryData];
            [categories addObject:category];
        }
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block(categories, [NSDate date], YES, error);
            }
        });
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}

- (void)places:(MITMapResponse)block
{
    [self placesWithPredicate:nil loaded:block];
}

- (void)placesWithPredicate:(NSPredicate*)predicate loaded:(MITMapResponse)block
{
    static dispatch_queue_t requestQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const char *queueName = [NSStringFromSelector(_cmd) cStringUsingEncoding:NSUTF8StringEncoding];
        requestQueue = dispatch_queue_create(queueName, 0);
    });

    dispatch_async(requestQueue, ^{
        NSTimeInterval lastUpdatedInterval = fabs([self.placesFetchDate timeIntervalSinceNow]);

        if (lastUpdatedInterval > self.placeExpiryInterval) {
            NSURL *serverURL = MITMobileWebGetCurrentServerURL();
            NSURL *requestURL = [NSURL URLWithString:@"/apis/map/places" relativeToURL:serverURL];
            MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithURL:requestURL parameters:nil];
            apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
                if (error) {
                    DDLogError(@"'places' update failed with error %@", error);

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (block) {
                            block(nil,self.placesFetchDate,YES,error);
                        }
                    });
                } else if ([content isKindOfClass:[NSDictionary class]]) {
                    NSError *requestError = [NSError errorWithDomain:NSURLErrorDomain
                                                                code:NSURLErrorResourceUnavailable
                                                            userInfo:nil];

                    DDLogError(@"'places' update failed with error %@", requestError);

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (block) {
                            block(nil,self.placesFetchDate,YES,requestError);
                        }
                    });
                } else if ([content isKindOfClass:[NSArray class]]) {
                    [self updateCachedPlaces:content partialUpdate:NO];
                    self.placesFetchDate = [NSDate date];

                    // The update completed, re-add this request to any queued requests
                    // and the next pass thru, we should get some results back!
                    // Since we updated the placesFetchDate above, this shouldn't result
                    // in an infinite loop.
                    [self placesWithPredicate:predicate loaded:block];
                }

                dispatch_resume(requestQueue);
            };

            [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
            dispatch_suspend(requestQueue);
        } else {
            NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            context.persistentStoreCoordinator = [[CoreDataManager coreDataManager] persistentStoreCoordinator];
            [context performBlockAndWait:^{
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MapPlace"];
                fetchRequest.predicate = predicate;

                NSError *error = nil;
                NSArray *places = [context executeFetchRequest:fetchRequest error:&error];

                if (error) {
                    DDLogError(@"'places' fetch failed with error %@",error);
                }

                NSMutableOrderedSet *objectIdentifiers = nil;
                if (places) {
                    DDLogVerbose(@"Returning %d places for predicate: %@",[places count],predicate);

                    objectIdentifiers = [[NSMutableOrderedSet alloc] init];
                    [places enumerateObjectsUsingBlock:^(MITMapPlace *mapPlace, NSUInteger idx, BOOL *stop) {
                        DDLogVerbose(@"\t%@ (%@)",mapPlace.identifier, [mapPlace title]);
                        if (![[mapPlace objectID] isTemporaryID]) {
                            [objectIdentifiers addObject:[mapPlace objectID]];
                        }

                    }];
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (block) {
                        block(objectIdentifiers,self.placesFetchDate,YES,error);
                    }
                });
            }];
        }
    });
}

- (void)placesInCategory:(MITMapCategory*)category loaded:(MITMapResponse)block
{
    NSDictionary *requestParameters = nil;
    if (category) {
        requestParameters = @{@"id" : category.identifier};
    }

    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"category"
                                                                             parameters:requestParameters];

    apiRequest.completeBlock = ^(MobileRequestOperation *operation, NSArray* content, NSString *mimeType, NSError *error) {

        if (!error) {
            NSMutableSet *identifiers = [[NSMutableSet alloc] init];
            for (NSDictionary *placeData in content) {
                [identifiers addObject:placeData[@"id"]];
            }

            NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(identifier != NIL) AND (identifier IN %@)", identifiers];
            [self placesWithPredicate:fetchPredicate loaded:block];
        }
    };

    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}

@end
