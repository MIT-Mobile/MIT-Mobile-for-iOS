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
    [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context) {
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
            DDLogWarn(@"Failed to save search: %@", error);
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
    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
    [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context) {
        NSMutableDictionary *placesByIdentifier = [[NSMutableDictionary alloc] init];
        for (NSDictionary *placeDictionary in placesData) {
            placesByIdentifier[placeDictionary[@"id"]] = placeDictionary;
        }


        // Fetch any existing cached objects and massage them into a dictionary (by identifier)
        // so it's a bit easier to figure out adds/deletes/updates
        NSMutableDictionary *fetchedPlaces = [[NSMutableDictionary alloc] init];
        {
            NSFetchRequest *placesFetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
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
                DDLogWarn(@"'places' update failed on fetch: %@", error);
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
            MITMapPlace *place = [NSEntityDescription insertNewObjectForEntityForName:MITMapPlaceEntityName inManagedObjectContext:context];
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
            DDLogWarn(@"Failed to save 'place' update: %@", error);
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
    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];

    [dataController performBackgroundUpdate:^(NSManagedObjectContext *context) {
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                                    [NSSortDescriptor sortDescriptorWithKey:@"searchTerm" ascending:YES]];

        if (string) {
            request.predicate = [NSPredicate predicateWithFormat:@"token BEGINSWITH[d] %@", [string stringBySearchNormalization]];
        }

        NSError *fetchError = nil;
        NSArray *searches = [context executeFetchRequest:request
                                                   error:&fetchError];

        NSMutableOrderedSet *searchObjects = nil;
        if (!fetchError) {
            searchObjects = [[NSMutableOrderedSet alloc] init];

            // Run through all the search objects and unique them based
            // on their normalized form (same-cased & whitespace and punctuation removed)
            [searches enumerateObjectsUsingBlock:^(MapSearch *search, NSUInteger idx, BOOL *stop) {
                NSTimeInterval searchInterval = fabs([search.date timeIntervalSinceNow]);
                if (searchInterval > self.searchExpiryInterval) {
                    [context deleteObject:search];
                } else {
                    [searchObjects addObject:search];
                }
            }];

            [context save:nil];
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSManagedObjectContext *mainContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
            NSArray *results = [mainContext transferManagedObjects:[searchObjects array]];

            if (block) {
                block([NSOrderedSet orderedSetWithArray:results],request,self.placesFetchDate,fetchError);
            }
        }];
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

    [self.requestQueue addOperation:apiRequest];
}


- (void)categories:(MITMapResult)block
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

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(categories, error);
            }
        }];
    };

    [self.requestQueue addOperation:apiRequest];
}

- (void)places:(MITMapFetchedResult)block
{
    [self placesWithPredicate:nil loaded:block];
}

- (void)placesWithPredicate:(NSPredicate*)predicate loaded:(MITMapFetchedResult)block
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
    fetchRequest.predicate = predicate;
    [self placesWithFetchRequest:fetchRequest loaded:block];
}

- (void)placesWithFetchRequest:(NSFetchRequest*)fetchRequest loaded:(MITMapFetchedResult)block
{
    NSMutableArray *operations = [[NSMutableArray alloc] init];

    void (^performAsynchronousFetchBlock)(void) = ^{
        MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];

        [dataController performBackgroundUpdate:^(NSManagedObjectContext *context) {
            NSError *error = nil;
            NSArray *places = [context executeFetchRequest:fetchRequest error:&error];

            if (error) {
                DDLogWarn(@"'places' fetch failed with error %@",error);
            } else if (places) {
                DDLogVerbose(@"Returning %d places for predicate: %@",[places count],fetchRequest.predicate);
            }

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                NSManagedObjectContext *mainContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
                NSArray *mainPlaces =[mainContext transferManagedObjects:places];

                if (block) {
                    block([NSOrderedSet orderedSetWithArray:mainPlaces],fetchRequest,self.placesFetchDate,error);
                }
            }];
        }];
    };

    // Known issue: Calling this method several times rapidly can lead to URL requests
    // being added to the queue until the first one completes and the refresh date is updated
    BOOL cacheHasExpired = (fabs([self.placesFetchDate timeIntervalSinceNow]) > self.placeExpiryInterval);
    if (cacheHasExpired) {
        // The data we have has either expired or it was never fetched to being with
        // Since we need to figure out which it is, perform a quick fetch on the main
        // context to grab the count of MapPlace entities in the DB. If it's more than zero
        // assume there is cached data (albeit stale) available that we can respond
        // with
        __block BOOL dataIsAvailable = NO;
        NSManagedObjectContext *mainContext = [[[MIT_MobileAppDelegate applicationDelegate] coreDataController] mainQueueContext];
        [mainContext performBlockAndWait:^{
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
            NSUInteger count = [mainContext countForFetchRequest:request error:nil];
            dataIsAvailable = ((count != NSNotFound) && (count > 0));
        }];

        NSBlockOperation *fetchOperation = nil;
        if (!dataIsAvailable) {
            // The fetch request should only go onto the queue if there is no
            // cached data availble. This way, it forces the URL
            // request to complete and then issues the fetch request
            // to the DB
            fetchOperation = [NSBlockOperation blockOperationWithBlock:^{
                performAsynchronousFetchBlock();
            }];

            __weak NSOperation *weakFetch = fetchOperation;
            fetchOperation.completionBlock = ^{
                if ([weakFetch isCancelled]) {
                    if (block) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                                                 code:NSUserCancelledError
                                                             userInfo:nil];
                            block(nil,nil,self.placesFetchDate,error);
                        }];
                    }
                }
            };
        }

        NSURL *serverURL = MITMobileWebGetCurrentServerURL();
        NSURL *requestURL = [NSURL URLWithString:@"/apis/map/places" relativeToURL:serverURL];
        MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithURL:requestURL parameters:nil];
        apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
            if (error) {
                DDLogWarn(@"'places' update failed with error %@", error);
                [fetchOperation cancel];
            } else if ([content isKindOfClass:[NSDictionary class]]) {
                NSError *requestError = [NSError errorWithDomain:NSURLErrorDomain
                                                            code:NSURLErrorResourceUnavailable
                                                        userInfo:content];

                DDLogWarn(@"'places' update failed with error %@", requestError);
                [fetchOperation cancel];
            } else if ([content isKindOfClass:[NSArray class]]) {
                [self updateCachedPlaces:content partialUpdate:NO];
                self.placesFetchDate = [NSDate date];
            }
        };

        [operations addObject:apiRequest];

        if (fetchOperation) {
            [fetchOperation addDependency:apiRequest];
            [operations addObject:fetchOperation];
        } else {
            // The fetch operation wasn't create so we won't be adding it to the queue
            // The only way to get here is if we have valid cached data in the store
            // so just perform the fetch to return what we have while the update
            // request is doing its thing.
            performAsynchronousFetchBlock();
        }

        [self.requestQueue addOperations:operations waitUntilFinished:NO];
    } else {
        // The cached data has *not* expired yet so just perform the fetch
        // and GTFO!
        performAsynchronousFetchBlock();
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

    [self.requestQueue addOperation:apiRequest];
}

#pragma mark - Map Bookmarks
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

- (void)bookmarkedPlaces:(MITMapFetchedResult)block
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"bookmark != NIL"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"bookmark.order" ascending:YES]];

    [self placesWithFetchRequest:fetchRequest loaded:block];
}

- (void)addBookmarkForPlace:(MITMapPlace*)place
{
    if (!place.bookmark) {
        NSManagedObjectID *placeID = place.objectID;
        MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
        [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapBookmarkEntityName];
            bookmarksRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSError *error = nil;
            MITMapPlace *localPlace = (MITMapPlace*)[context objectWithID:placeID];
            NSArray *bookmarks = [context executeFetchRequest:bookmarksRequest error:&error];

            if (error) {
                DDLogWarn(@"Failed to fetch bookmark count with error %@", error);
            } else {
                MITMapBookmark *bookmarkObject = [NSEntityDescription insertNewObjectForEntityForName:MITMapBookmarkEntityName inManagedObjectContext:context];
                bookmarkObject.order = @([bookmarks count]);
                bookmarkObject.place = localPlace;

                // Just in case there were cascaded deletions (ie: a place which was bookmarked no longer
                // exists and was deleted in a previous update), run through all the bookmarks and make sure
                // their ordering is correct
                [bookmarks enumerateObjectsUsingBlock:^(MITMapBookmark *bookmark, NSUInteger idx, BOOL *stop) {
                    bookmark.order = @(idx);
                }];

                [context save:&error];

                if (error) {
                    DDLogWarn(@"Failed to add bookmark for '%@' with error %@", [localPlace identifier], error);
                }
            }
        }];
    }
}

- (void)removeBookmarkForPlace:(MITMapPlace*)place
{
    if (place.bookmark) {
        NSManagedObjectID *placeID = place.objectID;
        MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];

        [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapBookmarkEntityName];
            bookmarksRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSError *error = nil;
            MITMapPlace *localPlace = (MITMapPlace*)[context objectWithID:placeID];
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
        }];
    }
}

- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index
{
    if (place.bookmark) {
        NSManagedObjectID *bookmarkID = [place.bookmark objectID];

        MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
        [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapBookmarkEntityName];
            bookmarksRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

            NSError *error = nil;
            MITMapBookmark *localBookmark = (MITMapBookmark*)[context objectWithID:bookmarkID];
            NSArray *fetchResults = [context executeFetchRequest:bookmarksRequest error:&error];
            NSMutableOrderedSet *bookmarks = [[NSMutableOrderedSet alloc] initWithArray:fetchResults];

            if (error) {
                DDLogError(@"Failed to fetch bookmarks with error %@", error);
            } else {
                NSUInteger fromIndex = [bookmarks indexOfObject:localBookmark];

                [bookmarks moveObjectsAtIndexes:[NSIndexSet indexSetWithIndex:fromIndex] toIndex:index];

                [bookmarks enumerateObjectsUsingBlock:^(MITMapBookmark *bookmark, NSUInteger idx, BOOL *stop) {
                    bookmark.order = @(idx);
                }];

                [context save:&error];

                if (error) {
                    DDLogWarn(@"Failed to move bookmark for '%@' to index %d with error %@", [localBookmark.place identifier],index,error);
                }
            }
        }];
    }
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

        NSPredicate *migratedBookmarkPredicate = [NSPredicate predicateWithFormat:@"(bookmark == NIL) AND (identifier IN %@)", bookmarkedIdentifiers];
        [self placesWithPredicate:migratedBookmarkPredicate
                           loaded:^(NSOrderedSet *places, NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
                               if (!error) {
                                   for (MITMapPlace *place in places) {
                                       [self addBookmarkForPlace:place];
                                   }
                                   
#if !(defined(DEBUG) || defined(TESTFLIGHT))
                                   [[NSFileManager defaultManager] removeItemAtURL:bookmarksURL
                                                                             error:nil];
#endif //DEBUG
                               }
                           }];
    }
}

@end
