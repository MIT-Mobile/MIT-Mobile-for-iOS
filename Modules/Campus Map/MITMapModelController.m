#import <CoreData/CoreData.h>
#import "MITAdditions.h"
#import "MITMapModelController.h"

#import "MITCoreDataController.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileServerConfiguration.h"
#import "MobileRequestOperation.h"
#import "MITMapCategory.h"
#import "MITMapPlace.h"
#import "MITMapBookmark.h"
#import "MITMapSearch.h"
#import "MITAdditions.h"
#import "MITMobileResource.h"
#import "MITMobile.h"

static NSString* const MITMapDefaultsPlacesFetchDateKey = @"MITMapDefaultsPlacesFetchDate";

// TODO: Find a better place for these, maybe a class method on the NSManagedObject subclasses?
NSString* const MITMapSearchEntityName = @"MapSearch";
NSString* const MITMapCategoryEntityName = @"MapPlace";
NSString* const MITMapPlaceEntityName = @"MapPlace";
NSString* const MITMapPlaceContentEntityName = @"MapPlaceContent";
NSString* const MITMapBookmarkEntityName = @"MapBookmark";
NSString* const MITCoreDataErrorDomain = @"MITCoreDataErrorDomain";

@interface MITMapModelController ()
@property (nonatomic,strong) NSDate *placesFetchDate;

- (void)addRecentSearch:(NSString*)queryString;
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
- (void)addRecentSearch:(NSString*)queryString
{
    MITCoreDataController *dataController = [[MIT_MobileAppDelegate applicationDelegate] coreDataController];
    [dataController performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError **error) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapSearchEntityName];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"searchTerm == %@", queryString];

        MITMapSearch *mapSearch = [[context executeFetchRequest:fetchRequest error:nil] lastObject];
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
    } completion:nil];
}

#pragma mark Asynchronous
- (NSFetchRequest*)recentSearches:(MITMobileManagedResult)block
{
    return [self recentSearchesForPartialString:nil loaded:block];
}

- (NSFetchRequest*)recentSearchesForPartialString:(NSString*)string loaded:(MITMobileManagedResult)block
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


- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMobileManagedResult)block
{
    NSParameterAssert([queryString length]);
    NSParameterAssert(block);

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMobileMapPlaces
                                                    object:nil
                                                parameters:@{@"q" : queryString}
                                                completion:^(RKMappingResult *result, NSError *error) {
                                                    [self addRecentSearch:queryString];

                                                    if (!error) {
                                                        self.placesFetchDate = [NSDate date];

                                                        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapPlaceEntityName];
                                                        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SELF IN %@) AND (identifier != NIL)",[result array]];
                                                        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];

                                                        block(fetchRequest,self.placesFetchDate,nil);
                                                    } else {
                                                        block(nil,self.placesFetchDate,error);
                                                    }

                                                }];
}


- (NSFetchRequest*)categories:(MITMobileManagedResult)block
{
    // The fetch request isn't dependent on the results of the 'GET' operation so
    // we can both return it and use it in the block later
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapCategoryEntityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]];

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMobileMapCategories
                                                    object:nil
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSError *error) {
                                                    if (!error) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            block(fetchRequest,[NSDate date],nil);
                                                        }];
                                                    } else {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            block(nil,nil,error);
                                                        }];
                                                    }
                                                }];

    return fetchRequest;
}

- (NSFetchRequest*)places:(MITMobileManagedResult)block
{
    // The fetch request isn't dependent on the results of the 'GET' operation so
    // we can both return it and use it in the block later
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:MITMapPlaceEntityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(identifier != nil)"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMobileMapPlaces
                                                    object:nil
                                                parameters:nil
                                                completion:^(RKMappingResult *result, NSError *error) {
                                                    if (!error) {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            block(fetchRequest,[NSDate date],nil);
                                                        }];
                                                    } else {
                                                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                            block(nil,nil,error);
                                                        }];
                                                    }
                                                }];

    return fetchRequest;
}


- (void)placesInCategory:(MITMapCategory*)category loaded:(MITMobileManagedResult)block
{
    NSParameterAssert(category);

    /*
     // Grab the resource and perform a sanity check on the category's URL. It should
     // successfully match the path pattern provided by the /map/places resource and, if not,
     // fail the assertion; this is a serious error!
     MITMobileResource *placesResource = [[MITMobile defaultManager] resourceForName:MITMobileMapPlaces];
     NSString *pathPattern = placesResource.pathPattern;
     RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:pathPattern];
     BOOL pathMatches = [pathMatcher matchesPath:[[category.url absoluteURL] path] tokenizeQueryStrings:YES parsedArguments:&parameters];
     NSAssert(pathMatches, @"fatal error: category url '%@' does not match path pattern '%@'",category.url,pathPattern);
    */

    // TODO (bskinner - 2013.12.18): The Mobile v3 map/place_categories call is currently broken;
    //  The URL is not included and the fields are named incorrectly. Manually formatting the 'category'
    //  parameter (instead of just using the URL directly until it is fixed
    NSDictionary *parameters = @{@"category" : category.identifier};

    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMobileMapPlaces
                                                    object:nil
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSError *error) {
                                                    NSMutableArray *objectIDs = [[NSMutableArray alloc] init];
                                                    [[result array] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                                        if ([obj isKindOfClass:[NSManagedObject class]]){
                                                            NSManagedObject *managedObject = (NSManagedObject*)obj;
                                                            [objectIDs addObject:[managedObject objectID]];
                                                        } else if ([obj isKindOfClass:[NSManagedObjectID class]]) {
                                                            [objectIDs addObject:obj];
                                                        }
                                                    }];

                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                        if (!error) {
                                                            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:MITMapPlaceEntityName];
                                                            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SELF IN %@)",objectIDs];
                                                            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];

                                                            block(fetchRequest,self.placesFetchDate,nil);
                                                        } else {
                                                            block(nil,nil,error);
                                                        }
                                                    }];
                                                }];
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

- (NSUInteger)numberOfBookmarks
{
    if ([self bookmarkMigrationNeeded]) {
        [self migrateBookmarks];
    }

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
