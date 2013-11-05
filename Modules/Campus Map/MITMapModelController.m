#import <CoreData/CoreData.h>
#import "MITMapModelController.h"

#import "MITCoreDataController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileServerConfiguration.h"
#import "MobileRequestOperation.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITMapBookmark.h"
#import "MapSearch.h"
#import "MITAdditions.h"

static NSString* const MITMapResourceCategoryTitles = @"categorytitles";
static NSString* const MITMapResourceCategory = @"category";
static NSString* const MITMapDefaultsPlacesFetchDateKey = @"MITMapDefaultsPlacesFetchDate";

NSString* const MITMapSearchEntityName = @"MapSearch";
NSString* const MITMapPlaceEntityName = @"MapPlace";
NSString* const MITMapBookmarkEntityName = @"MapBookmark";

@interface MITMapModelController ()
@property (nonatomic,strong) NSOperationQueue *requestQueue;
@property (nonatomic,strong) NSDate *placesFetchDate;

+ (NSFetchRequest*)fetchRequestForMapPlacesWithPredicate:(NSPredicate*)predicate sortDescriptors:(NSArray*)sortDescriptors;
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

// TODO: Think a bit about the placement here. Should this go into
// MITMapPlace instead?
+ (NSFetchRequest*)fetchRequestForMapPlacesWithPredicate:(NSPredicate*)predicate
                                         sortDescriptors:(NSArray*)sortDescriptors
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MapPlace"];

    NSMutableArray *predicates = [[NSMutableArray alloc] init];
    NSPredicate *defaultPredicate = [NSPredicate predicateWithFormat:@"identifier != NIL"];
    [predicates addObject:defaultPredicate];
    if (predicate) {
        [predicates addObject:predicate];
    }

    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    if (![sortDescriptors count]) {
        sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
    }

    fetchRequest.sortDescriptors = sortDescriptors;

    return fetchRequest;
}

- (id)init
{
    self = [super init];

    if (self) {
        _requestQueue = [[NSOperationQueue alloc] init];
        _requestQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;

        // Default to 1 week (measured in seconds) expiration interval for recent searches and
        // cached place data
        _searchExpiryInterval = (60. * 60. * 24. * 7);
        _placeExpiryInterval = (60. * 60. * 24. * 7);

        [self migrateBookmarks];
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
    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
    [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError **error) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"searchTerm == %@", queryString];

        MapSearch *mapSearch = [[context executeFetchRequest:fetchRequest error:nil] lastObject];
        if (!mapSearch) {
            mapSearch = [NSEntityDescription insertNewObjectForEntityForName:MITMapSearchEntityName
                                                      inManagedObjectContext:context];
        }

        mapSearch.searchTerm = queryString;
        mapSearch.date = [NSDate date];

        [context save:error];

        if (error) {
            DDLogWarn(@"Failed to save search: %@", (*error));
        }
    }
                                        completion:nil];
}

/** Synchronously updates cached MapPlace entities in the CoreData model.
 *
 *  @param placesData The array of 'place' dictionaries.
 *  @param incrementalUpdate If NO, delete any cached entities which do not have any associated data in placesData
 *  @related MITMapPlace
 */
- (void)updatePlacesWithData:(NSArray*)placesData incrementalUpdate:(BOOL)incremental completion:(void (^)(NSError *error))block
{
    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
    [dataController performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        // Create a mapping of {identifier => object} for each of the objects in the
        // response. This will make it easier later on to figure out all the objects
        // we need to update/insert/delete
        NSMutableDictionary *placesByIdentifier = [[NSMutableDictionary alloc] init];
        for (NSDictionary *placeDictionary in placesData) {
            placesByIdentifier[placeDictionary[@"id"]] = placeDictionary;
        }

        // Fetch any existing cached objects and massage them into a dictionary (by identifier)
        // so it's a bit easier to figure out adds/deletes/updates
        NSMutableDictionary *fetchedPlaces = [[NSMutableDictionary alloc] init];
        {
            NSFetchRequest *placesFetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
            if (incremental) {
                // If we are performing a partial update, don't delete anything
                // Just get any existing cached objects (matching in the 'id' key)
                // and update/insert any new ones
                placesFetchRequest.predicate = [NSPredicate predicateWithFormat:@"(identifier != nil) AND (identifier IN %@)", [placesByIdentifier allKeys]];
            } else {
                // Make sure we filter out anything that lacks an identifier.
                // Places which do not have an identifier should be children of
                // places which do have an identifier. When the parent places are updated
                // *all* of their children which lack an identifier should be deleted
                // and then re-created from the data.
                placesFetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier != nil"];
            }

            NSArray *places = [context executeFetchRequest:placesFetchRequest error:error];

            if (places) {
                for (MITMapPlace *place in places) {
                    if (place.identifier) {
                        fetchedPlaces[place.identifier] = place;
                    }
                }
            } else {
                // Something went wrong with the fetch.
                // The error should be set at this point so just return
                return;
            }
        }


        NSSet *fetchedIdentifiers = [NSSet setWithArray:[fetchedPlaces allKeys]];
        NSSet *newIdentifiers =  [NSSet setWithArray:[placesByIdentifier allKeys]];

        NSMutableSet *modifiedIdentifiers = [[NSMutableSet alloc] initWithSet:fetchedIdentifiers];
        [modifiedIdentifiers intersectSet:newIdentifiers];
        [modifiedIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, BOOL *stop) {
            MITMapPlace *place = fetchedPlaces[identifier];
            [place performUpdate:placesByIdentifier[identifier]];

        }];

        NSMutableSet *insertedIdentifiers = [[NSMutableSet alloc] initWithSet:newIdentifiers];
        [insertedIdentifiers minusSet:fetchedIdentifiers];
        [insertedIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, BOOL *stop) {
            MITMapPlace *place = [NSEntityDescription insertNewObjectForEntityForName:MITMapPlaceEntityName inManagedObjectContext:context];
            [place performUpdate:placesByIdentifier[identifier]];
        }];

        if (!incremental) {
            NSMutableSet *deletedIdentifiers = [[NSMutableSet alloc] initWithSet:fetchedIdentifiers];
            [deletedIdentifiers minusSet:newIdentifiers];
            [deletedIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, BOOL *stop) {
                [context deleteObject:fetchedPlaces[identifier]];
            }];
        }

        [context save:error];
    }
                                 completion:^(NSError *error) {
                                     if (error) {
                                         DDLogWarn(@"Failed to save 'place' update: %@", error);
                                     }

                                     if (block) {
                                         block(error);
                                     }
                                 }];
}

#pragma mark Asynchronous
- (void)recentSearches:(MITMapFetchedResult)block
{
    [self recentSearchesForPartialString:nil loaded:block];
}

- (void)recentSearchesForPartialString:(NSString*)string loaded:(MITMapFetchedResult)block
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"searchTerm" ascending:YES]];
    if (string) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"token BEGINSWITH[d] %@", [string stringBySearchNormalization]];
    }

    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {

        NSArray *searches = [context executeFetchRequest:fetchRequest
                                                   error:error];

        if (!error) {
            [searches enumerateObjectsUsingBlock:^(MapSearch *search, NSUInteger idx, BOOL *stop) {
                NSTimeInterval searchInterval = fabs([search.date timeIntervalSinceNow]);
                if (searchInterval > self.searchExpiryInterval) {
                    [context deleteObject:search];
                }
            }];

            [context save:error];

            if ((*error)) {
                DDLogWarn(@"Failed to save search results: %@", *error);
            }
        }
    }

                                                            completion:^(NSError *error) {
                                                                if (block) {
                                                                    if (error) {
                                                                        block(nil,self.placesFetchDate,error);
                                                                    } else {
                                                                        block(fetchRequest,self.placesFetchDate,nil);
                                                                    }
                                                                }
                                                            }];
}


- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMapFetchedResult)block
{
    NSDictionary *parameters = nil;
    if (queryString) {
        parameters = @{@"q" : queryString};
    }

    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"search"
                                                                             parameters:parameters];

    apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
        [self addRecentSearch:queryString];

        if (!error) {
            if ([content isKindOfClass:[NSArray class]]) {
                [self updatePlacesWithData:content incrementalUpdate:YES completion:^(NSError *error) {
                    NSFetchRequest *fetchRequest = nil;

                    if (error) {
                        DDLogWarn(@"failed to perform incremental place update for query '%@': %@", queryString, error);
                    } else {
                        // TODO: This may need to be changed once we start using the MIT Mobile v3 API
                        // since it may be returning a bunch of identifiers instead of the complete
                        // data for each place in the result.
                        NSMutableOrderedSet *identifiers = [[NSMutableOrderedSet alloc] init];
                        for (NSDictionary *placeData in content) {
                            [identifiers addObject:placeData[@"id"]];
                        }

                        NSPredicate *fetchPredicate = [NSPredicate predicateWithFormat:@"(identifier != nil) AND (identifier IN %@)", identifiers];
                        fetchRequest = [MITMapModelController fetchRequestForMapPlacesWithPredicate:fetchPredicate sortDescriptors:nil];
                    }

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(fetchRequest,self.placesFetchDate,error);
                        }
                    }];
                }];
            } else {
                NSError *remoteError = nil;

                if ([content isKindOfClass:[NSDictionary class]]) {
                    remoteError = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorResourceUnavailable
                                                  userInfo:content];
                } else {
                    remoteError = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:nil];
                }

                DDLogWarn(@"'places' update failed with error %@", remoteError);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(nil,self.placesFetchDate,remoteError);
                    }
                }];
            }
        } else {
            DDLogWarn(@"'places' contents request failed with error %@", error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(nil,self.placesFetchDate,error);
                }
            }];
        }
    };

    [self.requestQueue addOperation:apiRequest];
}


- (void)categories:(MITMapResult)block
{
    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"categorytitles"
                                                                             parameters:nil];

    apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
        if (!error) {
            if ([content isKindOfClass:[NSArray class]]) {
                NSMutableOrderedSet *categories = [[NSMutableOrderedSet alloc] init];

                for (NSDictionary *categoryData in content) {
                    MITMapCategory *category = [[MITMapCategory alloc] initWithDictionary:categoryData];
                    [categories addObject:category];
                }

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(categories, error);
                    }
                }];
            } else if ([content isKindOfClass:[NSDictionary class]]) {
                NSDictionary *serverErrorInfo = (NSDictionary*)content;
                NSError *serverError = [NSError errorWithDomain:NSURLErrorDomain
                                                           code:NSURLErrorResourceUnavailable
                                                       userInfo:serverErrorInfo];

                DDLogWarn(@"[categories] 'places' update failed with error %@", serverError);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(nil,serverError);
                    }
                }];
            }
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(nil,error);
                }
            }];
        }
    };

    [self.requestQueue addOperation:apiRequest];
}

- (void)places:(MITMapFetchedResult)block
{
    BOOL cacheHasExpired = (fabs([self.placesFetchDate timeIntervalSinceNow]) > self.placeExpiryInterval);

    if (cacheHasExpired) {
        NSURL *serverURL = MITMobileWebGetCurrentServerURL();
        NSURL *requestURL = [NSURL URLWithString:@"/apis/map/places" relativeToURL:serverURL];
        MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithURL:requestURL parameters:nil];
        __weak MITMapModelController *weakSelf = self;
        apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
            MITMapModelController *blockSelf = weakSelf;
            if (!error) {
                if ([content isKindOfClass:[NSArray class]]) {
                    [blockSelf updatePlacesWithData:content
                                  incrementalUpdate:NO
                                         completion:^(NSError *error) {
                                             if (error) {
                                                 DDLogError(@"Failed to update entites for 'places': %@", error);
                                             } else {
                                                 blockSelf.placesFetchDate = [NSDate date];
                                             }

                                             if (block) {
                                                 NSFetchRequest *fetchRequest = [MITMapModelController fetchRequestForMapPlacesWithPredicate:nil
                                                                                                                             sortDescriptors:nil];
                                                 block(fetchRequest,blockSelf.placesFetchDate,error);
                                             }
                                         }];
                } else {
                    NSError *remoteError = nil;

                    if ([content isKindOfClass:[NSDictionary class]]) {
                        remoteError = [NSError errorWithDomain:NSURLErrorDomain
                                                          code:NSURLErrorResourceUnavailable
                                                      userInfo:content];
                    } else {
                        remoteError = [NSError errorWithDomain:NSURLErrorDomain
                                                          code:NSURLErrorBadServerResponse
                                                      userInfo:nil];
                    }

                    DDLogWarn(@"'places' request failed with error %@", error);
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(nil,blockSelf.placesFetchDate,remoteError);
                        }
                    }];
                }
            } else {
                DDLogWarn(@"'places' request failed with error %@", error);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(nil,blockSelf.placesFetchDate,error);
                    }
                }];
            }
        };

        [self.requestQueue addOperation:apiRequest];
    } else if (block) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSFetchRequest *fetchRequest = [MITMapModelController fetchRequestForMapPlacesWithPredicate:nil
                                                                                        sortDescriptors:nil];
            block(fetchRequest,self.placesFetchDate,nil);
        }];
    }
}


- (void)placesInCategory:(MITMapCategory*)category loaded:(MITMapFetchedResult)block
{
    NSDictionary *requestParameters = nil;
    if (category) {
        requestParameters = @{@"id" : category.identifier};
    }

    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"category"
                                                                             parameters:requestParameters];

    apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
        if (!error) {
            if ([content isKindOfClass:[NSArray class]]) {
                [self updatePlacesWithData:content incrementalUpdate:YES completion:^(NSError *error) {
                    NSFetchRequest *fetchRequest = nil;

                    if (error) {
                        DDLogWarn(@"Failed to update places for category '%@': %@",category.identifier, error);
                    } else if (block) {
                        NSMutableSet *identifiers = [[NSMutableSet alloc] init];
                        for (NSDictionary *placeData in content) {
                            [identifiers addObject:placeData[@"id"]];
                        }

                        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(identifier IN %@)", identifiers];
                        fetchRequest = [MITMapModelController fetchRequestForMapPlacesWithPredicate:predicate sortDescriptors:nil];
                    }

                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if (block) {
                            block(fetchRequest,self.placesFetchDate,error);
                        }
                    }];
                }];
            } else {
                NSError *remoteError = nil;

                if ([content isKindOfClass:[NSDictionary class]]) {
                    remoteError = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorResourceUnavailable
                                                  userInfo:content];
                } else {
                    remoteError = [NSError errorWithDomain:NSURLErrorDomain
                                                      code:NSURLErrorBadServerResponse
                                                  userInfo:nil];
                }

                DDLogWarn(@"'places' update failed with error %@", remoteError);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(nil,self.placesFetchDate,remoteError);
                    }
                }];
            }
        } else {
            DDLogWarn(@"category contents request failed with error %@", error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(nil,self.placesFetchDate,error);
                }
            }];
        }
    };

    [self.requestQueue addOperation:apiRequest];
}

#pragma mark - Map Bookmarks
- (void)bookmarkedPlaces:(MITMapFetchedResult)block
{
    [self places:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (block) {
            NSPredicate *bookmarkPredicate = [NSPredicate predicateWithFormat:@"bookmark != NIL"];
            NSPredicate *andPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[bookmarkPredicate, fetchRequest.predicate]];
            fetchRequest.predicate = andPredicate;

            NSMutableArray *sortDescriptors = [[NSMutableArray alloc] initWithArray:fetchRequest.sortDescriptors];
            [sortDescriptors insertObject:[NSSortDescriptor sortDescriptorWithKey:@"bookmark.order" ascending:YES]
                                  atIndex:0];

            fetchRequest.sortDescriptors = sortDescriptors;

            block(fetchRequest,lastUpdated,error);
        }
    }];
}

- (NSUInteger)numberOfBookmarks
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"bookmark != NIL"];

    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
    NSManagedObjectContext *context = [dataController mainQueueContext];

    __block NSUInteger numberOfBookmarks = NSNotFound;
    [context performBlockAndWait:^{
        NSError *error = nil;
        numberOfBookmarks = [context countForFetchRequest:fetchRequest error:&error];

        if (error) {
            DDLogWarn(@"Failed to fetch bookmark count with error %@", error);
        }
    }];

    return numberOfBookmarks;
}

- (void)bookmarkPlaces:(NSArray*)places completion:(void (^)(NSError* error))block
{
    NSPredicate *notBookmarked = [NSPredicate predicateWithFormat:@"bookmark == NIL"];
    NSArray *newBookmarkedPlaces = [places filteredArrayUsingPredicate:notBookmarked];

    if (![newBookmarkedPlaces count]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(nil);
            }
        }];
    } else {
        [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
            NSArray *localPlaces = [context transferManagedObjects:newBookmarkedPlaces];

            NSMutableArray *insertedBookmarks = [[NSMutableArray alloc] init];
            [localPlaces enumerateObjectsUsingBlock:^(MITMapPlace *mapPlace, NSUInteger idx, BOOL *stop) {
                MITMapBookmark *bookmarkObject = [NSEntityDescription insertNewObjectForEntityForName:MITMapBookmarkEntityName inManagedObjectContext:context];
                bookmarkObject.place = mapPlace;
                [insertedBookmarks addObject:bookmarkObject];
            }];


            // Now grab all the bookmarks from the DB and update their indices. If there are
            // repeated indicies, this may change the desired order but we will be guaranteed
            // that each index is unique.
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapBookmarkEntityName];
            bookmarksRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSArray *fetchedBoomarks = [context executeFetchRequest:bookmarksRequest error:error];

            if (!fetchedBoomarks) {
                DDLogWarn(@"Failed to update bookmark indices %@", (*error));
            } else {
                NSMutableArray *bookmarks = [NSMutableArray arrayWithArray:fetchedBoomarks];
                [bookmarks addObjectsFromArray:insertedBookmarks];

                // Just in case run through all the other fetched bookmarks and make sure their ordering is correct
                [bookmarks enumerateObjectsUsingBlock:^(MITMapBookmark *bookmark, NSUInteger idx, BOOL *stop) {
                    bookmark.order = @(idx);
                }];
            }

            // Will overwrite the fetch error (if one occurred).
            // This is the desired behavior as a save error is
            // far more critical than just failing to uniquify
            // the ordering.
            [context save:error];
        }
                                                                completion:^(NSError *error) {
                                                                    if (block) {
                                                                        block(error);
                                                                    }
                                                                }];
    }
}

- (void)removeBookmarkForPlace:(MITMapPlace*)place completion:(void (^)(NSError* error))block
{
    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        MITMapPlace *localPlace = (MITMapPlace*)[context objectWithID:[place objectID]];

        if (localPlace.bookmark) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapBookmarkEntityName];
            bookmarksRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSError *error = nil;
            NSMutableArray *bookmarks = [[context executeFetchRequest:bookmarksRequest error:&error] mutableCopy];

            if (error) {
                DDLogWarn(@"Failed to fetch bookmarks with error %@", error);
            } else {
                [bookmarks removeObject:localPlace.bookmark];
                [context deleteObject:localPlace.bookmark];

                // Run through all the bookmarks and make sure their ordering is correct (taking into account
                // the deletion)
                [bookmarks enumerateObjectsUsingBlock:^(MITMapBookmark *bookmark, NSUInteger idx, BOOL *stop) {
                    bookmark.order = @(idx);
                }];

                [context save:&error];

                if (error) {
                    DDLogWarn(@"Failed to remove bookmark for '%@' with error %@", [localPlace identifier], error);
                }
            }
        }
    }

                                                            completion:^(NSError *error) {
                                                                if (block) {
                                                                    block(error);
                                                                }
                                                            }];
}

- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index completion:(void (^)(NSError* error))block
{
    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        MITMapPlace *localPlace = (MITMapPlace*)[context objectWithID:[place objectID]];

        if (localPlace.bookmark) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapBookmarkEntityName];
            bookmarksRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSArray *fetchResults = [context executeFetchRequest:bookmarksRequest error:error];
            NSMutableOrderedSet *bookmarks = [[NSMutableOrderedSet alloc] initWithArray:fetchResults];

            if (!fetchResults) {
                DDLogError(@"Failed to fetch bookmarks with error %@", *error);
            } else {
                NSUInteger fromIndex = [bookmarks indexOfObject:localPlace.bookmark];

                [bookmarks moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:index];

                [bookmarks enumerateObjectsUsingBlock:^(MITMapBookmark *bookmark, NSUInteger idx, BOOL *stop) {
                    bookmark.order = @(idx);
                }];

                [context save:error];

                if (error) {
                    DDLogWarn(@"Failed to move bookmark for '%@' to index %d with error %@", localPlace.identifier,index,*error);
                }
            }
        }
    }
                                                            completion:^(NSError *error) {
                                                                if (block) {
                                                                    block(error);
                                                                }
                                                            }];
}

- (void)migrateBookmarks
{
    NSURL *userDocumentsURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                     inDomain:NSUserDomainMask
                                                            appropriateForURL:nil
                                                                       create:NO
                                                                        error:nil];

    NSURL *bookmarksURL = [NSURL URLWithString:@"mapBookmarks.plist"
                                 relativeToURL:userDocumentsURL];

    NSArray *bookmarksV1 = [NSArray arrayWithContentsOfURL:bookmarksURL];
    if (bookmarksV1) {
        // Migrate the bookmarks from the original version of the app
        // The format of the saved bookmarks changed in the 3.5 release
        NSMutableOrderedSet *bookmarkedIdentifiers = [[NSMutableOrderedSet alloc] init];
        for (NSDictionary *savedBookmark in bookmarksV1) {
            [bookmarkedIdentifiers addObject:savedBookmark[@"id"]];
        }
        
        [self places:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
            if (!error) {
                NSPredicate *migratedBookmarks = [NSPredicate predicateWithFormat:@"identifier IN %@", bookmarkedIdentifiers];
                fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[fetchRequest.predicate,migratedBookmarks]];
                
                NSManagedObjectContext *context = [[MITCoreDataController defaultController] mainQueueContext];
                [context performBlockAndWait:^{
                    NSArray *places = [context executeFetchRequest:fetchRequest error:nil];
                    [self bookmarkPlaces:places completion:^(NSError *error) {
                        if (!error) {
#if !defined(DEBUG) || defined(TESTFLIGHT)
                            [[NSFileManager defaultManager] removeItemAtURL:bookmarksURL
                                                                      error:nil];
#endif //DEBUG
                        } else {
                            DDLogError(@"Failed to migrate bookmarks: %@", error);
                        }
                    }];
                }];
            }
        }];
    }
}

@end
