#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>

#import "MITMobiusResourceDataSource.h"
#import "MITCoreData.h"
#import "CoreData+MITAdditions.h"
#import "MITAdditions.h"
#import "MITMobiusResource.h"

#import "MITMobiusRecentSearchList.h"
#import "MITMobiusRecentSearchQuery.h"

static NSString* const MITMobiusDefaultServer = @"https://kairos-dev.mit.edu";
static NSString* const MITMobiusResourcePathPattern = @"resource";

@interface MITMobiusResourceDataSource ()
@property (nonatomic,strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) NSOperationQueue *mappingOperationQueue;
@property (copy) NSArray *resourceObjectIdentifiers;
@property (nonatomic,copy) NSString *queryString;
@end

@implementation MITMobiusResourceDataSource
@dynamic resources;

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

- (void)resourcesWithQuery:(NSString*)queryString completion:(void(^)(MITMobiusResourceDataSource* dataSource, NSError *error))block
{
    if (![queryString length]) {
        self.queryString = nil;
        self.lastFetched = [NSDate date];
        self.resourceObjectIdentifiers = nil;
        [self.managedObjectContext reset];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if (block) {
                block(self,nil);
            }
        }];
    } else {
        NSURL *resourceReservations = [[NSURL alloc] initWithString:MITMobiusDefaultServer];
        NSMutableString *urlPath = [NSMutableString stringWithFormat:@"/%@",MITMobiusResourcePathPattern];

        if (queryString) {
            NSString *encodedString = [queryString urlEncodeUsingEncoding:NSUTF8StringEncoding useFormURLEncoded:YES];
            [urlPath appendFormat:@"?%@&q=%@",@"format=json",encodedString];
        }

        NSURL *resourcesURL = [NSURL URLWithString:urlPath relativeToURL:resourceReservations];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:resourcesURL];
        request.HTTPShouldHandleCookies = NO;
        request.HTTPMethod = @"GET";
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        RKMapping *mapping = [MITMobiusResource objectMapping];
        RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:@"collection.items" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

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
                blockSelf.queryString = queryString;
                blockSelf.lastFetched = [NSDate date];
                blockSelf.resourceObjectIdentifiers = [NSManagedObjectContext objectIDsForManagedObjects:[mappingResult array]];

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    if (block) {
                        block(blockSelf,nil);
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
                        block(blockSelf,error);
                    }
                }];
            }
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
            [recentSearchList addRecentQueriesObject:searchItem];
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
