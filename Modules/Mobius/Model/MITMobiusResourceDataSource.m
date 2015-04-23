#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

#import "MITMobiusResourceDataSource.h"
#import "MITCoreData.h"
#import "CoreData+MITAdditions.h"
#import "MITAdditions.h"
#import "MITMobiusDataSource.h"
#import "MITMobiusResource.h"
#import "MITMobiusRoomSet.h"
#import "MITMobiusResourceType.h"

#import "MITMobiusRecentSearchList.h"
#import "MITMobiusRecentSearchQuery.h"

static NSString* const MITMobiusResourcePathPattern = @"resource";

@interface MITMobiusResourceDataSource ()
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSOperationQueue *mappingOperationQueue;
@property (copy) NSArray *resourceObjectIdentifiers;
@property (nonatomic,copy) NSString *queryString;
@property (nonatomic,strong) MITMobiusRecentSearchQuery *query;
@end

@implementation MITMobiusResourceDataSource
@dynamic resources;
@dynamic queryString;
@synthesize query = _query;

- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:YES];
    return [self initWithManagedObjectContext:managedObjectContext];
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSParameterAssert(managedObjectContext);

    self = [super init];
    if (self) {
        _managedObjectContext = managedObjectContext;
        _mappingOperationQueue = [[NSOperationQueue alloc] init];
    }

    return self;
}

- (NSArray*)resources
{
    __block NSArray *resources = nil;
    NSManagedObjectContext *mainQueueContext = [[MITCoreDataController defaultController] mainQueueContext];

    [mainQueueContext performBlockAndWait:^{
        if ([self.resourceObjectIdentifiers count]) {
            NSMutableArray *mutableResources = [[NSMutableArray alloc] init];
            [self.resourceObjectIdentifiers enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
                NSManagedObject *object = [mainQueueContext objectWithID:objectID];
                [mutableResources addObject:object];
            }];

            resources = mutableResources;
        }
    }];

    return resources;
}

- (NSString*)queryString
{
    __block NSString *result = nil;
    [self.query.managedObjectContext performBlockAndWait:^{
        if (self.query.text) {
            result = [NSString stringWithString:self.query.text];
        }
    }];

    return result;
}

- (BOOL)hasQuery
{
    return (_query != nil);
}

- (MITMobiusRecentSearchQuery*)query
{
    if (!_query) {
        [self.managedObjectContext performBlockAndWait:^{
            _query = (MITMobiusRecentSearchQuery*)[self.managedObjectContext insertNewObjectForEntityForName:[MITMobiusRecentSearchQuery entityName]];
        }];

    }

    return _query;
}

- (void)setQuery:(MITMobiusRecentSearchQuery *)query
{
    if (query) {
        _query = (MITMobiusRecentSearchQuery*)[self.managedObjectContext existingObjectWithID:query.objectID error:nil];
    } else {
        _query = nil;
    }
}

- (NSDictionary*)resourcesGroupedByKey:(NSString*)key withManagedObjectContext:(NSManagedObjectContext*)context
{
    NSParameterAssert(context);

    if (self.resourceObjectIdentifiers.count > 0) {
        NSMutableDictionary *groupedResources = [[NSMutableDictionary alloc] init];
        [context performBlockAndWait:^{
            [self.resourceObjectIdentifiers enumerateObjectsUsingBlock:^(NSManagedObjectID *objectID, NSUInteger idx, BOOL *stop) {
                NSManagedObject *object = [context existingObjectWithID:objectID error:nil];
                if (object) {
                    id<NSCopying> keyValue = [object valueForKey:key];

                    NSMutableArray *values = groupedResources[keyValue];
                    if (!values) {
                        values = [[NSMutableArray alloc] init];
                        groupedResources[keyValue] = values;
                    }

                    [values addObject:object];
                }
            }];
        }];

        return groupedResources;
    } else {
        return nil;
    }
}

- (void)resourcesWithQueryObject:(MITMobiusRecentSearchQuery*)queryObject completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block
{
    if (!queryObject) {
        self.query = nil;
        self.lastFetched = [NSDate date];
        self.resourceObjectIdentifiers = nil;
        [self.managedObjectContext reset];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(self,nil);
            }
        }];
    } else {
        NSURL *resourceReservations = [MITMobiusDataSource mobiusServerURL];
        NSMutableString *urlPath = [NSMutableString stringWithFormat:@"/%@",MITMobiusResourcePathPattern];

        if (queryObject) {
            NSMutableArray *parameters = [[NSMutableArray alloc] init];
            [[queryObject URLParameters] enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
                NSString *parameterString = [NSString stringWithFormat:@"%@=%@",key,[value urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES]];
                [parameters addObject:parameterString];
            }];

            [parameters addObject:@"format=json"];

            NSString *parameterString = [parameters componentsJoinedByString:@"&"];
            [urlPath appendFormat:@"?%@",parameterString];
        }

        NSURL *resourcesURL = [NSURL URLWithString:urlPath relativeToURL:resourceReservations];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesURL];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        __weak MITMobiusResourceDataSource *weakSelf = self;
        [self _performRequest:request completion:^(BOOL success, NSError *error) {
            MITMobiusResourceDataSource *blockSelf = weakSelf;
            if (!blockSelf) {
                return;
            }

            if (success) {
                blockSelf.lastFetched = [NSDate date];
                blockSelf.query = queryObject;
                [blockSelf.query.managedObjectContext performBlockAndWait:^{
                    [blockSelf.query.managedObjectContext saveToPersistentStore:nil];
                }];
            }

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(blockSelf,error);
                }
            }];
        }];
    }
}

- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block
{
    if (![queryString length]) {
        self.query = nil;
        self.lastFetched = [NSDate date];
        self.resourceObjectIdentifiers = nil;
        [self.managedObjectContext reset];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(self,nil);
            }
        }];
    } else {
        NSURL *resourceReservations = [MITMobiusDataSource mobiusServerURL];
        NSMutableString *urlPath = [NSMutableString stringWithFormat:@"/%@",MITMobiusResourcePathPattern];
#warning temporary fix
        if ([queryString rangeOfString:@"params"].location != NSNotFound) {
            NSString *encodedString = [queryString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [urlPath appendFormat:@"/?%@&%@",@"format=json",encodedString];
        } else if (queryString) {

            NSString *encodedString = [queryString urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
            [urlPath appendFormat:@"?%@&q=%@",@"format=json",encodedString];
        }

        NSURL *resourcesURL = [NSURL URLWithString:urlPath relativeToURL:resourceReservations];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesURL];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPMethod = @"GET";
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        __weak MITMobiusResourceDataSource *weakSelf = self;
        [self _performRequest:request completion:^(BOOL success, NSError *error) {
            MITMobiusResourceDataSource *blockSelf = weakSelf;
            if (!blockSelf) {
                return;
            }

            if (success) {
                blockSelf.lastFetched = [NSDate date];
                [blockSelf.managedObjectContext performBlockAndWait:^{
                    blockSelf.query.text = queryString;
                    [blockSelf.query.managedObjectContext saveToPersistentStore:nil];
                }];
            }

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(blockSelf,error);
                }
            }];
        }];
    }
}

- (void)_performRequest:(NSURLRequest*)request completion:(void(^)(BOOL success, NSError *error))block
{
    RKMapping *mapping = [MITMobiusResource objectMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    requestOperation.managedObjectContext = self.managedObjectContext;

    RKFetchRequestManagedObjectCache *cache = [[RKFetchRequestManagedObjectCache alloc] init];
    requestOperation.managedObjectCache = cache;

    __weak MITMobiusResourceDataSource *weakSelf = self;
    [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        MITMobiusResourceDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        }

        NSManagedObjectContext *context = blockSelf.managedObjectContext;
        [context performBlock:^{
            blockSelf.resourceObjectIdentifiers = [NSManagedObjectContext objectIDsForManagedObjects:[mappingResult array]];

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(YES,nil);
                }
            }];
        }];
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        MITMobiusResourceDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        } else {
            DDLogError(@"failed to request Mobius resources: %@",error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(NO,error);
                }
            }];
        }
    }];

    [self.mappingOperationQueue addOperation:requestOperation];
}

- (void)getObjectsForRoute:(MITMobiusQuickSearchType)type completion:(void(^)(NSArray* objects, NSError *error))block
{
    if (type != MITMobiusQuickSearchRoomSet &&
        type != MITMobiusQuickSearchResourceType) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(nil,nil);
            }
        }];
    } else {
        NSURL *resourceReservations = [MITMobiusDataSource mobiusServerURL];
        NSString *urlPath = nil;
        if (type == MITMobiusQuickSearchRoomSet) {
            NSString *encodedString = [@"resourceroomset" urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
            urlPath = [NSString stringWithFormat:@"/%@?%@",encodedString, @"format=json"];
        } else if (type == MITMobiusQuickSearchResourceType) {
            NSString *encodedString = [@"resourcetype" urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
            urlPath = [NSString stringWithFormat:@"/%@?%@",encodedString, @"format=json"];
            
        }
        
        NSURL *resourcesURL = [NSURL URLWithString:urlPath relativeToURL:resourceReservations];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesURL];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPMethod = @"GET";
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        
        RKMapping *mapping = nil;
        
        if (type == MITMobiusQuickSearchResourceType) {
            mapping = [MITMobiusResourceType objectMapping];
        } else if (type == MITMobiusQuickSearchRoomSet) {
            mapping = [MITMobiusRoomSet objectMapping];
        }
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
        
        RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
        requestOperation.managedObjectContext = self.managedObjectContext;
        
        RKFetchRequestManagedObjectCache *cache = [[RKFetchRequestManagedObjectCache alloc] init];
        requestOperation.managedObjectCache = cache;
        
        __weak MITMobiusResourceDataSource *weakSelf = self;
        [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
            MITMobiusResourceDataSource *blockSelf = weakSelf;
            if (!blockSelf) {
                return;
            }
            
            NSManagedObjectContext *context = blockSelf.managedObjectContext;
            [context performBlock:^{
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block([mappingResult array],nil);
                    }
                }];
            }];
        } failure:^(RKObjectRequestOperation *operation, NSError *error) {
            
            DDLogError(@"failed to request Mobius resources: %@",error);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (block) {
                    block(nil,error);
                }
            }];
        }];
        
        [self.mappingOperationQueue addOperation:requestOperation];
    }
}

#pragma mark - Recent Search List

- (MITMobiusRecentSearchList *)recentSearchListWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMobiusRecentSearchList entityName]];
    NSError *error = nil;
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        return nil;
    } else if ([fetchedObjects count] == 0) {
        return [[MITMobiusRecentSearchList alloc] initWithEntity:[MITMobiusRecentSearchList entityDescription] insertIntoManagedObjectContext:context];
    } else {
        return [fetchedObjects firstObject];
    }
}

#pragma mark - Recent Search Items
- (NSInteger)numberOfRecentSearchItemsWithFilterString:(NSString *)filterString
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMobiusRecentSearchQuery entityName]];
    fetchRequest.resultType = NSCountResultType;
    
    if ([filterString length]) {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"text BEGINSWITH[cd] %@", filterString];
    }
    
    NSInteger numberOfRecentSearchItems = [[MITCoreDataController defaultController].mainQueueContext countForFetchRequest:fetchRequest error:nil];

    // Don't propogate the error up if things go south.
    // Just catch the bad count and return a 0.
    if (numberOfRecentSearchItems == NSNotFound) {
        return 0;
    } else {
        return numberOfRecentSearchItems;
    }
}

- (NSArray *)recentSearchItemswithFilterString:(NSString *)filterString
{
    NSManagedObjectContext *managedObjectContext = [MITCoreDataController defaultController].mainQueueContext;
    MITMobiusRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:managedObjectContext];
    NSArray *recentSearchItems = [[recentSearchList.recentQueries reversedOrderedSet] array];
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    
    if ([filterString length] > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text BEGINSWITH[cd] %@", filterString];
        return [[recentSearchItems filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    }
    
    return [[recentSearchList.recentQueries array] sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (void)addRecentSearchItem:(NSString *)searchTerm error:(NSError**)error
{
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError *__autoreleasing *updateError) {
        
        MITMobiusRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        NSArray *recentSearchItems = [recentSearchList.recentQueries array];
        
        __block MITMobiusRecentSearchQuery *searchItem = nil;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text =[c] %@", searchTerm];
        [recentSearchItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            BOOL objectMatches = [predicate evaluateWithObject:obj];
            if (objectMatches) {
                (*stop) = YES;
                searchItem = (MITMobiusRecentSearchQuery*)obj;
            }
        }];
        
        if (!searchItem) {
            searchItem = [[MITMobiusRecentSearchQuery alloc] initWithEntity:[MITMobiusRecentSearchQuery entityDescription] insertIntoManagedObjectContext:context];
            searchItem.text = searchTerm;
            searchItem.search = recentSearchList;
        }
        
        searchItem.date = [NSDate date];
        return YES;
    } error:error];
}

- (void)clearRecentSearches
{
    [[MITCoreDataController defaultController] performBackgroundUpdateAndWait:^(NSManagedObjectContext *context, NSError **updateError) {
        MITMobiusRecentSearchList *recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        [context deleteObject:recentSearchList];
        recentSearchList = [self recentSearchListWithManagedObjectContext:context];
        
        if (recentSearchList) {
            return YES;
        } else {
            return NO;
        }
    } error:nil];
}

@end
