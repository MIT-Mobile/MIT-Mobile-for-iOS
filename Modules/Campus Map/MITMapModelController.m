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

static NSString* const MITMapResourceCategoryTitles = @"categorytitles";
static NSString* const MITMapResourceCategory = @"category";
static NSString* const MITMapDefaultsPlacesFetchDateKey = @"MITMapDefaultsPlacesFetchDate";

NSString* const MITMapSearchEntityName = @"MapSearch";
NSString* const MITMapPlaceEntityName = @"MapPlace";
NSString* const MITMapBookmarkEntityName = @"MapBookmark";
NSString* const MITCoreDataErrorDomain = @"MITCoreDataErrorDomain";

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

+ (NSManagedObjectModel*)managedObjectModel
{
    static NSManagedObjectModel *managedObjectModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *dataModelURL = [[NSBundle mainBundle] URLForResource:@"CampusMap" withExtension:@"momd"];
        managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:dataModelURL];
    });
    
    return managedObjectModel;
}

+ (MITMobileResource*)placesResource
{
    static MITMobileResource *placesResource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSEntityDescription *entity = [[self managedObjectModel] entitiesByName][@"MapPlace"];
        NSAssert1(entity,@"Entity %@ does not exist in the managed object model", @"MapPlace");
        
        MITMobileResource *resource = [[MITMobileResource alloc] initWithName:MITMobileMapPlaces pathPattern:MITMobileMapPlaces];
        RKEntityMapping *placeMapping = [[RKEntityMapping alloc] initWithEntity:entity];
        placeMapping.identificationAttributes = @[@"identifier"]; // RKEntityMapping converts this to an NSAttributeDescription internally
        placeMapping.assignsNilForMissingRelationships = YES;
        
        NSDictionary *placeAttributeMappings = @{@"id" : @"identifier",
                                                 @"name" : @"name",
                                                 @"bldgimg" : @"imageURL",
                                                 @"bldgnum" : @"buildingNumber",
                                                 @"viewangle" : @"imageCaption",
                                                 @"architect" : @"architect",
                                                 @"mailing" : @"mailingAddress",
                                                 @"street" : @"streetAddress",
                                                 @"city" : @"city",
                                                 @"lat_wgs84" : @"latitude",
                                                 @"long_wgs84" : @"longitude",
                                                 @"url" : @"url"};
        
        [placeMapping addAttributeMappingsFromDictionary:placeAttributeMappings];
        
        RKEntityMapping *placeContentsMapping = [[RKEntityMapping alloc] initWithEntity:entity];
        [placeContentsMapping addAttributeMappingsFromDictionary:placeAttributeMappings];
        placeContentsMapping.assignsNilForMissingRelationships = YES;
        
        RKRelationshipMapping *contentsRelationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"contents"
                                                                                                  toKeyPath:@"contents"
                                                                                                withMapping:placeContentsMapping];
        contentsRelationship.assignmentPolicy = RKAssignmentPolicyReplace;
        [placeMapping addPropertyMapping:contentsRelationship];
        
        [resource addMapping:placeMapping atKeyPath:nil forRequestMethod:RKRequestMethodGET];
        
        
        // Use of typecasts below is to make the auto-detection of the return type
        // work nicely. Without it, Clang complains that void* is not a NSFetchRequest*,
        // which is technically correct (the worst type of correct).
        __weak MITMobileResource *weakResource = resource;
        resource.fetchGenerator = ^(NSURL*url) {
            MITMobileResource *blockResource = weakResource;
            
            if (!blockResource) {
                return (NSFetchRequest*)nil;
            } else if (!url) {
                return (NSFetchRequest*)nil;
            }
            
            RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[url relativePath]];
            
            NSDictionary *parameters = nil;
            BOOL matches = [pathMatcher matchesPattern:blockResource.pathPattern tokenizeQueryStrings:YES parsedArguments:&parameters];
            
            if (matches) {
                if (parameters[@"q"]) {
                    // Can't calculate a fetch request for search queries. This completely
                    // depends on the server's response, not the URL of the request.
                    return (NSFetchRequest*)nil;
                } else if (parameters[@"category"]) {
                    // Can't build a fetch request for this either (at the moment).
                    // As of 2013.12.04, the categories returned by the place_categories
                    // resource and the categories at a MapPlace's 'categories' subkey do
                    // not match up.
                    return (NSFetchRequest*)nil;
                } else {
                    // Ok, we can *probably* build some sort of a fetch request!
                    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapPlaces"];
                    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"identifier != nil"];
                    return fetchRequest;
                }
            }
            
            return (NSFetchRequest*)nil;
        };

        placesResource = resource;
    });
    
    return placesResource;
}

+ (MITMobileResource*)categoriesResource
{
    static MITMobileResource *categoriesResource = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSEntityDescription *entity = [[self managedObjectModel] entitiesByName][@"MapCategory"];
        NSAssert(entity,@"Entity %@ does not exist in the managed object model", @"MapCategory");
        
        MITMobileResource *resource = [[MITMobileResource alloc] initWithName:MITMobileMapCategories pathPattern:MITMobileMapCategories];
        RKEntityMapping *categoryMapping = [[RKEntityMapping alloc] initWithEntity:entity];
        [categoryMapping addAttributeMappingsFromDictionary:@{@"categoryId": @"identifier",
                                                              @"url" : @"url",
                                                              @"categoryName" : @"name",
                                                              @"@metadata.mapping.collectionIndex" : @"order"}];
        
        RKRelationshipMapping *subcategories = [RKRelationshipMapping relationshipMappingFromKeyPath:@"subcategories"
                                                                                           toKeyPath:@"children"
                                                                                         withMapping:categoryMapping];
        [categoryMapping addPropertyMapping:subcategories];
        
        [resource addMapping:categoryMapping atKeyPath:nil forRequestMethod:RKRequestMethodGET];
        
        __weak MITMobileResource *weakResource = resource;
        resource.fetchGenerator = ^(NSURL*url) {
            MITMobileResource *blockResource = weakResource;
            
            if (!blockResource) {
                return (NSFetchRequest*)nil;
            } else if (!url) {
                return (NSFetchRequest*)nil;
            }
            
            RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPath:[url relativePath]];
            BOOL matches = [pathMatcher matchesPattern:blockResource.pathPattern tokenizeQueryStrings:NO parsedArguments:nil];
            
            if (matches) {
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapCategory"];
                fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
                fetchRequest.sortDescriptors = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
                return fetchRequest;
            } else {
                return (NSFetchRequest*)nil;
            }
        };
        
        categoriesResource = resource;
    });
    
    return categoriesResource;
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
    }
                                        completion:nil];
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
            [searches enumerateObjectsUsingBlock:^(MITMapSearch *search, NSUInteger idx, BOOL *stop) {
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
    } completion:^(NSError *error) {
        if (block) {
            if (!error) {
                block(fetchRequest,self.placesFetchDate,nil);
            } else {
                block(nil,self.placesFetchDate,error);
            }
        }
    }];
}

- (void)searchMapWithQuery:(NSString*)queryString loaded:(MITMapFetchedResult)block
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
                                                        
                                                        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapPlace"];
                                                        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SELF IN %@) AND (identifier != NIL) AND (building == nil)",[result array]];
                                                        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
                                                        
                                                        block(fetchRequest,self.placesFetchDate,nil);
                                                    } else {
                                                        block(nil,self.placesFetchDate,error);
                                                    }
                                                    
                                                }];
}


- (void)categories:(MITMapFetchedResult)block
{
    NSParameterAssert(block);
    
    MITMobile *defaultManager = [MITMobile defaultManager];
    [defaultManager getObjectsForResourceNamed:MITMobileMapCategories
                                        object:nil
                                    parameters:nil
                                    completion:^(RKMappingResult *result, NSError *error) {
                                        if (!error) {
                                            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapCategory"];
                                            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parent == nil"];
                                            
                                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                block(fetchRequest,[NSDate date],nil);
                                            }];
                                        } else {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                block(nil,nil,error);
                                            }];
                                        }
                                    }];
}

- (void)places:(MITMapFetchedResult)block
{
    NSParameterAssert(block);
    
    MITMobile *defaultManager = [MITMobile defaultManager];
    [defaultManager getObjectsForResourceNamed:MITMobileMapCategories
                                        object:nil
                                    parameters:nil
                                    completion:^(RKMappingResult *result, NSError *error) {
                                        if (!error) {
                                            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"MapPlaces"];
                                            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(identifier != nil) AND (building == nil)"];
                                            
                                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                block(fetchRequest,[NSDate date],nil);
                                            }];
                                        } else {
                                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                block(nil,nil,error);
                                            }];
                                        }
                                    }];
}


- (void)placesInCategory:(MITMapCategory*)category loaded:(MITMapFetchedResult)block
{
    NSParameterAssert(category);
    NSParameterAssert(block);
    
    // This is fairly messy at the moment since there is no foreign key between the map places
    // and the categories. What we need to do is fire off a request to the category's content URL, parse
    // out the parameters and then GET the places
    NSString *pathPattern = [MITMapModelController placesResource].pathPattern;
    RKPathMatcher *pathMatcher = [RKPathMatcher pathMatcherWithPattern:pathPattern];
    NSDictionary *parameters = nil;
    BOOL pathMatches = [pathMatcher matchesPath:[[category.url absoluteURL] path] tokenizeQueryStrings:YES parsedArguments:&parameters];
    
    NSAssert(pathMatches, @"fatal error: category url '%@' does not match path pattern '%@'",category.url,pathPattern);
    [[MITMobile defaultManager] getObjectsForResourceNamed:MITMobileMapPlaces
                                                    object:nil
                                                parameters:parameters
                                                completion:^(RKMappingResult *result, NSError *error) {
                                                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                                        if (!error) {
                                                            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"MapPlace"];
                                                            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SELF IN %@)",[result array]];
                                                            fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]];
                                                            
                                                            block(fetchRequest,self.placesFetchDate,nil);
                                                        } else {
                                                            block(nil,nil,error);
                                                        }
                                                    }];
                                                }];
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
