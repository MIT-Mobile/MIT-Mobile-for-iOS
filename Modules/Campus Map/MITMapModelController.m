#import <CoreData/CoreData.h>
#import "MITAdditions.h"
#import "MITMapModelController.h"

#import "MITMobileServerConfiguration.h"
#import "MITCoreData.h"

#import "MITMapPlace.h"
#import "MITMapSearch.h"
#import "MITMapCategory.h"

static NSString* const MITMapDefaultsPlacesFetchDateKey = @"MITMapDefaultsPlacesFetchDate";

@interface MITMapModelController ()
@property (nonatomic,strong) NSDate *placesFetchDate;
@end

@implementation MITMapModelController

+ (instancetype)sharedController
{
    static MITMapModelController *modelController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modelController = [[self alloc] init];
    });

    return modelController;
}

+ (NSString *)sanitizeMapSearchString:(NSString *)searchString
{
    NSString *buildingNumber;
    NSArray *roomComponents = [searchString componentsSeparatedByString:@"-"];
    NSString *firstComponent = roomComponents.firstObject;
    if (firstComponent.length == 1 && firstComponent.intValue == 0) {
        // First component is a letter.  Someone probably put N-51 or E-15 instead of N51 or E15
        if (roomComponents.count >= 2) {
            NSString *secondComponent = roomComponents[1];
            if (secondComponent.intValue > 0) {
                buildingNumber = [NSString stringWithFormat:@"%@%@", firstComponent, secondComponent];
            }
        } else {
            buildingNumber = searchString;
        }
    } else {
        buildingNumber = firstComponent;
    }
    
    buildingNumber = [buildingNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    buildingNumber = [buildingNumber stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return buildingNumber;
}

- (instancetype)init
{
    self = [super init];

    if (self) {
        // Default to 1 week (measured in seconds) expiration interval for recent searches and
        // cached place data
        _searchExpiryInterval = (60. * 60. * 24. * 7);
    }

    return self;
}

#pragma mark - Search, Create, Read methods
#pragma mark Synchronous
- (NSManagedObjectID *)addRecentSearch:(id)query
{
    if (![query isKindOfClass:[NSString class]] && ![query isKindOfClass:[MITMapPlace class]] && ![query isKindOfClass:[MITMapCategory class]]) {
        return nil;
    }
    
    __block NSManagedObjectID *searchObjectID = nil;
    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
    NSError *updateError = nil;
    BOOL success = [dataController performBackgroundUpdateAndWait:^BOOL(NSManagedObjectContext *context, NSError *__autoreleasing *error) {

        BOOL blockSuccess = NO;

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITMapSearch entityName]];
        if ([query isKindOfClass:[NSString class]]) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"searchTerm == %@", query];
        } else if ([query isKindOfClass:[MITMapPlace class]]) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"place == %@", query];
        } else if ([query isKindOfClass:[MITMapCategory class]]) {
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"category == %@", query];
        }
        
        MITMapSearch *mapSearch = [[context executeFetchRequest:fetchRequest error:nil] lastObject];
        if (!mapSearch) {
            mapSearch = [NSEntityDescription insertNewObjectForEntityForName:[MITMapSearch entityName]
                                                      inManagedObjectContext:context];
        }
        
        id localQuery = query;
        if ([query isKindOfClass:[NSManagedObject class]]) {
            localQuery = [[context transferManagedObjects:@[query]] firstObject];
        }

        if ([localQuery isKindOfClass:[NSString class]]) {
            mapSearch.searchTerm = localQuery;
        } else if ([localQuery isKindOfClass:[MITMapPlace class]]) {
            mapSearch.place = localQuery;
        } else if ([localQuery isKindOfClass:[MITMapCategory class]]) {
            mapSearch.category = localQuery;
        }

        mapSearch.date = [NSDate date];
        
        [context save:error];
        
        if (!*error) {
            blockSuccess = [context obtainPermanentIDsForObjects:@[mapSearch] error:error];

            if (!*error) {
                searchObjectID = [mapSearch objectID];
            }
        }
        return blockSuccess;
    } error:nil];
    
    if (!success) {
        DDLogWarn(@"failed to add recent search': %@",updateError);
    }
    
    return searchObjectID;
}

#pragma mark Asynchronous
- (NSFetchRequest*)recentSearches:(MITMobileManagedResult)block
{
    return [self recentSearchesForPartialString:nil loaded:block];
}

- (NSFetchRequest*)recentSearchesForPartialString:(NSString*)string loaded:(MITMobileManagedResult)block
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITMapSearch entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO],
                                     [NSSortDescriptor sortDescriptorWithKey:@"token" ascending:YES]];
    if (string) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"token BEGINSWITH[d] %@", [string stringBySearchNormalization]];
    }

    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        NSArray *searches = [context executeFetchRequest:fetchRequest
                                                   error:error];

        if (!*error) {
            [searches enumerateObjectsUsingBlock:^(MITMapSearch *search, NSUInteger idx, BOOL *stop) {
                NSTimeInterval searchInterval = fabs([search.date timeIntervalSinceNow]);
                if (searchInterval > self.searchExpiryInterval) {
                    [context deleteObject:search];
                }
            }];

            [context save:error];

            if (error && (*error)) {
                DDLogWarn(@"Failed to save search results: %@", *error);
            }
        }
    } completion:^(NSError *error) {
        if (block) {
            if (!error) {
                block(fetchRequest,self.placesFetchDate,nil);
            } else {
                block(nil,self.placesFetchDate,error);
            }
        }
    }];

    return fetchRequest;
}

- (void)clearRecentSearchesWithCompletion:(void (^)(NSError* error))block
{
    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITMapSearch entityName]];
        NSArray *searches = [context executeFetchRequest:fetchRequest
                                                   error:error];
        
        if (!*error) {
            [searches enumerateObjectsUsingBlock:^(MITMapSearch *search, NSUInteger idx, BOOL *stop) {
                [context deleteObject:search];
            }];
            
            [context save:error];
            
            if (error && (*error)) {
                DDLogWarn(@"Failed to save search results: %@", *error);
            }
        }
    } completion:^(NSError *error) {
        if (block) {
            block(error);
        }
    }];
}

- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMobileResult)block
{
    NSParameterAssert(queryString);
    NSParameterAssert(block);
    [MITMapPlacesResource placesWithQuery:queryString loaded:block];
}


- (NSFetchRequest*)categories:(MITMobileManagedResult)block
{
    return [MITMapCategoriesResource categories:block];
}

- (NSFetchRequest*)places:(MITMobileManagedResult)block
{
    return [MITMapPlacesResource placesInCategory:nil loaded:block];
}


- (void)placesInCategory:(MITMapCategory*)category loaded:(MITMobileManagedResult)block
{
    NSParameterAssert(category);
    [MITMapPlacesResource placesInCategory:category.identifier loaded:block];
}

#pragma mark - Map Bookmarks
- (NSFetchRequest*)bookmarkedPlaces:(MITMobileManagedResult)block
{
    if ([self bookmarkMigrationNeeded]) {
        [self migrateBookmarks];
    }

    NSPredicate *bookmarkPredicate = [NSPredicate predicateWithFormat:@"bookmark != nil"];
    NSSortDescriptor *bookmarkSortDescriptors = [NSSortDescriptor sortDescriptorWithKey:@"bookmark.order" ascending:YES];

    NSFetchRequest *fetchRequest = [self places:^(NSFetchRequest *fetchRequest, NSDate *lastUpdated, NSError *error) {
        if (block) {
            fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[bookmarkPredicate,fetchRequest.predicate]];

            NSMutableArray *sortDescriptors = [NSMutableArray arrayWithArray:fetchRequest.sortDescriptors];
            [sortDescriptors insertObject:bookmarkSortDescriptors atIndex:0];
            fetchRequest.sortDescriptors = sortDescriptors;

            block(fetchRequest,lastUpdated,error);
        }
    }];


    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[bookmarkPredicate,fetchRequest.predicate]];

    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithArray:fetchRequest.sortDescriptors];
    [sortDescriptors insertObject:bookmarkSortDescriptors atIndex:0];
    fetchRequest.sortDescriptors = sortDescriptors;
    return fetchRequest;
}

// This takes an array, and returns a keyed dictionary, because otherwise we'd
// have to fetch request for each individual name desired, rather than just
// making one fetch.
- (void)buildingNamesForBuildingNumbers:(NSArray *)buildingNumbers completion:(void (^)(NSArray *, NSError *))completion
{
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMapPlacesResourceName
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSHTTPURLResponse *response, NSError *error) {
                                                    if (!error) {
                                                        NSArray *buildingNames = [self buildingNamesFromResults:result.array buildingNumbers:buildingNumbers];
                                                        completion(buildingNames, nil);
                                                    } else {
                                                        completion(nil, error);
                                                    }
                                                }];
}

- (NSArray *)buildingNamesFromResults:(NSArray *)resultsArray buildingNumbers:(NSArray *)buildingNumbers
{
    NSMutableArray *buildingNames = [[NSMutableArray alloc] init];
    for (NSString *buildingNumber in buildingNumbers) {
        NSString *buildingName = buildingNumber;
        for (MITMapPlace *place in resultsArray) {
            if ([place.buildingNumber isEqualToString:buildingNumber]) {
                buildingName = [NSString stringWithFormat:@"%@ - %@", buildingName, [place.name uppercaseString]];
                break;
            }
        }
        [buildingNames addObject:buildingName];
    }
    return buildingNames.count > 0 ? buildingNames : nil;
}

- (NSUInteger)numberOfBookmarks
{
    if ([self bookmarkMigrationNeeded]) {
        [self migrateBookmarks];
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[MITMapPlace entityName]];
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
    if ([self bookmarkMigrationNeeded]) {
        [self migrateBookmarks];
    }


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
                MITMapBookmark *bookmarkObject = [NSEntityDescription insertNewObjectForEntityForName:[MITMapBookmark entityName] inManagedObjectContext:context];
                bookmarkObject.place = mapPlace;
                [insertedBookmarks addObject:bookmarkObject];
            }];


            // Now grab all the bookmarks from the DB and update their indices. If there are
            // repeated indicies, this may change the desired order but we will be guaranteed
            // that each index is unique.
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMapBookmark entityName]];
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
        } completion:^(NSError *error) {
            if (block) {
                block(error);
            }
        }];
    }
}

- (void)removeBookmarkForPlace:(MITMapPlace*)place completion:(void (^)(NSError* error))block
{
    if ([self bookmarkMigrationNeeded]) {
        [self migrateBookmarks];
    }

    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        MITMapPlace *localPlace = (MITMapPlace*)[context objectWithID:[place objectID]];

        if (localPlace.bookmark) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMapBookmark entityName]];
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
    } completion:^(NSError *error) {
        if (block) {
            block(error);
        }
    }];
}

- (void)moveBookmarkForPlace:(MITMapPlace*)place toIndex:(NSUInteger)index completion:(void (^)(NSError* error))block
{
    if ([self bookmarkMigrationNeeded]) {
        [self migrateBookmarks];
    }

    [[MITCoreDataController defaultController] performBackgroundUpdate:^(NSManagedObjectContext *context, NSError **error) {
        MITMapPlace *localPlace = (MITMapPlace*)[context objectWithID:[place objectID]];

        if (localPlace.bookmark) {
            NSFetchRequest *bookmarksRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMapBookmark entityName]];
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
                    DDLogWarn(@"Failed to move bookmark for '%@' to index %ld with error %@", localPlace.identifier, (unsigned long)index, *error);
                }
            }
        }
    } completion:^(NSError *error) {
        if (block) {
            block(error);
        }
    }];
}

- (BOOL)bookmarkMigrationNeeded
{
    NSURL *userDocumentsURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                     inDomain:NSUserDomainMask
                                                            appropriateForURL:nil
                                                                       create:NO
                                                                        error:nil];

    NSURL *bookmarksURL = [NSURL URLWithString:@"mapBookmarks.plist"
                                 relativeToURL:userDocumentsURL];

    return [[NSFileManager defaultManager] fileExistsAtPath:[bookmarksURL path]];
}

- (void)migrateBookmarks
{
    return;

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
