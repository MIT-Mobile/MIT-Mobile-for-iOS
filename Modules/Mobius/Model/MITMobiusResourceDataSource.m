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
@property (nonatomic,strong) NSOperationQueue *mappingOperationQueue;
@property (copy) NSArray *resourceObjectIdentifiers;

@property (nonatomic,copy) NSString *customField;
@property (nonatomic,copy) NSString *customValue;
@end

@implementation MITMobiusResourceDataSource
@dynamic resources;
@synthesize queryString = _queryString;
@synthesize query = _query;

- (instancetype)init
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.parentContext = [MITCoreDataController defaultController].mainQueueContext;
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

- (void)setCustomField:(NSString*)field withValue:(NSString*)value
{
    NSParameterAssert(field);
    NSParameterAssert(value);
    
    self.customField = field;
    self.customValue = value;
    
    _queryString = nil;
    _query = nil;
    _lastFetched = nil;
    _resourceObjectIdentifiers = nil;
}

- (void)clearCustomField
{
    self.customField = nil;
    self.customValue = nil;
    _lastFetched = nil;
    _resourceObjectIdentifiers = nil;
}

- (NSString*)queryString
{
    __block NSString *result = nil;
    
    if (_queryString) {
        result = _queryString;
    } else if (self.query) {
        [self.query.managedObjectContext performBlockAndWait:^{
            if (self.query.text) {
                result = [NSString stringWithString:self.query.text];
            }
        }];
    } else if (self.customField) {
        result = [NSString stringWithFormat:@"%@: %@",self.customField,self.customValue];
    }

    return result;
}

- (void)setQueryString:(NSString*)string
{
    _queryString = [string copy];
    
    _query = nil;
    _lastFetched = nil;
    _resourceObjectIdentifiers = nil;
    [self clearCustomField];
}

- (void)setQuery:(MITMobiusRecentSearchQuery *)query
{
    if (query) {
        _query = (MITMobiusRecentSearchQuery*)[self.managedObjectContext objectWithID:query.objectID];
        [self.managedObjectContext refreshObject:_query mergeChanges:NO];
    } else {
        _query = nil;
    }

    _queryString = nil;
    _lastFetched = nil;
    _resourceObjectIdentifiers = nil;
    [self clearCustomField];
}

- (MITMobiusResourceSearchType)queryType
{
    if (self.customField) {
        return MITMobiusResourceSearchTypeCustomField;
    } else if (self.query.options.count > 0) {
        return MITMobiusResourceSearchTypeComplexQuery;
    } else if (self.query) {
        return MITMobiusResourceSearchTypeQuery;
    } else if (_queryString) {
        return MITMobiusResourceSearchTypeQuery;
    } else {
        return MITMobiusResourceSearchTypeAll;
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

- (void)getResources:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))completion
{
    self.lastFetched = [NSDate date];
    self.resourceObjectIdentifiers = nil;
    
    switch (self.queryType) {
        case MITMobiusResourceSearchTypeComplexQuery:
            [self resourcesWithQueryObject:self.query completion:completion];
            break;
            
        case MITMobiusResourceSearchTypeCustomField:
            [self resourcesWithField:self.customField value:self.customValue completion:completion];
            break;
            
        case MITMobiusResourceSearchTypeQuery:
            [self resourcesWithQuery:self.queryString completion:completion];
            break;
            
        default:
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (completion) {
                    completion(self,nil);
                }
            }];
            break;
    }
}

- (void)resourcesWithQueryObject:(MITMobiusRecentSearchQuery*)queryObject completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block
{
    if (!queryObject) {
        self.lastFetched = [NSDate date];
        self.resourceObjectIdentifiers = nil;

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
            __block NSDictionary *URLParameters = nil;
            [queryObject.managedObjectContext performBlockAndWait:^{
                URLParameters = [[queryObject URLParameters] copy];
            }];
            
            [URLParameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
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
        
        self.lastFetched = [NSDate date];
        self.resourceObjectIdentifiers = nil;

        __weak MITMobiusResourceDataSource *weakSelf = self;
        [self _performRequest:request completion:^(BOOL success, NSError *error) {
            MITMobiusResourceDataSource *blockSelf = weakSelf;
            if (!blockSelf) {
                return;
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
    NSParameterAssert(queryString);

    __block NSString *currentQueryString = nil;
    [self.query.managedObjectContext performBlockAndWait:^{
        currentQueryString = self.query.text;
    }];
    
    __block MITMobiusRecentSearchQuery *query = nil;
    if ([currentQueryString isEqualToString:queryString]) {
        [self.managedObjectContext performBlockAndWait:^{
            NSMutableOrderedSet *options = [self.query mutableOrderedSetValueForKey:@"options"];
            [options removeAllObjects];
            [self.managedObjectContext saveToPersistentStore:nil];
        }];

        query = self.query;
    } else {
        [self.managedObjectContext performBlockAndWait:^{
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[MITMobiusRecentSearchQuery entityName]];
            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"text BEGINSWITH[c] %@",queryString];
            
            MITMobiusRecentSearchQuery *fetchedQuery = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] firstObject];
            if (fetchedQuery) {
                query = fetchedQuery;
                
                NSMutableOrderedSet *options = [query mutableOrderedSetValueForKey:@"options"];
                [options removeAllObjects];
            } else {
                query = [NSEntityDescription insertNewObjectForEntityForName:[MITMobiusRecentSearchQuery entityName] inManagedObjectContext:self.managedObjectContext];
                query.text = queryString;
            }
            
            [self.managedObjectContext saveToPersistentStore:nil];
        }];
        
        self.query = query;
    }
    
    [self resourcesWithQueryObject:query completion:block];
}

- (void)resourcesWithField:(NSString*)field value:(NSString*)value completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block
{
    NSParameterAssert(field);
    NSParameterAssert(value);

    NSURL *resourceReservations = [MITMobiusDataSource mobiusServerURL];
    NSMutableString *urlPath = [NSMutableString stringWithFormat:@"/%@",MITMobiusResourcePathPattern];
    
    
    NSDictionary *predicate = @{@"where" : @[@{ @"field" : field,
                                                @"value" : value }]};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:predicate options:0 error:nil];
    NSString *jsonString = [[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
    [urlPath appendFormat:@"?params=%@&format=json",jsonString];
    
    NSURL *resourcesURL = [NSURL URLWithString:urlPath relativeToURL:resourceReservations];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesURL];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    
    self.lastFetched = [NSDate date];
    self.resourceObjectIdentifiers = nil;
    
    __weak MITMobiusResourceDataSource *weakSelf = self;
    [self _performRequest:request completion:^(BOOL success, NSError *error) {
        MITMobiusResourceDataSource *blockSelf = weakSelf;
        if (!blockSelf) {
            return;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(blockSelf,error);
            }
        }];
    }];
}

- (void)_performRequest:(NSURLRequest*)request completion:(void(^)(BOOL success, NSError *error))block
{
    RKMapping *mapping = [MITMobiusResource objectMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];

    NSManagedObjectContext *managedObjectContext = [[MITCoreDataController defaultController] newManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType trackChanges:NO];
    requestOperation.managedObjectContext = managedObjectContext;

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
